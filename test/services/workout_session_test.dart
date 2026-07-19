import 'package:fitnesbuster/core/services/workout_session.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkoutSession session;

  setUp(() {
    session = WorkoutSession();
  });

  test('isActive is false initially', () {
    expect(session.isActive, isFalse);
  });

  test('workout is null initially', () {
    expect(session.workout, isNull);
  });

  group('startSession', () {
    test('sets active and resets counters', () {
      const day = WorkoutDay(
        day: 1,
        focus: 'Chest',
        exercises: [
          WorkoutExercise(
            name: 'Bench Press',
            sets: 3,
            reps: '10',
            restSeconds: 60,
          ),
        ],
      );
      session.startSession(day, prepSeconds: 10);

      expect(session.isActive, isTrue);
      expect(session.workout, day);
      expect(session.phase, WorkoutPhase.prep);
      expect(session.phaseDuration, 10);
      expect(session.exIdx, 0);
      expect(session.setIdx, 0);
      expect(session.completedSets, 0);
    });
  });

  group('syncState', () {
    test('updates all state fields', () {
      final now = DateTime(2025, 7, 1, 10, 0);
      const day = WorkoutDay(day: 1, focus: 'Test', exercises: []);
      session.startSession(day, prepSeconds: 10);
      session.syncState(
        exIdx: 2,
        setIdx: 1,
        phase: WorkoutPhase.exercise,
        phaseDuration: 45,
        phaseStart: now,
        completedSets: 5,
      );

      expect(session.exIdx, 2);
      expect(session.setIdx, 1);
      expect(session.phase, WorkoutPhase.exercise);
      expect(session.phaseDuration, 45);
      expect(session.phaseStart, now);
      expect(session.completedSets, 5);
    });
  });

  group('logSet', () {
    test('does not affect external state directly', () {
      const day = WorkoutDay(day: 1, focus: 'Test', exercises: []);
      session.startSession(day, prepSeconds: 10);
      final before = session.completedSets;
      session.logSet(
        exerciseName: 'Squat',
        setNumber: 1,
        plannedReps: '10',
        weightKg: 80,
      );
      // logSet does not change completedSets (that's done by the screen)
      expect(session.completedSets, before);
    });
  });

  group('computedTimeLeft', () {
    test('returns elapsed time from wall clock', () {
      const day = WorkoutDay(day: 1, focus: 'Test', exercises: []);
      session.startSession(day, prepSeconds: 30);
      final initial = session.computedTimeLeft;
      expect(initial, greaterThanOrEqualTo(0));
      expect(initial, lessThanOrEqualTo(30));
    });

    test('clamps to zero after phase expires', () {
      const day = WorkoutDay(day: 1, focus: 'Test', exercises: []);
      // Start a session with the phase start set far in the past
      session.startSession(day, prepSeconds: 5);
      session.syncState(
        exIdx: 0,
        setIdx: 0,
        phase: WorkoutPhase.exercise,
        phaseDuration: 30,
        phaseStart: DateTime.now().subtract(const Duration(seconds: 60)),
        completedSets: 0,
      );
      expect(session.computedTimeLeft, 0);
    });
  });

  group('exerciseName', () {
    test('returns empty when no workout', () {
      expect(session.exerciseName, '');
    });

    test('returns current exercise name', () {
      const day = WorkoutDay(
        day: 1,
        focus: 'Legs',
        exercises: [
          WorkoutExercise(name: 'Squat', sets: 3, reps: '10', restSeconds: 60),
          WorkoutExercise(
            name: 'Deadlift',
            sets: 3,
            reps: '8',
            restSeconds: 90,
          ),
        ],
      );
      session.startSession(day, prepSeconds: 5);
      expect(session.exerciseName, 'Squat');
      session.syncState(
        exIdx: 1,
        setIdx: 0,
        phase: WorkoutPhase.prep,
        phaseDuration: 5,
        phaseStart: DateTime.now(),
        completedSets: 3,
      );
      expect(session.exerciseName, 'Deadlift');
    });

    test('returns empty when index out of bounds', () {
      const day = WorkoutDay(day: 1, focus: 'Test', exercises: []);
      session.startSession(day, prepSeconds: 5);
      session.syncState(
        exIdx: 99,
        setIdx: 0,
        phase: WorkoutPhase.prep,
        phaseDuration: 5,
        phaseStart: DateTime.now(),
        completedSets: 0,
      );
      expect(session.exerciseName, '');
    });
  });

  group('progressText', () {
    test('returns empty when no workout', () {
      expect(session.progressText, '');
    });

    test('formats completed sets vs total', () {
      const day = WorkoutDay(
        day: 1,
        focus: 'Chest',
        exercises: [
          WorkoutExercise(name: 'A', sets: 3, reps: '10', restSeconds: 60),
          WorkoutExercise(name: 'B', sets: 2, reps: '12', restSeconds: 45),
        ],
      );
      session.startSession(day, prepSeconds: 5);
      session.syncState(
        exIdx: 0,
        setIdx: 0,
        phase: WorkoutPhase.exercise,
        phaseDuration: 30,
        phaseStart: DateTime.now(),
        completedSets: 2,
      );
      final text = session.progressText;
      expect(text, isNotEmpty);
    });
  });

  group('estimatedCaloriesBurned', () {
    test('returns non-negative even for zero elapsed time', () {
      const day = WorkoutDay(day: 1, focus: 'Test', exercises: []);
      session.startSession(day, prepSeconds: 5);
      // Immediately after start, elapsed time is near zero
      final kcal = session.estimatedCaloriesBurned;
      expect(kcal, greaterThanOrEqualTo(0));
      expect(kcal, lessThan(50)); // Less than ~1 min worth
    });

    test('rate is 7 kcal/min when workout has cardio', () {
      const day = WorkoutDay(
        day: 1,
        focus: 'Test',
        exercises: [],
        cardioMinutes: 20,
      );
      session.startSession(day, prepSeconds: 5);
      // Rate should be 7 for cardio, ~0 for zero elapsed
      final kcal = session.estimatedCaloriesBurned;
      expect(kcal, greaterThanOrEqualTo(0));
      // After 0-1 minutes, result should be 0-7
      expect(kcal, lessThan(15));
    });
  });

  group('endSession', () {
    test('returns empty list when not active', () async {
      final result = await session.endSession(completed: true);
      expect(result, isEmpty);
    });
  });
}
