import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';

class NutritionService {
  final IDeepSeekService _ai;

  NutritionService({required IDeepSeekService ai}) : _ai = ai;

  bool shouldRegenerate(DateTime? lastGenerated) {
    if (lastGenerated == null) return true;
    return DateTime.now().difference(lastGenerated).inDays >= 7;
  }

  Future<String> generateMealPlan(UserProfile profile, {int stepsToday = 0}) =>
      _ai.generateMealPlan(profile, stepsToday: stepsToday);
}
