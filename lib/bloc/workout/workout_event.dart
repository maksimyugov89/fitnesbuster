part of 'workout_bloc.dart';

sealed class WorkoutEvent extends Equatable {
  const WorkoutEvent();
  @override List<Object?> get props => [];
}

class WorkoutStartRequested extends WorkoutEvent {
  final WorkoutSession? session;
  const WorkoutStartRequested({this.session});
  @override List<Object?> get props => [session ?? ''];
}

class WorkoutPauseRequested extends WorkoutEvent {
  const WorkoutPauseRequested();
}

class WorkoutResumeRequested extends WorkoutEvent {
  const WorkoutResumeRequested();
}

class WorkoutStopRequested extends WorkoutEvent {
  const WorkoutStopRequested();
}

class WorkoutSetCompleted extends WorkoutEvent {
  final SetLog setLog;
  const WorkoutSetCompleted({required this.setLog});
  @override List<Object?> get props => [setLog];
}

class WorkoutExerciseChanged extends WorkoutEvent {
  final int index;
  const WorkoutExerciseChanged({required this.index});
  @override List<Object?> get props => [index];
}

class WorkoutTick extends WorkoutEvent {
  const WorkoutTick();
}
