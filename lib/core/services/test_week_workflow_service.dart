import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class TestWeekWorkflowService {
  final IAdaptiveTrainingService _trainingService;

  TestWeekWorkflowService({required IAdaptiveTrainingService trainingService})
    : _trainingService = trainingService;

  Future<
    ({
      TrainingAdjustment adjustment,
      FeasibilityResult feasibility,
      List<AdaptiveWeek> adaptedPlan,
      TestWeekResult testResult,
    })
  >
  calculateResults({
    required List<TestExerciseResult> exercises,
    required UserProfile profile,
    int perceivedDifficulty = 5,
  }) async {
    final testResult = TestWeekResult(
      completedAt: DateTime.now(),
      exercises: exercises,
      averageHeartRate: 0,
      averageSessionDuration: 0,
      perceivedDifficulty: perceivedDifficulty,
    );

    final adjustment = _trainingService.calculateAdjustment(
      testResult: testResult,
      profile: profile,
    );

    FeasibilityResult feasibility;
    try {
      feasibility = await _trainingService.checkGoalFeasibility(
        profile: profile,
        adjustment: adjustment,
      );
    } catch (e, st) {
      appLogger.w(
        '[TestWeekWorkflow] feasibility check failed',
        error: e,
        stackTrace: st,
      );
      feasibility = FeasibilityResult(
        isFeasible: true,
        reason: AppLocalizations.tl('testWeekPlanReady'),
        suggestedActions: [],
      );
    }

    final adaptedPlan = _trainingService.buildAdaptedPlan(
      testResult: testResult,
      adjustment: adjustment,
      durationWeeks: profile.targetDate != null
          ? profile.estimatedWeeksNeeded
          : 12,
      profile: profile,
    );

    return (
      adjustment: adjustment,
      feasibility: feasibility,
      adaptedPlan: adaptedPlan,
      testResult: testResult,
    );
  }
}
