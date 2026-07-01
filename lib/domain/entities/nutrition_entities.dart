import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_entities.freezed.dart';
part 'nutrition_entities.g.dart';

enum MealType { breakfast, lunch, dinner, snack }

@freezed
class NutritionPer100g with _$NutritionPer100g {
  const factory NutritionPer100g({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) = _NutritionPer100g;

  factory NutritionPer100g.fromJson(Map<String, dynamic> json) =>
      _$NutritionPer100gFromJson(json);
}

@freezed
class FoodItem with _$FoodItem {
  const FoodItem._();

  const factory FoodItem({
    required String id,
    required String name,
    String? brand,
    String? barcode,
    required NutritionPer100g nutrition,
    String? imageUrl,
  }) = _FoodItem;

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);

  NutritionPer100g nutritionForGrams(double grams) {
    final factor = grams / 100;
    return NutritionPer100g(
      calories: nutrition.calories * factor,
      protein: nutrition.protein * factor,
      carbs: nutrition.carbs * factor,
      fat: nutrition.fat * factor,
      fiber: nutrition.fiber != null ? nutrition.fiber! * factor : null,
      sugar: nutrition.sugar != null ? nutrition.sugar! * factor : null,
    );
  }
}

@freezed
class FoodEntry with _$FoodEntry {
  const FoodEntry._();

  const factory FoodEntry({required FoodItem food, required double grams}) =
      _FoodEntry;

  factory FoodEntry.fromJson(Map<String, dynamic> json) =>
      _$FoodEntryFromJson(json);

  double get totalCalories => food.nutritionForGrams(grams).calories;
  double get totalProtein => food.nutritionForGrams(grams).protein;
  double get totalCarbs => food.nutritionForGrams(grams).carbs;
  double get totalFat => food.nutritionForGrams(grams).fat;
}

@freezed
class MealLog with _$MealLog {
  const MealLog._();

  const factory MealLog({
    required String id,
    required String userId,
    required DateTime date,
    required MealType mealType,
    required List<FoodEntry> foods,
  }) = _MealLog;

  factory MealLog.fromJson(Map<String, dynamic> json) =>
      _$MealLogFromJson(json);

  double get totalCalories => foods.fold(0, (sum, f) => sum + f.totalCalories);
  double get totalProtein => foods.fold(0, (sum, f) => sum + f.totalProtein);
  double get totalCarbs => foods.fold(0, (sum, f) => sum + f.totalCarbs);
  double get totalFat => foods.fold(0, (sum, f) => sum + f.totalFat);
}

@freezed
class MealPlan with _$MealPlan {
  const factory MealPlan({
    required MealType type,
    required String title,
    required List<MealPlanItem> items,
    required int targetCalories,
  }) = _MealPlan;

  factory MealPlan.fromJson(Map<String, dynamic> json) =>
      _$MealPlanFromJson(json);
}

@freezed
class MealPlanItem with _$MealPlanItem {
  const factory MealPlanItem({
    required FoodItem food,
    required double grams,
    String? note,
  }) = _MealPlanItem;

  factory MealPlanItem.fromJson(Map<String, dynamic> json) =>
      _$MealPlanItemFromJson(json);
}

@freezed
class DailyNutritionPlan with _$DailyNutritionPlan {
  const factory DailyNutritionPlan({
    required String id,
    required String userId,
    required DateTime date,
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    required List<MealPlan> meals,
  }) = _DailyNutritionPlan;

  factory DailyNutritionPlan.fromJson(Map<String, dynamic> json) =>
      _$DailyNutritionPlanFromJson(json);
}
