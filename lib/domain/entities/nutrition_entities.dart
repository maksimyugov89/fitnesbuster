enum MealType { breakfast, lunch, dinner, snack }

class NutritionPer100g {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  const NutritionPer100g({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
  });
}

class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final NutritionPer100g nutrition;
  final String? imageUrl;

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.nutrition,
    this.imageUrl,
  });

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

class FoodEntry {
  final FoodItem food;
  final double grams;

  const FoodEntry({required this.food, required this.grams});

  double get totalCalories => food.nutritionForGrams(grams).calories;
  double get totalProtein => food.nutritionForGrams(grams).protein;
  double get totalCarbs => food.nutritionForGrams(grams).carbs;
  double get totalFat => food.nutritionForGrams(grams).fat;
}

class MealLog {
  final String id;
  final String userId;
  final DateTime date;
  final MealType mealType;
  final List<FoodEntry> foods;

  const MealLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foods,
  });

  double get totalCalories => foods.fold(0, (sum, f) => sum + f.totalCalories);
  double get totalProtein => foods.fold(0, (sum, f) => sum + f.totalProtein);
  double get totalCarbs => foods.fold(0, (sum, f) => sum + f.totalCarbs);
  double get totalFat => foods.fold(0, (sum, f) => sum + f.totalFat);
}

class MealPlan {
  final MealType type;
  final String title;
  final List<MealPlanItem> items;
  final int targetCalories;

  const MealPlan({
    required this.type,
    required this.title,
    required this.items,
    required this.targetCalories,
  });
}

class MealPlanItem {
  final FoodItem food;
  final double grams;
  final String? note;

  const MealPlanItem({
    required this.food,
    required this.grams,
    this.note,
  });
}

class DailyNutritionPlan {
  final String id;
  final String userId;
  final DateTime date;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final List<MealPlan> meals;

  const DailyNutritionPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.meals,
  });
}
