import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/core/services/workout_session.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WorkoutSession session;

  WorkoutDay makeDay({
    int day = 1,
    String focus = 'Test',
    List<WorkoutExercise> exercises = const [],
    int cardioMinutes = 0,
  }) {
    return WorkoutDay(
      day: day,
      focus: focus,
      exercises: exercises,
      cardioMinutes: cardioMinutes,
    );
  }

  WorkoutExercise makeEx({
    String name = 'Squat',
    int sets = 3,
    String reps = '10',
    int restSeconds = 60,
  }) {
    return WorkoutExercise(
      name: name,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
    );
  }

  setUp(() {
    session = WorkoutSession();
  });

  test('initial state — not active', () {
    expect(session.isActive, false);
    expect(session.workout, isNull);
    expect(session.phase, WorkoutPhase.prep);
    expect(session.completedSets, 0);
    expect(session.exIdx, 0);
    expect(session.setIdx, 0);
  });

  group('startSession', () {
    test('sets active state and initial properties', () {
      final workout = makeDay(exercises: [makeEx()]);
      session.startSession(workout, prepSeconds: 15);

      expect(session.isActive, true);
      expect(session.workout, workout);
      expect(session.phase, WorkoutPhase.prep);
      expect(session.phaseDuration, 15);
      expect(session.exIdx, 0);
      expect(session.setIdx, 0);
      expect(session.completedSets, 0);
    });

    test('clears previous set log', () {
      final workout = makeDay(exercises: [makeEx()]);
      session.startSession(workout, prepSeconds: 10);
      session.logSet(exerciseName: 'Squat', setNumber: 1, plannedReps: '10');
      session.startSession(workout, prepSeconds: 10);

      expect(session.completedSets, 0);
    });
  });

  group('syncState', () {
    test('updates all state properties', () {
      final workout = makeDay(
        exercises: [
          makeEx(),
          makeEx(name: 'Deadlift', sets: 4, reps: '8'),
        ],
      );
      session.startSession(workout, prepSeconds: 15);

      final syncTime = DateTime.now().subtract(const Duration(seconds: 5));
      session.syncState(
        exIdx: 1,
        setIdx: 2,
        phase: WorkoutPhase.exercise,
        phaseDuration: 45,
        phaseStart: syncTime,
        completedSets: 3,
      );

      expect(session.exIdx, 1);
      expect(session.setIdx, 2);
      expect(session.phase, WorkoutPhase.exercise);
      expect(session.phaseDuration, 45);
      expect(session.completedSets, 3);
    });
  });

  group('getters', () {
    test('exerciseName returns correct name', () {
      final workout = makeDay(
        exercises: [
          makeEx(name: 'Bench Press'),
          makeEx(name: 'Shoulder Press', sets: 4, reps: '8'),
        ],
      );
      session.startSession(workout, prepSeconds: 10);
      session.syncState(
        exIdx: 1,
        setIdx: 0,
        phase: WorkoutPhase.exercise,
        phaseDuration: 45,
        phaseStart: DateTime.now(),
        completedSets: 0,
      );

      expect(session.exerciseName, 'Shoulder Press');
    });

    test('exerciseName is empty when no workout', () {
      expect(session.exerciseName, '');
    });

    test('computedTimeLeft decreases over time', () {
      final workout = makeDay(exercises: [makeEx()]);
      session.startSession(workout, prepSeconds: 30);

      final timeLeft = session.computedTimeLeft;
      expect(timeLeft, lessThanOrEqualTo(30));
      expect(timeLeft, greaterThanOrEqualTo(0));
    });

    test('elapsedMinutes is non-negative', () {
      expect(session.elapsedMinutes, greaterThanOrEqualTo(0));
    });

    test('estimatedCaloriesBurned is in valid range', () {
      final workout = makeDay(exercises: [makeEx()], cardioMinutes: 10);
      session.startSession(workout, prepSeconds: 10);

      final kcal = session.estimatedCaloriesBurned;
      expect(kcal, greaterThanOrEqualTo(0));
      expect(kcal, lessThanOrEqualTo(9999));
    });
  });

  group('progressText', () {
    test('is empty when no workout', () {
      expect(session.progressText, '');
    });

    test('shows completed / total sets', () {
      final workout = makeDay(
        exercises: [
          makeEx(),
          makeEx(name: 'Deadlift', sets: 4, reps: '8'),
        ],
      );
      session.startSession(workout, prepSeconds: 10);
      session.syncState(
        exIdx: 0,
        setIdx: 1,
        phase: WorkoutPhase.exercise,
        phaseDuration: 45,
        phaseStart: DateTime.now(),
        completedSets: 3,
      );

      expect(session.progressText, isNotEmpty);
      expect(session.progressText, contains('3'));
    });
  });
}
