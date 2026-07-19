part of 'test_week_bloc.dart';

sealed class TestWeekState extends Equatable {
  const TestWeekState();
  @override
  List<Object?> get props => [];
}

class TestWeekStateInitial extends TestWeekState {
  const TestWeekStateInitial();
}

/// The user is currently performing a test day.
class TestWeekStateDayInProgress extends TestWeekState {
  final int dayIndex;
  final List<TestDayExercise> dayExercises;
  final List<TestExerciseResult> completedExercises;

  const TestWeekStateDayInProgress({
    required this.dayIndex,
    required this.dayExercises,
    required this.completedExercises,
  });

  TestWeekStateDayInProgress copyWith({
    int? dayIndex,
    List<TestDayExercise>? dayExercises,
    List<TestExerciseResult>? completedExercises,
  }) {
    return TestWeekStateDayInProgress(
      dayIndex: dayIndex ?? this.dayIndex,
      dayExercises: dayExercises ?? this.dayExercises,
      completedExercises: completedExercises ?? this.completedExercises,
    );
  }

  @override
  List<Object?> get props => [dayIndex, dayExercises, completedExercises];
}

/// A day was completed, showing summary before next day.
class TestWeekStateDayCompleted extends TestWeekState {
  final int dayIndex;
  final List<TestExerciseResult> exercisesCompleted;
  final int nextDayIndex;
  final int totalDays;
  final DateTime nextAvailableAt;
  final bool nextDayAvailable;

  const TestWeekStateDayCompleted({
    required this.dayIndex,
    required this.exercisesCompleted,
    required this.nextDayIndex,
    required this.totalDays,
    required this.nextAvailableAt,
    required this.nextDayAvailable,
  });
  @override
  List<Object?> get props => [
    dayIndex,
    exercisesCompleted,
    nextDayIndex,
    totalDays,
    nextAvailableAt,
    nextDayAvailable,
  ];
}

/// The next assessment workout is intentionally separated by a recovery day.
class TestWeekStateDayScheduled extends TestWeekState {
  final int dayIndex;
  final int totalDays;
  final DateTime availableAt;

  const TestWeekStateDayScheduled({
    required this.dayIndex,
    required this.totalDays,
    required this.availableAt,
  });

  @override
  List<Object?> get props => [dayIndex, totalDays, availableAt];
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
  @override
  List<Object?> get props => [testResult, adjustment, adaptedPlan, feasibility];
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
  @override
  List<Object?> get props => [reason, suggestions];
}

/// Error during plan acceptance.
class TestWeekStateError extends TestWeekState {
  final String message;
  const TestWeekStateError(this.message);
  @override
  List<Object?> get props => [message];
}
