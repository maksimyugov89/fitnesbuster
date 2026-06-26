class MealMacros {
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;

  const MealMacros({
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
  });

  factory MealMacros.fromJson(Map<String, dynamic> j) => MealMacros(
    protein: (j['protein'] as num?)?.toInt() ?? (j['protein_g'] as num?)?.toInt() ?? 0,
    carbs: (j['carbs'] as num?)?.toInt() ?? (j['carbs_g'] as num?)?.toInt() ?? 0,
    fat: (j['fat'] as num?)?.toInt() ?? (j['fat_g'] as num?)?.toInt() ?? 0,
    fiber: (j['fiber'] as num?)?.toInt() ?? (j['fiber_g'] as num?)?.toInt() ?? 0,
  );

  bool get isEmpty => protein == 0 && carbs == 0 && fat == 0;
}

class AiSupplement {
  final String name;
  final String dose;
  final String timing;
  final String purpose;

  const AiSupplement({
    required this.name,
    this.dose = '',
    this.timing = '',
    this.purpose = '',
  });

  factory AiSupplement.fromJson(Map<String, dynamic> j) => AiSupplement(
    name: j['name'] as String? ?? '',
    dose: j['dose'] as String? ?? j['dosage'] as String? ?? '',
    timing: j['timing'] as String? ?? j['when'] as String? ?? '',
    purpose: j['purpose'] as String? ?? j['benefit'] as String? ?? '',
  );
}

class DailyTargets {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int waterMl;

  const DailyTargets({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.waterMl = 2500,
  });

  factory DailyTargets.fromJson(Map<String, dynamic> j) => DailyTargets(
    calories: (j['calories'] as num?)?.toInt() ?? (j['total_calories'] as num?)?.toInt() ?? 0,
    protein: (j['protein'] as num?)?.toInt() ?? (j['protein_g'] as num?)?.toInt() ?? 0,
    carbs: (j['carbs'] as num?)?.toInt() ?? (j['carbs_g'] as num?)?.toInt() ?? 0,
    fat: (j['fat'] as num?)?.toInt() ?? (j['fat_g'] as num?)?.toInt() ?? 0,
    waterMl: (j['water_ml'] as num?)?.toInt() ?? 2500,
  );

  bool get isEmpty => calories == 0 && protein == 0 && carbs == 0 && fat == 0;
}

class AiMeal {
  final String type;
  final String time;
  final List<String> foods;
  final int calories;
  final MealMacros macros;

  const AiMeal({
    required this.type,
    this.time = '',
    this.foods = const [],
    this.calories = 0,
    this.macros = const MealMacros(),
  });

  factory AiMeal.fromJson(Map<String, dynamic> j) {
    final macroRaw = j['macros'] as Map<String, dynamic>? ?? j['macro_breakdown'] as Map<String, dynamic>?;
    return AiMeal(
      type: (j['type'] as String? ?? '').toLowerCase(),
      time: j['time'] as String? ?? '',
      foods: (j['foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      calories: (j['calories'] as num?)?.toInt() ?? (j['total_calories'] as num?)?.toInt() ?? 0,
      macros: macroRaw != null ? MealMacros.fromJson(macroRaw) : const MealMacros(),
    );
  }
}

class AiMealPlan {
  final List<AiMeal> meals;
  final DailyTargets dailyTargets;
  final List<AiSupplement> supplements;
  final List<String> recommendations;
  final int waterTargetMl;

  const AiMealPlan({
    required this.meals,
    this.dailyTargets = const DailyTargets(),
    this.supplements = const [],
    this.recommendations = const [],
    this.waterTargetMl = 2500,
  });

  int get totalCalories => meals.fold(0, (s, m) => s + m.calories);

  factory AiMealPlan.fromJson(Map<String, dynamic> data) {
    final mealsRaw = (data['meals'] as List<dynamic>? ?? [])
        .map((e) => AiMeal.fromJson(e as Map<String, dynamic>))
        .toList();

    final targetsRaw = data['daily_targets'] as Map<String, dynamic>?;
    final dailyTargets = targetsRaw != null
        ? DailyTargets.fromJson(targetsRaw)
        : const DailyTargets();

    final suppsRaw = data['supplements'] as List<dynamic>?;
    final supplements = suppsRaw
        ?.map((e) => AiSupplement.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    final recs = (data['recommendations'] as List<dynamic>? ?? data['daily_tips'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final water = (data['water_target_ml'] as num?)?.toInt() ?? 2500;

    return AiMealPlan(
      meals: mealsRaw,
      dailyTargets: dailyTargets,
      supplements: supplements,
      recommendations: recs,
      waterTargetMl: water,
    );
  }
}
