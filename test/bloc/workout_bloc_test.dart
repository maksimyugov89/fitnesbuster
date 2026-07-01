import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/bloc/workout/workout_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

void main() {
  group('WorkoutBloc', () {
    late WorkoutBloc bloc;

    setUp(() => bloc = WorkoutBloc());
    tearDown(() => bloc.close());

    test('initial state is WorkoutStateInitial', () {
      expect(bloc.state, const WorkoutStateInitial());
    });

    blocTest<WorkoutBloc, WorkoutState>(
      'start emits WorkoutStateInProgress with index 0',
      build: () => WorkoutBloc(),
      act: (b) => b.add(const WorkoutStartRequested()),
      expect: () => [
        isA<WorkoutStateInProgress>()
            .having((s) => s.currentExerciseIndex, 'index', 0)
            .having((s) => s.isPaused, 'isPaused', false)
            .having((s) => s.completedSets, 'completedSets', isEmpty),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'pause sets isPaused = true',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(const WorkoutStartRequested());
        b.add(const WorkoutPauseRequested());
      },
      skip: 1,
      expect: () => [
        isA<WorkoutStateInProgress>().having(
          (s) => s.isPaused,
          'isPaused',
          true,
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'resume after pause sets isPaused = false',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(const WorkoutStartRequested());
        b.add(const WorkoutPauseRequested());
        b.add(const WorkoutResumeRequested());
      },
      skip: 2,
      expect: () => [
        isA<WorkoutStateInProgress>().having(
          (s) => s.isPaused,
          'isPaused',
          false,
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'stop emits WorkoutStateError when in progress without session',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(const WorkoutStartRequested());
        b.add(const WorkoutStopRequested());
      },
      skip: 1,
      expect: () => [isA<WorkoutStateError>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'stop with session emits WorkoutStateCompleted',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(WorkoutStartRequested(session: _makeSession()));
        b.add(const WorkoutStopRequested());
      },
      skip: 1,
      expect: () => [isA<WorkoutStateCompleted>()],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'setCompleted appends to completedSets',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(const WorkoutStartRequested());
        b.add(WorkoutSetCompleted(setLog: _makeSetLog()));
      },
      skip: 1,
      expect: () => [
        isA<WorkoutStateInProgress>().having(
          (s) => s.completedSets.length,
          'sets count',
          1,
        ),
      ],
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'exerciseChanged updates currentExerciseIndex',
      build: () => WorkoutBloc(),
      act: (b) {
        b.add(const WorkoutStartRequested());
        b.add(const WorkoutExerciseChanged(index: 3));
      },
      skip: 1,
      expect: () => [
        isA<WorkoutStateInProgress>().having(
          (s) => s.currentExerciseIndex,
          'index',
          3,
        ),
      ],
    );
  });
}

WorkoutSession _makeSession() => const WorkoutSession(
  id: 'test-session',
  title: 'Test',
  primaryMuscle: MuscleGroup.chest,
  exercises: [],
  estimatedDurationMinutes: 30,
  estimatedCaloriesBurn: 200,
  difficulty: DifficultyLevel.beginner,
);

SetLog _makeSetLog() => const SetLog(setNumber: 1, reps: 10, completed: true);
