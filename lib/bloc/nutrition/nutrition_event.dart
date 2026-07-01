part of 'nutrition_bloc.dart';

sealed class NutritionEvent extends Equatable {
  const NutritionEvent();
  @override
  List<Object?> get props => [];
}

class NutritionLoadRequested extends NutritionEvent {
  final String userId;
  final DateTime? date;
  final UserProfile? profile;
  const NutritionLoadRequested({required this.userId, this.date, this.profile});
  @override
  List<Object?> get props => [userId, date ?? '', profile ?? ''];
}

class NutritionAddFood extends NutritionEvent {
  final MealType mealType;
  final FoodItem food;
  final double grams;
  const NutritionAddFood({
    required this.mealType,
    required this.food,
    required this.grams,
  });
  @override
  List<Object?> get props => [mealType, food, grams];
}

class NutritionRemoveFood extends NutritionEvent {
  final MealType mealType;
  final String foodId;
  const NutritionRemoveFood({required this.mealType, required this.foodId});
  @override
  List<Object?> get props => [mealType, foodId];
}

class NutritionRegenerateMealPlan extends NutritionEvent {
  final UserProfile? profile;
  const NutritionRegenerateMealPlan({this.profile});
  @override
  List<Object?> get props => [profile ?? ''];
}
