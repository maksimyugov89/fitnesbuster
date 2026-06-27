import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/core/services/nutrition_service.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart' show AiException;
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

import 'nutrition_service_test.mocks.dart';

@GenerateMocks([IDeepSeekService])
void main() {
  late MockIDeepSeekService mockAi;
  late NutritionService service;

  setUp(() {
    mockAi = MockIDeepSeekService();
    service = NutritionService(ai: mockAi);
  });

  group('shouldRegenerate', () {
    test('returns true when lastGenerated is null', () {
      expect(service.shouldRegenerate(null), isTrue);
    });

    test('returns false when generated 1 day ago', () {
      final recent = DateTime.now().subtract(const Duration(days: 1));
      expect(service.shouldRegenerate(recent), isFalse);
    });

    test('returns false when generated 6 days ago', () {
      final sixDays = DateTime.now().subtract(const Duration(days: 6));
      expect(service.shouldRegenerate(sixDays), isFalse);
    });

    test('returns true when generated exactly 7 days ago', () {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      expect(service.shouldRegenerate(weekAgo), isTrue);
    });

    test('returns true when generated more than 7 days ago', () {
      final old = DateTime.now().subtract(const Duration(days: 10));
      expect(service.shouldRegenerate(old), isTrue);
    });
  });

  group('generateMealPlan', () {
    const tProfile = UserProfile(
      weight: 80,
      height: 175,
      age: 30,
      gender: Gender.male,
      goal: FitnessGoal.loseWeight,
      intensity: IntensityLevel.balanced,
      activityLevel: ActivityLevel.moderatelyActive,
    );

    test('delegates to DeepSeekService.generateMealPlan', () async {
      when(mockAi.generateMealPlan(any, stepsToday: anyNamed('stepsToday')))
          .thenAnswer((_) async => '{"meals":[]}');

      final result = await service.generateMealPlan(tProfile);

      expect(result, '{"meals":[]}');
      verify(mockAi.generateMealPlan(any, stepsToday: anyNamed('stepsToday'))).called(1);
    });

    test('passes stepsToday to DeepSeekService', () async {
      when(mockAi.generateMealPlan(any, stepsToday: anyNamed('stepsToday')))
          .thenAnswer((_) async => '{"meals":[]}');

      await service.generateMealPlan(tProfile, stepsToday: 5000);

      verify(mockAi.generateMealPlan(any, stepsToday: 5000)).called(1);
    });

    test('propagates AiException from DeepSeekService', () async {
      when(mockAi.generateMealPlan(any, stepsToday: anyNamed('stepsToday')))
          .thenThrow(const AiException('API key not set'));

      expect(
        () => service.generateMealPlan(tProfile),
        throwsA(isA<AiException>()),
      );
    });
  });
}
