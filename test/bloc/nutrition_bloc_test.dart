import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/nutrition/nutrition_bloc.dart';
import 'package:fitnesbuster/core/services/nutrition_service.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

import 'nutrition_bloc_test.mocks.dart';

@GenerateMocks([NutritionService])
void main() {
  late MockNutritionService nutritionService;

  const tProfile = UserProfile(
    weight: 80,
    height: 175,
    age: 30,
    gender: Gender.male,
    goal: FitnessGoal.loseWeight,
    intensity: IntensityLevel.balanced,
    activityLevel: ActivityLevel.moderatelyActive,
  );

  const tFood = FoodItem(
    id: 'food-1',
    name: 'Banana',
    nutrition: NutritionPer100g(calories: 89, protein: 1.1, carbs: 23, fat: 0.3),
  );

  final tMealLog = MealLog(
    id: 'log-1',
    userId: 'uid-1',
    date: DateTime(2024, 1, 1),
    mealType: MealType.breakfast,
    foods: const [],
  );

  NutritionState makeLoadedState() => NutritionStateLoaded(
        logs: [tMealLog],
        targetCalories: 2000,
        targetProtein: 150,
        targetCarbs: 200,
        targetFat: 70,
      );

  setUp(() {
    nutritionService = MockNutritionService();
    when(nutritionService.shouldRegenerate(any)).thenReturn(false);
  });

  NutritionBloc makeBloc() => NutritionBloc(nutritionService: nutritionService);

  test('initial state is NutritionStateInitial', () {
    final bloc = makeBloc();
    expect(bloc.state, const NutritionStateInitial());
    bloc.close();
  });

  group('NutritionLoadRequested', () {
    blocTest<NutritionBloc, NutritionState>(
      'emits Loading then Loaded with empty logs',
      build: makeBloc,
      act: (b) => b.add(const NutritionLoadRequested(userId: 'uid-1')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const NutritionStateLoading(),
        isA<NutritionStateLoaded>()
            .having((s) => s.logs, 'logs', isEmpty)
            .having((s) => s.targetCalories, 'targetCalories', 0.0),
      ],
    );

    blocTest<NutritionBloc, NutritionState>(
      'no extra state emitted when shouldRegenerate is true but profile is null',
      build: makeBloc,
      setUp: () => when(nutritionService.shouldRegenerate(any)).thenReturn(true),
      act: (b) => b.add(const NutritionLoadRequested(userId: 'uid-1')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        const NutritionStateLoading(),
        isA<NutritionStateLoaded>(),
      ],
    );
  });

  group('NutritionRegenerateMealPlan', () {
    blocTest<NutritionBloc, NutritionState>(
      'emits updated Loaded with mealPlanJson on success',
      build: makeBloc,
      seed: makeLoadedState,
      setUp: () {
        when(nutritionService.generateMealPlan(any))
            .thenAnswer((_) async => '{"meals": []}');
      },
      act: (b) => b.add(const NutritionRegenerateMealPlan(profile: tProfile)),
      expect: () => [
        isA<NutritionStateLoaded>()
            .having((s) => s.mealPlanJson, 'mealPlanJson', '{"meals": []}')
            .having((s) => s.mealPlanError, 'mealPlanError', isNull),
      ],
    );

    blocTest<NutritionBloc, NutritionState>(
      'emits Loaded with mealPlanError when service throws',
      build: makeBloc,
      seed: makeLoadedState,
      setUp: () {
        when(nutritionService.generateMealPlan(any))
            .thenThrow(Exception('network error'));
      },
      act: (b) => b.add(const NutritionRegenerateMealPlan(profile: tProfile)),
      expect: () => [
        isA<NutritionStateLoaded>()
            .having((s) => s.mealPlanError, 'mealPlanError', isNotNull)
            .having((s) => s.mealPlanJson, 'mealPlanJson', isNull),
      ],
    );

    blocTest<NutritionBloc, NutritionState>(
      'does nothing when state is not Loaded',
      build: makeBloc,
      act: (b) => b.add(const NutritionRegenerateMealPlan(profile: tProfile)),
      expect: () => [],
    );

    blocTest<NutritionBloc, NutritionState>(
      'does nothing when profile is null',
      build: makeBloc,
      seed: makeLoadedState,
      act: (b) => b.add(const NutritionRegenerateMealPlan()),
      expect: () => [],
    );
  });

  group('NutritionAddFood', () {
    blocTest<NutritionBloc, NutritionState>(
      'appends FoodEntry to matching MealLog',
      build: makeBloc,
      seed: makeLoadedState,
      act: (b) => b.add(const NutritionAddFood(
        mealType: MealType.breakfast,
        food: tFood,
        grams: 150,
      )),
      expect: () => [
        isA<NutritionStateLoaded>().having(
          (s) => s.logs.first.foods.length,
          'foods count',
          1,
        ),
      ],
    );

    blocTest<NutritionBloc, NutritionState>(
      'food entry has correct grams',
      build: makeBloc,
      seed: makeLoadedState,
      act: (b) => b.add(const NutritionAddFood(
        mealType: MealType.breakfast,
        food: tFood,
        grams: 200,
      )),
      expect: () => [
        isA<NutritionStateLoaded>().having(
          (s) => s.logs.first.foods.first.grams,
          'grams',
          200.0,
        ),
      ],
    );

    blocTest<NutritionBloc, NutritionState>(
      'does nothing when state is not Loaded',
      build: makeBloc,
      act: (b) => b.add(const NutritionAddFood(
        mealType: MealType.breakfast,
        food: tFood,
        grams: 100,
      )),
      expect: () => [],
    );
  });

  group('NutritionRemoveFood', () {
    final logWithFood = MealLog(
      id: 'log-1',
      userId: 'uid-1',
      date: DateTime(2024, 1, 1),
      mealType: MealType.breakfast,
      foods: const [FoodEntry(food: tFood, grams: 100)],
    );

    NutritionState loadedWithFood() => NutritionStateLoaded(
          logs: [logWithFood],
          targetCalories: 2000,
          targetProtein: 150,
          targetCarbs: 200,
          targetFat: 70,
        );

    blocTest<NutritionBloc, NutritionState>(
      'removes FoodEntry by foodId',
      build: makeBloc,
      seed: loadedWithFood,
      act: (b) => b.add(const NutritionRemoveFood(
        mealType: MealType.breakfast,
        foodId: 'food-1',
      )),
      expect: () => [
        isA<NutritionStateLoaded>().having(
          (s) => s.logs.first.foods,
          'foods',
          isEmpty,
        ),
      ],
    );

    blocTest<NutritionBloc, NutritionState>(
      'does nothing when state is not Loaded',
      build: makeBloc,
      act: (b) => b.add(const NutritionRemoveFood(
        mealType: MealType.breakfast,
        foodId: 'food-1',
      )),
      expect: () => [],
    );

    blocTest<NutritionBloc, NutritionState>(
      'does not emit when foodId does not match (state unchanged)',
      build: makeBloc,
      seed: loadedWithFood,
      act: (b) => b.add(const NutritionRemoveFood(
        mealType: MealType.breakfast,
        foodId: 'nonexistent',
      )),
      // NutritionStateLoaded uses Equatable — no emission when state is unchanged
      expect: () => [],
    );
  });
}
