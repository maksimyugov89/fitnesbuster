import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/core/ai/knowledge/training_knowledge.dart';
import 'package:fitnesbuster/core/services/recovery_score_service.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

void main() {
  const baseProfile = UserProfile(
    weight: 80,
    height: 180,
    age: 30,
    gender: Gender.male,
    goal: FitnessGoal.maintain,
    intensity: IntensityLevel.balanced,
    trainingExperience: TrainingExperience.intermediate,
    activityLevel: ActivityLevel.moderatelyActive,
  );

  group('methodologyEmphasisBlock', () {
    test('novice profile gets ОФП/non-failure directive', () {
      final block = methodologyEmphasisBlock(
        baseProfile.copyWith(
          trainingExperience: TrainingExperience.novice,
          goal: FitnessGoal.gainWeight,
          intensity: IntensityLevel.intensive,
        ),
      );
      expect(block, contains('начинающего'));
      expect(block, contains('НЕ доводи'));
    });

    test('relaxed intensity gets ОФП directive regardless of experience', () {
      final block = methodologyEmphasisBlock(
        baseProfile.copyWith(
          trainingExperience: TrainingExperience.experienced,
          intensity: IntensityLevel.relaxed,
        ),
      );
      expect(block, contains('начинающего'));
    });

    test('sportPerformance + experienced/intensive gets power emphasis', () {
      final block = methodologyEmphasisBlock(
        baseProfile.copyWith(
          goal: FitnessGoal.sportPerformance,
          trainingExperience: TrainingExperience.experienced,
          intensity: IntensityLevel.intensive,
        ),
      );
      expect(block, contains('взрывные/плиометрические'));
      expect(block, contains('перенос'));
    });

    test('gainWeight + balanced/intensive gets volume emphasis', () {
      final block = methodologyEmphasisBlock(
        baseProfile.copyWith(
          goal: FitnessGoal.gainWeight,
          intensity: IntensityLevel.balanced,
        ),
      );
      expect(block, contains('набор массы'));
    });

    test('low recovery score triggers intensity-reduction directive', () {
      const lowRecovery = RecoveryScore(
        score: 30,
        level: RecoveryLevel.low,
        label: 'Низкое',
        advice: '',
        shouldReduceIntensity: true,
      );
      final block = methodologyEmphasisBlock(
        baseProfile,
        recovery: lowRecovery,
      );
      expect(block, contains('Восстановление снижено'));
    });

    test('good recovery score does not trigger reduction directive', () {
      const goodRecovery = RecoveryScore(
        score: 90,
        level: RecoveryLevel.excellent,
        label: 'Отлично',
        advice: '',
        shouldReduceIntensity: false,
      );
      final block = methodologyEmphasisBlock(
        baseProfile,
        recovery: goodRecovery,
      );
      expect(block, isNot(contains('Восстановление снижено')));
    });

    test('sustained high RPE triggers fatigue/deload directive', () {
      final block = methodologyEmphasisBlock(baseProfile, recentAvgRpe: 9);
      expect(block, contains('накопленной усталости'));
    });

    test('noticeable/severe DOMS triggers muscle-rest directive', () {
      final block = methodologyEmphasisBlock(baseProfile, domsLevel: 2);
      expect(block, contains('DOMS'));
    });

    test('mild DOMS does not trigger muscle-rest directive', () {
      final block = methodologyEmphasisBlock(baseProfile, domsLevel: 1);
      expect(block, isNot(contains('DOMS')));
    });

    test('moderate RPE does not trigger fatigue directive', () {
      final block = methodologyEmphasisBlock(baseProfile, recentAvgRpe: 6);
      expect(block, isNot(contains('накопленной усталости')));
    });

    test(
      'intermediate/balanced/loseWeight profile with no signals returns empty string',
      () {
        final block = methodologyEmphasisBlock(
          baseProfile.copyWith(goal: FitnessGoal.loseWeight),
        );
        expect(block, isEmpty);
      },
    );
  });

  test('trainingPrinciplesCore mentions RPE/RIR and progressive overload', () {
    expect(trainingPrinciplesCore, contains('RPE'));
    expect(trainingPrinciplesCore, contains('Прогрессивная перегрузка'));
  });
}
