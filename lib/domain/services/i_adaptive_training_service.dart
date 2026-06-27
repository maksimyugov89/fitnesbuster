import 'package:fitnesbuster/domain/entities/entities.dart';

// ─── Supporting types ────────────────────────────────────────────

class AdaptiveWeek {
  final int weekNumber;
  final String focus;
  final List<String> exercises;
  final int plannedSessions;
  final double estimatedCalorieBurn;

  const AdaptiveWeek({
    required this.weekNumber,
    required this.focus,
    required this.exercises,
    required this.plannedSessions,
    required this.estimatedCalorieBurn,
  });
}

enum UserLevel { beginner, intermediate, advanced }

class TrainingAdjustment {
  final double weightMultiplier;
  final double weeklyIncreasePercent;
  final int suggestedSetsPerExercise;
  final int suggestedRepsPerSet;
  final UserLevel userLevel;
  final int maxHeartRate;
  final String adaptedIntensityLabel;

  const TrainingAdjustment({
    required this.weightMultiplier,
    required this.weeklyIncreasePercent,
    required this.suggestedSetsPerExercise,
    required this.suggestedRepsPerSet,
    required this.userLevel,
    required this.maxHeartRate,
    required this.adaptedIntensityLabel,
  });
}

class FeasibilityResult {
  final bool isFeasible;
  final String reason;
  final List<String> suggestedActions;

  const FeasibilityResult({
    required this.isFeasible,
    required this.reason,
    required this.suggestedActions,
  });
}

// ─── Interface ───────────────────────────────────────────────────

abstract interface class IAdaptiveTrainingService {
  TrainingAdjustment calculateAdjustment({
    required TestWeekResult testResult,
    required UserProfile profile,
  });

  Future<FeasibilityResult> checkGoalFeasibility({
    required UserProfile profile,
    required TrainingAdjustment adjustment,
  });

  List<AdaptiveWeek> buildAdaptedPlan({
    required TestWeekResult testResult,
    required TrainingAdjustment adjustment,
    required int durationWeeks,
  });
}
