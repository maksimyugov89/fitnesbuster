import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/core/services/onboarding_workflow_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

import 'onboarding_workflow_service_test.mocks.dart';

@GenerateMocks([IDeepSeekService, IUserRepository])
void main() {
  late MockIDeepSeekService mockAi;
  late MockIUserRepository mockUserRepo;
  late OnboardingWorkflowService service;

  setUp(() {
    mockAi = MockIDeepSeekService();
    mockUserRepo = MockIUserRepository();
    service = OnboardingWorkflowService(aiService: mockAi, userRepo: mockUserRepo);
  });

  test('generatePlans returns workout and meal plan', () async {
    when(mockAi.generateWorkoutPlan(any)).thenAnswer((_) async => '{"workout":"test"}');
    when(mockAi.generateMealPlan(any, city: anyNamed('city')))
        .thenAnswer((_) async => '{"meals":["breakfast"]}');
    when(mockUserRepo.saveAiPlans(
      userId: anyNamed('userId'),
      workoutPlanJson: anyNamed('workoutPlanJson'),
      mealPlanJson: anyNamed('mealPlanJson'),
    )).thenAnswer((_) async {});

    final result = await service.generatePlans(
      userId: 'uid-1',
      profile: UserProfile.defaults,
    );

    expect(result.workoutPlanJson, '{"workout":"test"}');
    expect(result.mealPlanJson, '{"meals":["breakfast"]}');
    verify(mockUserRepo.saveAiPlans(
      userId: 'uid-1',
      workoutPlanJson: '{"workout":"test"}',
      mealPlanJson: '{"meals":["breakfast"]}',
    )).called(1);
  });

  test('generatePlans passes city to meal plan', () async {
    when(mockAi.generateWorkoutPlan(any)).thenAnswer((_) async => '{}');
    when(mockAi.generateMealPlan(any, city: 'Moscow')).thenAnswer((_) async => '{}');
    when(mockUserRepo.saveAiPlans(
      userId: anyNamed('userId'),
      workoutPlanJson: anyNamed('workoutPlanJson'),
      mealPlanJson: anyNamed('mealPlanJson'),
    )).thenAnswer((_) async {});

    await service.generatePlans(userId: 'uid-1', profile: UserProfile.defaults, city: 'Moscow');
    verify(mockAi.generateMealPlan(any, city: 'Moscow')).called(1);
  });

  test('generatePlans succeeds even when save fails', () async {
    when(mockAi.generateWorkoutPlan(any)).thenAnswer((_) async => '{"workout":"test"}');
    when(mockAi.generateMealPlan(any, city: anyNamed('city')))
        .thenAnswer((_) async => '{"meals":[]}');
    when(mockUserRepo.saveAiPlans(
      userId: anyNamed('userId'),
      workoutPlanJson: anyNamed('workoutPlanJson'),
      mealPlanJson: anyNamed('mealPlanJson'),
    )).thenThrow(Exception('Firestore error'));

    final result = await service.generatePlans(
      userId: 'uid-1',
      profile: UserProfile.defaults,
    );

    expect(result.workoutPlanJson, '{"workout":"test"}');
  });
}
