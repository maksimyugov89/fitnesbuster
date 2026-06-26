part of 'workout_bloc.dart';

sealed class WorkoutState extends Equatable {
  const WorkoutState();
  @override List<Object?> get props => [];
}

class WorkoutStateInitial extends WorkoutState {
  const WorkoutStateInitial();
}

class WorkoutStateInProgress extends WorkoutState {
  final WorkoutSession? session;
  final int currentExerciseIndex;
  final List<SetLog> completedSets;
  final int elapsedSeconds;
  final bool isPaused;

  const WorkoutStateInProgress({
    this.session,
    this.currentExerciseIndex = 0,
    this.completedSets = const [],
    this.elapsedSeconds = 0,
    this.isPaused = false,
  });

  WorkoutStateInProgress copyWith({
    WorkoutSession? session,
    int? currentExerciseIndex,
    List<SetLog>? completedSets,
    int? elapsedSeconds,
    bool? isPaused,
  }) {
    return WorkoutStateInProgress(
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      completedSets: completedSets ?? this.completedSets,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override List<Object?> get props => [session ?? '', currentExerciseIndex, completedSets, elapsedSeconds, isPaused];
}

class WorkoutStateCompleted extends WorkoutState {
  final String sessionId;
  final int elapsedSeconds;
  final List<SetLog> completedSets;

  const WorkoutStateCompleted({
    required this.sessionId,
    required this.elapsedSeconds,
    required this.completedSets,
  });
  @override List<Object?> get props => [sessionId, elapsedSeconds, completedSets];
}

class WorkoutStateError extends WorkoutState {
  final String message;
  const WorkoutStateError({required this.message});
  @override List<Object?> get props => [message];
}
