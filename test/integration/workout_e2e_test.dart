import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/bloc/workout/workout_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

void main() {
  group('WorkoutBloc E2E', () {
    late WorkoutBloc bloc;

    setUp(() => bloc = WorkoutBloc());

    tearDown(() => bloc.close());

    blocTest<WorkoutBloc, WorkoutState>(
      'Normal flow: start → complete sets → finish',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(WorkoutStartRequested(session: _makeSession()));
        b.add(WorkoutSetCompleted(setLog: _makeSetLog(1, 12)));
        b.add(WorkoutSetCompleted(setLog: _makeSetLog(2, 10)));
        b.add(const WorkoutExerciseChanged(index: 1));
        b.add(WorkoutSetCompleted(setLog: _makeSetLog(1, 8)));
        b.add(const WorkoutStopRequested());
      },
      skip: 5,
      expect: () => [isA<WorkoutStateCompleted>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'Pause and resume mid-workout',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(WorkoutStartRequested(session: _makeSession()));
        b.add(WorkoutSetCompleted(setLog: _makeSetLog(1, 10)));
        b.add(const WorkoutPauseRequested());
        b.add(const WorkoutResumeRequested());
        b.add(WorkoutSetCompleted(setLog: _makeSetLog(2, 10)));
        b.add(const WorkoutStopRequested());
      },
      skip: 5,
      expect: () => [isA<WorkoutStateCompleted>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'Pause sets isPaused=true',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(WorkoutStartRequested(session: _makeSession()));
        b.add(const WorkoutPauseRequested());
      },
      skip: 1,
      expect: () => [
        isA<WorkoutStateInProgress>().having((s) => s.isPaused, 'paused', true),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'Resume after pause sets isPaused=false',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(WorkoutStartRequested(session: _makeSession()));
        b.add(const WorkoutPauseRequested());
        b.add(const WorkoutResumeRequested());
      },
      skip: 2,
      expect: () => [
        isA<WorkoutStateInProgress>().having(
          (s) => s.isPaused,
          'paused',
          false,
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'Cancel mid-workout without session emits error',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(const WorkoutStartRequested());
        b.add(const WorkoutStopRequested());
      },
      skip: 1,
      expect: () => [isA<WorkoutStateError>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'Stop when not in progress returns initial',
      build: () => WorkoutBloc(),
      act: (b) => b.add(const WorkoutStopRequested()),
      expect: () => [const WorkoutStateInitial()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'Exercise change updates index correctly',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(WorkoutStartRequested(session: _makeSession()));
        b.add(const WorkoutExerciseChanged(index: 2));
        b.add(const WorkoutExerciseChanged(index: 0));
      },
      skip: 1,
      expect: () => [
        isA<WorkoutStateInProgress>().having(
          (s) => s.currentExerciseIndex,
          'idx',
          2,
        ),
        isA<WorkoutStateInProgress>().having(
          (s) => s.currentExerciseIndex,
          'idx',
          0,
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'Empty plan: start without session still runs',
      build: () => WorkoutBloc(),
      act: (b) => b.add(const WorkoutStartRequested()),
      expect: () => [
        isA<WorkoutStateInProgress>()
            .having((s) => s.session, 'session', isNull)
            .having((s) => s.completedSets, 'completedSets', isEmpty),
      ],
    );
  });
}

WorkoutSession _makeSession() => const WorkoutSession(
  id: 'e2e-session-1',
  title: 'Chest Day',
  primaryMuscle: MuscleGroup.chest,
  exercises: [],
  estimatedDurationMinutes: 45,
  estimatedCaloriesBurn: 350,
  difficulty: DifficultyLevel.intermediate,
);

SetLog _makeSetLog(int setNumber, int reps) =>
    SetLog(setNumber: setNumber, reps: reps, weightKg: 60, completed: true);
