import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/test_week_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const result = TestExerciseResult(
    exerciseName: 'Отжимания',
    primaryMuscle: MuscleGroup.chest,
    comfortableWeightKg: 0,
    comfortableSets: 4,
    comfortableReps: 12,
  );

  test('assessment workouts are distributed over all seven days', () {
    final progress = TestWeekProgress(
      startedAt: DateTime(2026, 7, 13, 18),
      workoutLocation: 'home',
    );

    expect(List.generate(4, progress.availableAtForDay), [
      DateTime(2026, 7, 13),
      DateTime(2026, 7, 15),
      DateTime(2026, 7, 17),
      DateTime(2026, 7, 19),
    ]);
    expect(progress.isDayAvailable(1, DateTime(2026, 7, 14, 23)), isFalse);
    expect(progress.isDayAvailable(1, DateTime(2026, 7, 15)), isTrue);
  });

  test('completed days and current draft survive serialization', () {
    final progress = TestWeekProgress(
      startedAt: DateTime(2026, 7, 13),
      workoutLocation: 'outdoor',
      completedDays: [
        TestWeekCompletedDay(
          dayIndex: 0,
          completedAt: DateTime(2026, 7, 13, 19),
          rpe: 7,
          exercises: const [result],
        ),
      ],
      draftDayIndex: 1,
      draftExercises: const [result],
      updatedAt: DateTime.utc(2026, 7, 15, 12),
    );

    final restored = TestWeekProgress.fromJson(progress.toJson());
    expect(restored.workoutLocation, 'outdoor');
    expect(restored.nextDayIndex, 1);
    expect(restored.allCompletedExercises, const [result]);
    expect(restored.draftDayIndex, 1);
    expect(restored.draftExercises, const [result]);
    expect(restored.averageRpe, 7);
    expect(restored.updatedAt, DateTime.utc(2026, 7, 15, 12));
  });
}
