import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/core/services/nutrition_service.dart';

part 'nutrition_event.dart';
part 'nutrition_state.dart';

class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final NutritionService _nutritionService;
  DateTime? _lastMealPlanGenerated;

  NutritionBloc({required NutritionService nutritionService})
      : _nutritionService = nutritionService,
        super(const NutritionStateInitial()) {
    on<NutritionLoadRequested>(_onLoad);
    on<NutritionAddFood>(_onAddFood);
    on<NutritionRemoveFood>(_onRemoveFood);
    on<NutritionRegenerateMealPlan>(_onRegenerateMealPlan);
  }

  Future<void> _onLoad(NutritionLoadRequested event, Emitter<NutritionState> emit) async {
    emit(const NutritionStateLoading());

    final profile = event.profile;
    final targetCalories = profile?.dailyCalorieTarget.round() ?? 0;
    // Macro split: protein 30%, carbs 40%, fat 30%
    final targetProtein = profile != null ? ((targetCalories * 0.30) / 4).round() : 0;
    final targetCarbs   = profile != null ? ((targetCalories * 0.40) / 4).round() : 0;
    final targetFat     = profile != null ? ((targetCalories * 0.30) / 9).round() : 0;

    emit(NutritionStateLoaded(
      logs: [],
      targetCalories: targetCalories.toDouble(),
      targetProtein: targetProtein.toDouble(),
      targetCarbs: targetCarbs.toDouble(),
      targetFat: targetFat.toDouble(),
    ));

    if (profile != null && _nutritionService.shouldRegenerate(_lastMealPlanGenerated)) {
      add(NutritionRegenerateMealPlan(profile: profile));
    }
  }

  Future<void> _onAddFood(NutritionAddFood event, Emitter<NutritionState> emit) async {
    if (state is! NutritionStateLoaded) return;
    final current = state as NutritionStateLoaded;
    final logs = current.logs.map((meal) {
      if (meal.mealType == event.mealType) {
        return MealLog(
          id: meal.id, userId: meal.userId,
          date: meal.date, mealType: meal.mealType,
          foods: [...meal.foods, FoodEntry(food: event.food, grams: event.grams)],
        );
      }
      return meal;
    }).toList();
    emit(current.copyWith(logs: logs));
  }

  void _onRemoveFood(NutritionRemoveFood event, Emitter<NutritionState> emit) {
    if (state is! NutritionStateLoaded) return;
    final current = state as NutritionStateLoaded;
    final logs = current.logs.map((meal) {
      if (meal.mealType == event.mealType) {
        return MealLog(
          id: meal.id, userId: meal.userId,
          date: meal.date, mealType: meal.mealType,
          foods: meal.foods.where((f) => f.food.id != event.foodId).toList(),
        );
      }
      return meal;
    }).toList();
    emit(current.copyWith(logs: logs));
  }

  /// Regenerate meal plan via DeepSeek AI and update state.
  Future<void> _onRegenerateMealPlan(
    NutritionRegenerateMealPlan event,
    Emitter<NutritionState> emit,
  ) async {
    if (state is! NutritionStateLoaded) return;
    final current = state as NutritionStateLoaded;

    if (event.profile == null) return;

    try {
      final mealPlan = await _nutritionService.generateMealPlan(event.profile!);
      _lastMealPlanGenerated = DateTime.now();
      emit(current.copyWith(mealPlanJson: mealPlan, clearMealPlanError: true));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[NutritionBloc] generateMealPlan failed: $e\n$st');
      emit(current.copyWith(mealPlanError: 'Не удалось обновить план питания. Попробуйте снова.'));
    }
  }
}