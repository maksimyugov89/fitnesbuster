part of 'test_week_bloc.dart';

sealed class TestWeekEvent extends Equatable {
  const TestWeekEvent();
  @override List<Object?> get props => [];
}

class TestWeekStartDay extends TestWeekEvent {
  final int dayIndex;
  final UserProfile? profile;
  const TestWeekStartDay({required this.dayIndex, this.profile});
  @override List<Object?> get props => [dayIndex, profile ?? ''];
}

class TestWeekRecordExercise extends TestWeekEvent {
  final String exerciseName;
  final MuscleGroup muscle;
  final double comfortableWeightKg;
  final int comfortableSets;
  final int comfortableReps;
  final String? notes;

  const TestWeekRecordExercise({
    required this.exerciseName,
    required this.muscle,
    required this.comfortableWeightKg,
    required this.comfortableSets,
    required this.comfortableReps,
    this.notes,
  });
  @override List<Object?> get props => [exerciseName, muscle, comfortableWeightKg, comfortableSets, comfortableReps, notes ?? ''];
}

class TestWeekFinishDay extends TestWeekEvent {
  const TestWeekFinishDay();
  @override List<Object?> get props => [];
}

class TestWeekComplete extends TestWeekEvent {
  final List<TestExerciseResult> results;
  const TestWeekComplete({required this.results});
  @override List<Object?> get props => [results];
}

class TestWeekAcceptPlan extends TestWeekEvent {
  const TestWeekAcceptPlan();
}

class TestWeekAdjustGoal extends TestWeekEvent {
  final String reason;
  final List<String> suggestions;
  const TestWeekAdjustGoal({required this.reason, required this.suggestions});
  @override List<Object?> get props => [reason, suggestions];
}
