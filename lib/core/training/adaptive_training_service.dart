import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

/// Results of an adaptive training calculation.
class AdaptiveTrainingResult {
  final List<AdaptiveWeek> adjustedPlan;
  final bool isGoalRealistic;
  final String? recommendation;
  final String? warning;

  const AdaptiveTrainingResult({
    required this.adjustedPlan,
    required this.isGoalRealistic,
    this.recommendation,
    this.warning,
  });
}

/// Service that processes test week results and builds an adaptive training plan.
class AdaptiveTrainingService implements IAdaptiveTrainingService {
  final IDeepSeekService _ai;

  AdaptiveTrainingService({required IDeepSeekService ai}) : _ai = ai;

  /// Calculates adjusted training parameters based on test week results.
  @override
  TrainingAdjustment calculateAdjustment({
    required TestWeekResult testResult,
    required UserProfile profile,
  }) {
    // Base multipliers per intensity
    final intensityMultiplier = _getIntensityMultiplier(profile.intensity);

    // Calculate the user's actual capacity vs expected beginner capacity
    final count = testResult.exercises.length;
    final avgWeight = count > 0
        ? testResult.exercises.fold<double>(0.0, (sum, e) => sum + e.comfortableWeightKg) / count
        : 0.0;
    final avgReps = count > 0
        ? testResult.exercises.fold<double>(0.0, (sum, e) => sum + e.comfortableReps) / count
        : 0.0;
    final avgSets = count > 0
        ? testResult.exercises.fold<double>(0.0, (sum, e) => sum + e.comfortableSets) / count
        : 0.0;

    // Determine user level
    final userLevel = _determineLevel(avgWeight, avgReps, profile);

    // Calculate progression speed
    final progressionSpeed = _calculateProgressionSpeed(
      testResult.perceivedDifficulty,
      userLevel,
      intensityMultiplier,
    );

    return TrainingAdjustment(
      weightMultiplier: progressionSpeed.weightMultiplier,
      weeklyIncreasePercent: progressionSpeed.weeklyIncreasePercent,
      suggestedSetsPerExercise: avgSets.isFinite ? avgSets.round().clamp(3, 5) : 4,
      suggestedRepsPerSet: avgReps.isFinite ? avgReps.round().clamp(8, 15) : 10,
      userLevel: userLevel,
      maxHeartRate: 220 - profile.age,
      adaptedIntensityLabel: _adaptIntensityLabel(userLevel, profile.intensity),
    );
  }

  /// Checks if the user's goal is feasible within the chosen timeframe.
  @override
  Future<FeasibilityResult> checkGoalFeasibility({
    required UserProfile profile,
    required TrainingAdjustment adjustment,
  }) async {
    final weeksNeeded = profile.estimatedWeeksNeeded;
    final intensityLabel = _intensityLabel(profile.intensity);
    final goalLabel = _fitnessGoalLabel(profile.goal);

    // Basic feasibility check
    if (!profile.isGoalRealistic) {
      // Goal is not realistic — try AI for recommendation
      final aiAdvice = await _getAiFeasibilityAdvice(profile, adjustment);
      return FeasibilityResult(
        isFeasible: false,
        reason: '''
Выбрана цель: $goalLabel (уровень: $intensityLabel)
Текущий вес: ${profile.weight} кг
Целевой вес: ${profile.targetWeight ?? 'не указан'} кг
Оценка: Нереалистично за выбранный срок.

Рекомендация: $aiAdvice
''',
        suggestedActions: [
          'Увеличить срок достижения цели',
          'Снизить интенсивность на уровень ниже',
          'Изменить целевую дату',
        ],
      );
    }

    final totalCalorieNeeded = (profile.weight - (profile.targetWeight ?? profile.weight)).abs() * 7700; // 7700 kcal per kg
    final dailyDeficit = profile.dailyCalorieTarget < profile.tdee
        ? profile.tdee - profile.dailyCalorieTarget
        : 0;
    final estimatedWeeks = dailyDeficit > 0
        ? (totalCalorieNeeded / (dailyDeficit * 7)).round()
        : weeksNeeded;

    if (estimatedWeeks > weeksNeeded * 1.3) {
      final aiAdvice = await _getAiFeasibilityAdvice(profile, adjustment);
      return FeasibilityResult(
        isFeasible: false,
        reason: '''
Цель $goalLabel требует ~$estimatedWeeks недель при текущем дефиците ${dailyDeficit.toInt()} ккал/день.

Выбрано: $weeksNeeded недель — маловато.

Рекомендация: $aiAdvice
''',
        suggestedActions: [
          'Увеличить дефицит калорий (не более -700 ккал/день)',
          'Добавить 1 дополнительную кардио-тренировку в неделю',
          'Увеличить срок программы',
        ],
      );
    }

    return const FeasibilityResult(
      isFeasible: true,
      reason: 'Цель реалистична при текущих параметрах. ✅',
      suggestedActions: [],
    );
  }

