import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/services/i_nutrition_service.dart';

class NutritionService implements INutritionService {
  final IDeepSeekService _ai;

  NutritionService({required IDeepSeekService ai}) : _ai = ai;

  @override
  bool shouldRegenerate(DateTime? lastGenerated) {
    if (lastGenerated == null) return true;
    return DateTime.now().difference(lastGenerated).inDays >= 7;
  }

  @override
  Future<String> generateMealPlan(UserProfile profile, {int stepsToday = 0}) =>
      _ai.generateMealPlan(profile, stepsToday: stepsToday);

  @override
  Macros calculateMacros(UserProfile profile) {
    final target = profile.dailyCalorieTarget.round();
    return Macros(
      totalCalories: target,
      protein: ((target * 0.30) / 4).round(),
      carbs: ((target * 0.40) / 4).round(),
      fat: ((target * 0.30) / 9).round(),
    );
  }
}
