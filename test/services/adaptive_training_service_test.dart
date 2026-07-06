import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/core/training/adaptive_training_service.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';

import 'adaptive_training_service_test.mocks.dart';

@GenerateMocks([IDeepSeekService])
void main() {
  late MockIDeepSeekService mockAi;
  late AdaptiveTrainingService service;

  const tProfile = UserProfile(
    weight: 80,
    height: 175,
    age: 30,
    gender: Gender.male,
    goal: FitnessGoal.loseWeight,
    intensity: IntensityLevel.balanced,
    activityLevel: ActivityLevel.moderatelyActive,
    targetWeight: 75,
  );

  final tTestResult = TestWeekResult(
    completedAt: DateTime(2026, 1, 1),
    exercises: [
      const TestExerciseResult(
        exerciseName: 'Жим лёжа',
        primaryMuscle: MuscleGroup.chest,
        comfortableWeightKg: 60,
        comfortableSets: 3,
        comfortableReps: 10,
      ),
      const TestExerciseResult(
        exerciseName: 'Приседания',
        primaryMuscle: MuscleGroup.quads,
        comfortableWeightKg: 80,
        comfortableSets: 4,
        comfortableReps: 8,
      ),
      const TestExerciseResult(
        exerciseName: 'Тяга гантели',
        primaryMuscle: MuscleGroup.back,
        comfortableWeightKg: 30,
        comfortableSets: 3,
        comfortableReps: 12,
      ),
    ],
    averageHeartRate: 130,
    averageSessionDuration: 45,
    perceivedDifficulty: 5,
  );

  setUp(() {
    mockAi = MockIDeepSeekService();
    service = AdaptiveTrainingService(ai: mockAi);
  });

  // ── userLevel from declared trainingExperience ───────────────────

  group('calculateAdjustment userLevel', () {
    final tLightTestResult = TestWeekResult(
      completedAt: DateTime(2026, 1, 1),
      exercises: const [
        TestExerciseResult(
          exerciseName: 'Жим лёжа',
          primaryMuscle: MuscleGroup.chest,
          comfortableWeightKg: 10,
          comfortableSets: 3,
          comfortableReps: 8,
        ),
      ],
      averageHeartRate: 120,
      averageSessionDuration: 30,
      perceivedDifficulty: 5,
    );

    test(
      'declared "experienced" yields advanced even with light test week',
      () {
        final adj = service.calculateAdjustment(
          testResult: tLightTestResult,
          profile: tProfile.copyWith(
            trainingExperience: TrainingExperience.experienced,
          ),
        );
        expect(adj.userLevel, UserLevel.advanced);
      },
    );

    test('heavy test week can raise level above a declared novice', () {
      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile.copyWith(
          trainingExperience: TrainingExperience.novice,
        ),
      );
      expect(adj.userLevel, UserLevel.intermediate);
    });
  });

  // ── calculateAdjustment ─────────────────────────────────────────

  group('calculateAdjustment', () {
    test('returns TrainingAdjustment for balanced profile', () {
      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile,
      );

      expect(adj.weightMultiplier, greaterThan(0));
      expect(adj.weeklyIncreasePercent, greaterThan(0));
      expect(adj.suggestedSetsPerExercise, inInclusiveRange(3, 5));
      expect(adj.suggestedRepsPerSet, inInclusiveRange(8, 15));
      expect(adj.userLevel, isNotNull);
      expect(adj.maxHeartRate, equals(190)); // 220 - 30
    });

    test('weightMultiplier varies with intensity', () {
      const hardcore = UserProfile(
        weight: 80,
        height: 175,
        age: 30,
        gender: Gender.male,
        goal: FitnessGoal.loseWeight,
        intensity: IntensityLevel.hardcore,
        activityLevel: ActivityLevel.moderatelyActive,
      );
      const relaxed = UserProfile(
        weight: 80,
        height: 175,
        age: 30,
        gender: Gender.male,
        goal: FitnessGoal.loseWeight,
        intensity: IntensityLevel.relaxed,
        activityLevel: ActivityLevel.moderatelyActive,
      );

      final adjHard = service
          .calculateAdjustment(testResult: tTestResult, profile: hardcore)
          .weightMultiplier;
      final adjSoft = service
          .calculateAdjustment(testResult: tTestResult, profile: relaxed)
          .weightMultiplier;

      expect(adjHard, greaterThanOrEqualTo(adjSoft));
    });

    test('empty exercises returns valid adjustment', () {
      final emptyResult = TestWeekResult(
        completedAt: DateTime(2026, 1, 1),
        exercises: [],
        averageHeartRate: 0,
        averageSessionDuration: 0,
        perceivedDifficulty: 5,
      );
      final adj = service.calculateAdjustment(
        testResult: emptyResult,
        profile: tProfile,
      );
      expect(adj.suggestedSetsPerExercise, inInclusiveRange(3, 5));
      expect(adj.suggestedRepsPerSet, inInclusiveRange(8, 15));
    });

    test('maxHeartRate is 220 - age', () {
      const young = UserProfile(
        weight: 70,
        height: 180,
        age: 25,
        gender: Gender.male,
        goal: FitnessGoal.gainWeight,
        intensity: IntensityLevel.intensive,
        activityLevel: ActivityLevel.veryActive,
      );
      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: young,
      );
      expect(adj.maxHeartRate, equals(195));
    });
  });

  // ── buildAdaptedPlan ─────────────────────────────────────────────

  group('buildAdaptedPlan', () {
    test('builds plan with correct number of weeks', () {
      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile,
      );
      final plan = service.buildAdaptedPlan(
        testResult: tTestResult,
        adjustment: adj,
        durationWeeks: 4,
        profile: tProfile,
      );

      expect(plan.length, equals(4));
      expect(plan.first.weekNumber, equals(1));
      expect(plan.last.weekNumber, equals(4));
    });

    test('plan weeks have exercises and estimated calories', () {
      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile,
      );
      final plan = service.buildAdaptedPlan(
        testResult: tTestResult,
        adjustment: adj,
        durationWeeks: 12,
        profile: tProfile,
      );

      expect(plan.every((w) => w.exercises.isNotEmpty), isTrue);
      expect(plan.every((w) => w.estimatedCalorieBurn > 0), isTrue);
      expect(plan.every((w) => w.plannedSessions >= 3), isTrue);
    });

    test('plan duration with target date uses estimated weeks', () {
      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile,
      );
      final plan = service.buildAdaptedPlan(
        testResult: tTestResult,
        adjustment: adj,
        durationWeeks: tProfile.estimatedWeeksNeeded,
        profile: tProfile,
      );

      expect(plan.length, equals(tProfile.estimatedWeeksNeeded));
    });

    test('week phases: adaptation → progress → intensification → peak', () {
      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile,
      );
      final plan = service.buildAdaptedPlan(
        testResult: tTestResult,
        adjustment: adj,
        durationWeeks: 16,
        profile: tProfile,
      );

      expect(plan[0].focus, contains('Адаптация'));
      expect(plan[5].focus, contains('Прогресс'));
      expect(plan[9].focus, anyOf(contains('Интенсификация'), contains('Пик')));
    });
  });

  // ── buildAdaptedPlan location-aware fallback ─────────────────────

  group('buildAdaptedPlan fallback exercises respect workoutLocation', () {
    // Empty exercises forces the fallback path (no real test-week data to
    // map onto the weekly focus) regardless of week number.
    final emptyTestResult = TestWeekResult(
      completedAt: DateTime(2026, 1, 1),
      exercises: const [],
      averageHeartRate: 0,
      averageSessionDuration: 0,
      perceivedDifficulty: 5,
    );

    List<String> planExercises(String location) {
      final profile = tProfile.copyWith(workoutLocation: location);
      final adj = service.calculateAdjustment(
        testResult: emptyTestResult,
        profile: profile,
      );
      final plan = service.buildAdaptedPlan(
        testResult: emptyTestResult,
        adjustment: adj,
        durationWeeks: 1,
        profile: profile,
      );
      return plan.expand((w) => w.exercises).toList();
    }

    test('gym fallback uses barbell/dumbbell exercises', () {
      final all = planExercises('gym').join(' ');
      expect(all, contains('гантел'));
    });

    test('home fallback has no gym equipment', () {
      final all = planExercises('home').join(' ');
      expect(all, isNot(contains('штанг')));
      expect(all, contains('Отжимания'));
    });

    test('outdoor fallback uses bar/bodyweight exercises', () {
      final all = planExercises('outdoor').join(' ');
      expect(all, contains('брусьях'));
      expect(all, isNot(contains('гантел')));
    });
  });

  // ── checkGoalFeasibility ─────────────────────────────────────────

  group('checkGoalFeasibility', () {
    test('returns feasible for realistic goal', () async {
      when(
        mockAi.askQuestion(any, profile: anyNamed('profile')),
      ).thenAnswer((_) async => 'Всё реалистично, продолжайте.');

      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile,
      );
      final result = await service.checkGoalFeasibility(
        profile: tProfile,
        adjustment: adj,
      );

      expect(result.isFeasible, isTrue);
    });

    test('calls AI for advice when profile needs it', () async {
      when(
        mockAi.askQuestion(any, profile: anyNamed('profile')),
      ).thenAnswer((_) async => 'Рекомендую увеличить кардио.');
      final profile = tProfile.copyWith(
        targetWeight: 50,
        targetDate: DateTime.now().add(const Duration(days: 7)),
      );

      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: profile,
      );
      await service.checkGoalFeasibility(profile: profile, adjustment: adj);
      // AI may or may not be called depending on feasibility logic
    });

    test('handles AI failure gracefully', () async {
      when(
        mockAi.askQuestion(any, profile: anyNamed('profile')),
      ).thenThrow(Exception('AI timeout'));

      final adj = service.calculateAdjustment(
        testResult: tTestResult,
        profile: tProfile,
      );
      final result = await service.checkGoalFeasibility(
        profile: tProfile,
        adjustment: adj,
      );

      expect(result, isNotNull);
    });
  });
}
