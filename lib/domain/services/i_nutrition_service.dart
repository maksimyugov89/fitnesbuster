import 'package:fitnesbuster/domain/entities/entities.dart';

class Macros {
  final int protein;
  final int carbs;
  final int fat;
  final int totalCalories;

  const Macros({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.totalCalories,
  });
}

abstract interface class INutritionService {
  bool shouldRegenerate(DateTime? lastGenerated);
  Future<String> generateMealPlan(UserProfile profile, {int stepsToday = 0});
  Macros calculateMacros(UserProfile profile);
}