  /// Builds the adapted weekly plan from test results.
  @override
  List<AdaptiveWeek> buildAdaptedPlan({
    required TestWeekResult testResult,
    required TrainingAdjustment adjustment,
    required int durationWeeks,
  }) {
    final focusRotation = [
      'Грудь + Трицепс',
      'Спина + Бицепс',
      'Отдых / Кардио',
      'Плечи + Пресс',
      'Ноги',
      'Кардио + Функциональный',
      'Отдых',
    ];

    return List.generate(durationWeeks, (i) {
      final weekNum = i + 1;
      final phase = weekNum <= 4
          ? 'Адаптация'
          : weekNum <= 8
              ? 'Прогресс'
              : weekNum <= 12
                  ? 'Интенсификация'
                  : 'Пик';

      // Each week focuses on a muscle group, rotating
      final focusIdx = weekNum % focusRotation.length;
      final exercisesThisWeek = _selectExercises(
        testResult,
        adjustment,
        focusRotation[focusIdx],
        weekNum,
      );

      return AdaptiveWeek(
        weekNumber: weekNum,
        focus: 'Неделя $weekNum — $phase ($focusRotation[focusIdx])',
        exercises: exercisesThisWeek,
        plannedSessions: _getSessionsPerWeek(adjustment.userLevel),
        estimatedCalorieBurn: exercisesThisWeek.length * 150,
      );
    });
  }

  // ─── Internal helpers ──────────────────────────────────────────

  double _getIntensityMultiplier(IntensityLevel level) {
    switch (level) {
      case IntensityLevel.hardcore: return 1.2;
      case IntensityLevel.intensive: return 1.1;
      case IntensityLevel.balanced: return 1.0;
      case IntensityLevel.gradual: return 0.9;
      case IntensityLevel.relaxed: return 0.8;
    }
  }

  UserLevel _determineLevel(double avgWeight, double avgReps, UserProfile profile) {
    // Simple heuristic: compare weight to body weight
    final weightRatio = avgWeight / profile.weight;
    if (weightRatio > 0.5 && avgReps >= 10) return UserLevel.intermediate;
    if (weightRatio > 0.3) return UserLevel.beginner;
    return UserLevel.beginner;
  }

  _ProgressionSpeed _calculateProgressionSpeed(
    int rpe,
    UserLevel level,
    double intensityMult,
  ) {
    // RPE 1-10, lower = easier = faster progression
    final baseSpeed = (10 - rpe) / 10.0;
    final levelBonus = level == UserLevel.beginner ? 0.1 : 0.0;
    final speed = (baseSpeed + levelBonus) * intensityMult;
    return _ProgressionSpeed(
      weightMultiplier: speed.clamp(0.5, 1.5),
      weeklyIncreasePercent: (speed * 0.05).clamp(0.02, 0.10),
    );
  }

  String _adaptIntensityLabel(UserLevel level, IntensityLevel chosen) {
    if (level == UserLevel.beginner && chosen == IntensityLevel.hardcore) {
      return 'Понижена (начинающий)';
    }
    return _intensityLabel(chosen);
  }

