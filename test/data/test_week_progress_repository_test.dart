import 'package:fitnesbuster/data/repositories/test_week_progress_repository.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/test_week_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemoteStore implements TestWeekProgressRemoteStore {
  TestWeekProgress? progress;
  bool failLoad = false;
  bool failSave = false;

  @override
  Future<TestWeekProgress?> load(String userId) async {
    if (failLoad) throw Exception('offline');
    return progress;
  }

  @override
  Future<void> save(String userId, TestWeekProgress value) async {
    if (failSave) throw Exception('offline');
    progress = value;
  }
}

const _exercise = TestExerciseResult(
  exerciseName: 'Отжимания',
  primaryMuscle: MuscleGroup.chest,
  comfortableWeightKg: 0,
  comfortableSets: 4,
  comfortableReps: 12,
);

TestWeekProgress _progress({
  int completedDays = 0,
  int draftExercises = 0,
  DateTime? updatedAt,
}) => TestWeekProgress(
  startedAt: DateTime.utc(2026, 7, 13),
  workoutLocation: 'home',
  completedDays: List.generate(
    completedDays,
    (index) => TestWeekCompletedDay(
      dayIndex: index,
      completedAt: DateTime.utc(2026, 7, 13 + index * 2),
      rpe: 6,
      exercises: const [_exercise],
    ),
  ),
  draftDayIndex: draftExercises == 0 ? null : completedDays,
  draftExercises: List.filled(draftExercises, _exercise),
  updatedAt: updatedAt,
);

void main() {
  const userId = 'user-1';
  late _FakeRemoteStore remote;
  late TestWeekProgressRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    remote = _FakeRemoteStore();
    repository = TestWeekProgressRepository(
      remote: remote,
      now: () => DateTime.utc(2026, 7, 13, 12),
    );
  });

  test('save persists to both local cache and server', () async {
    await repository.save(userId, _progress(draftExercises: 1));

    expect(remote.progress, isNotNull);
    expect(remote.progress!.draftExercises, hasLength(1));
    expect(remote.progress!.updatedAt, DateTime.utc(2026, 7, 13, 12));

    remote.failLoad = true;
    final cached = await repository.load(userId);
    expect(cached!.draftExercises, hasLength(1));
  });

  test('a new device restores progress from the server', () async {
    remote.progress = _progress(completedDays: 2);

    final restored = await repository.load(userId);

    expect(restored!.completedDays, hasLength(2));
    remote.failLoad = true;
    expect((await repository.load(userId))!.completedDays, hasLength(2));
  });

  test(
    'offline progress wins and reconciles the server after reconnect',
    () async {
      remote.progress = _progress(completedDays: 1);
      remote.failSave = true;
      await repository.save(userId, _progress(completedDays: 2));

      remote.failSave = false;
      final restored = await repository.load(userId);

      expect(restored!.completedDays, hasLength(2));
      expect(remote.progress!.completedDays, hasLength(2));
    },
  );

  test('clear removes local cache but keeps the server archive', () async {
    await repository.save(userId, _progress(completedDays: 1));
    await repository.clear(userId);

    expect(remote.progress, isNotNull);
    remote.failLoad = true;
    expect(await repository.load(userId), isNull);
  });

  test('conflict selection never regresses completed days', () {
    final local = _progress(completedDays: 3);
    final server = _progress(completedDays: 1, draftExercises: 4);
    expect(selectMostAdvancedTestWeekProgress(local, server), same(local));
  });
}
