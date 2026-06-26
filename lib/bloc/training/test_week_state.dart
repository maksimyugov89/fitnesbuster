part of 'test_week_bloc.dart';

sealed class TestWeekState extends Equatable {
  const TestWeekState();
  @override List<Object?> get props => [];
}

class TestWeekStateInitial extends TestWeekState {
  const TestWeekStateInitial();
}

/// The user is currently performing a test day.
class TestWeekStateDayInProgress extends TestWeekState {
  final int dayIndex;
  final List<TestDayExercise> dayExercises;
  final List<TestExerciseResult> completedExercises;
  final int overallRpe;
  final String sessionNotes;

  const TestWeekStateDayInProgress({
    required this.dayIndex,
    required this.dayExercises,
    required this.completedExercises,
    this.overallRpe = 5,
    this.sessionNotes = '',
  });

  TestWeekStateDayInProgress copyWith({
    int? dayIndex,
    List<TestDayExercise>? dayExercises,
    List<TestExerciseResult>? completedExercises,
    int? overallRpe,
    String? sessionNotes,
  }) {
    return TestWeekStateDayInProgress(
      dayIndex: dayIndex ?? this.dayIndex,
      dayExercises: dayExercises ?? this.dayExercises,
      completedExercises: completedExercises ?? this.completedExercises,
      overallRpe: overallRpe ?? this.overallRpe,
      sessionNotes: sessionNotes ?? this.sessionNotes,
    );
  }

  @override List<Object?> get props => [dayIndex, dayExercises, completedExercises, overallRpe, sessionNotes];
}

/// A day was completed, showing summary before next day.
class TestWeekStateDayCompleted extends TestWeekState {
  final int dayIndex;
  final List<TestExerciseResult> exercisesCompleted;
  final int nextDayIndex;
  final int totalDays;

  const TestWeekStateDayCompleted({
    required this.dayIndex,
    required this.exercisesCompleted,
    required this.nextDayIndex,
    required this.totalDays,
  });
  @override List<Object?> get props => [dayIndex, exercisesCompleted, nextDayIndex, totalDays];
}

/// AI is calculating the adapted plan.
class TestWeekStateCalculating extends TestWeekState {
  const TestWeekStateCalculating();
}

/// All test days done, plan calculated, showing results.
class TestWeekStateCompleted extends TestWeekState {
  final TestWeekResult testResult;
  final TrainingAdjustment adjustment;
  final List<AdaptiveWeek> adaptedPlan;
  final FeasibilityResult feasibility;

  const TestWeekStateCompleted({
    required this.testResult,
    required this.adjustment,
    required this.adaptedPlan,
    required this.feasibility,
  });
  @override List<Object?> get props => [testResult, adjustment, adaptedPlan, feasibility];
}

/// User accepted the adapted plan.
class TestWeekStatePlanAccepted extends TestWeekState {
  const TestWeekStatePlanAccepted();
}

/// Goal is unrealistic — user needs to adjust.
class TestWeekStateNeedsAdjustment extends TestWeekState {
  final String reason;
  final List<String> suggestions;

  const TestWeekStateNeedsAdjustment({
    required this.reason,
    required this.suggestions,
  });
  @override List<Object?> get props => [reason, suggestions];
}