  List<String> _selectExercises(
    TestWeekResult testResult,
    TrainingAdjustment adjustment,
    String focus,
    int weekNum,
  ) {
    // Map test exercises to the focus area
    final available = testResult.exercises.where((e) {
      return _muscleGroupToFocus(e.primaryMuscle) == focus || weekNum <= 4;
    }).toList();

    if (available.isEmpty) {
      // Fallback exercises by focus
      return _fallbackExercises(focus, adjustment);
    }

    return available.map((e) =>
      '${e.exerciseName} — ${adjustment.suggestedSetsPerExercise}×${adjustment.suggestedRepsPerSet} @ ${(e.comfortableWeightKg * (1 + (weekNum - 1) * adjustment.weeklyIncreasePercent)).toStringAsFixed(1)} кг'
    ).toList();
  }

  List<String> _fallbackExercises(String focus, TrainingAdjustment adj) {
    final sets = adj.suggestedSetsPerExercise;
    final reps = adj.suggestedRepsPerSet;
    final all = [
      'Жим лёжа — $sets×$reps',
      'Тяга гантели — $sets×$reps',
      'Жим гантелей сидя — $sets×$reps',
      'Приседания — $sets×$reps',
      'Тяга верхнего блока — $sets×$reps',
      'Разгибание ног — $sets×$reps',
    ];
    return all.take(4).toList();
  }

  String _muscleGroupToFocus(MuscleGroup mg) {
    switch (mg) {
      case MuscleGroup.chest: return 'Грудь + Трицепс';
      case MuscleGroup.back: return 'Спина + Бицепс';
      case MuscleGroup.shoulders: return 'Плечи + Пресс';
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves: return 'Ноги';
      default: return 'Грудь + Трицепс';
    }
  }

  int _getSessionsPerWeek(UserLevel level) {
    switch (level) {
      case UserLevel.beginner: return 3;
      case UserLevel.intermediate: return 4;
      case UserLevel.advanced: return 5;
    }
  }

  Future<String> _getAiFeasibilityAdvice(
    UserProfile profile,
    TrainingAdjustment adjustment,
  ) async {
    try {
      return await _ai.askQuestion(
        'Моя цель: ${_fitnessGoalLabel(profile.goal)}. '
        'Вес: ${profile.weight} кг, целевой вес: ${profile.targetWeight?.toStringAsFixed(0) ?? "не указан"} кг. '
        'Выбранный уровень: ${_intensityLabel(profile.intensity)}. '
        'Что мне делать, чтобы достичь цели? Дай короткий совет.',
        profile: profile,
      );
    } catch (_) {
      return 'Попробуй увеличить срок программы на ${profile.estimatedWeeksNeeded} недель или снизить интенсивность на уровень.';
    }
  }

  String _fitnessGoalLabel(FitnessGoal g) {
    switch (g) {
      case FitnessGoal.loseWeight: return AppLocalizations.tl('trainingWeightLoss');
      case FitnessGoal.gainWeight: return AppLocalizations.tl('trainingMuscleGain');
      case FitnessGoal.maintain: return AppLocalizations.tl('trainingMaintenance');
      case FitnessGoal.beachBody: return AppLocalizations.tl('trainingBeachSeason');
      case FitnessGoal.sportPerformance: return AppLocalizations.tl('trainingSport');
    }
  }

  String _intensityLabel(IntensityLevel i) {
    switch (i) {
      case IntensityLevel.hardcore: return AppLocalizations.tl('trainingHardcore');
      case IntensityLevel.intensive: return AppLocalizations.tl('trainingIntense');
      case IntensityLevel.balanced: return AppLocalizations.tl('trainingBalanced');
      case IntensityLevel.gradual: return AppLocalizations.tl('trainingGradual');
      case IntensityLevel.relaxed: return AppLocalizations.tl('trainingLight');
    }
  }
}

// ─── Supporting types ────────────────────────────────────────────

class _ProgressionSpeed {
  final double weightMultiplier;
  final double weeklyIncreasePercent;
  const _ProgressionSpeed({
    required this.weightMultiplier,
    required this.weeklyIncreasePercent,
  });
}
