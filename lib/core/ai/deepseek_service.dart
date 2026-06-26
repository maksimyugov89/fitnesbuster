// cspell:disable
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fitnesbuster/core/ai/ai_config.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';

class DeepSeekService implements IDeepSeekService {
  DeepSeekService({
    AiConfig? config,
  });

  /// Strips markdown code fences from AI JSON responses: ```json ... ``` → raw JSON.
  /// Handles both complete fences and orphaned opening fences (truncated responses).
  String _extractJson(String response) {
    final trimmed = response.trim();
    // Strip markdown code fences
    final full = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(trimmed);
    String body;
    if (full != null) {
      body = full.group(1)!.trim();
    } else {
      final open = RegExp(r'^```(?:json)?\s*').firstMatch(trimmed);
      if (open != null) {
        body = trimmed.substring(open.end).trim();
      } else {
        body = trimmed;
      }
    }
    // Trim any trailing text after the last JSON brace/bracket
    final objEnd = body.lastIndexOf('}');
    final arrEnd = body.lastIndexOf(']');
    final lastJsonChar = objEnd > arrEnd ? objEnd : arrEnd;
    if (lastJsonChar >= 0 && lastJsonChar < body.length - 1) {
      body = body.substring(0, lastJsonChar + 1);
    }
    // Validate that the extracted string is parseable JSON
    try {
      jsonDecode(body);
    } catch (_) {
      // Return raw body — caller's _validateX method will throw with proper message
    }
    return body;
  }

  /// Validates workout plan JSON structure and normalizes new rich format for current UI.
  /// Ensures `plan` list exists, each day has `focus` (compat alias for `name`),
  /// and each day has an `exercises` list. Logs + throws on malformed input.
  String _validateWorkoutJson(String raw) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[DeepSeek] Malformed workout JSON: $raw');
      throw AiException('AI вернул некорректный JSON плана тренировок. Попробуйте ещё раз.');
    }

    final plan = data['plan'];
    if (plan == null || plan is! List || plan.isEmpty) {
      if (kDebugMode) debugPrint('[DeepSeek] Missing or empty "plan" in workout JSON: $raw');
      throw AiException('AI не вернул план тренировок. Попробуйте ещё раз.');
    }

    // Normalise each day: bridge new "name" field → legacy "focus" expected by current UI
    for (final item in plan) {
      if (item is! Map<String, dynamic>) continue;
      item['focus'] ??= item['name'] ?? '';
      if (item['exercises'] is! List) item['exercises'] = <dynamic>[];
    }

    return jsonEncode(data);
  }

  /// Validates meal plan JSON structure and normalizes new rich format for current UI.
  /// Ensures `meals` list exists. Bridges field renames:
  ///   total_calories → calories, daily_tips → recommendations, daily_targets.water_ml → water_target_ml.
  /// Flattens rich `foods` objects → plain strings so the current list widget doesn't crash.
  String _validateMealJson(String raw) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) debugPrint('[DeepSeek] Malformed meal JSON: $raw');
      throw AiException('AI вернул некорректный JSON плана питания. Попробуйте ещё раз.');
    }

    final meals = data['meals'];
    if (meals == null || meals is! List || meals.isEmpty) {
      if (kDebugMode) debugPrint('[DeepSeek] Missing or empty "meals" in meal JSON: $raw');
      throw AiException('AI не вернул план питания. Попробуйте ещё раз.');
    }

    for (final item in meals) {
      if (item is! Map<String, dynamic>) continue;

      // calories compat: new format uses total_calories
      item['calories'] ??= item['total_calories'] ?? 0;

      // foods compat: new format uses list of objects → flatten to "Name (Xг)"
      final foods = item['foods'];
      if (foods is List) {
        item['foods'] = foods.map((f) {
          if (f is String) return f;
          if (f is Map<String, dynamic>) {
            final name = f['name'] as String? ?? '';
            final grams = f['grams'];
            final fn = f['function'] as String?;
            final label = grams != null ? '$name ($gramsг)' : name;
            return fn != null ? '$label — $fn' : label;
          }
          return f.toString();
        }).toList();
      }

      // alternatives: pass through as List<String> — used by nutrition screen UI
      final alts = item['alternatives'];
      if (alts is List) {
        item['alternatives'] = alts.map((a) => a.toString()).toList();
      }
    }

    // recommendations compat: new format uses daily_tips
    data['recommendations'] ??= data['daily_tips'] ?? <dynamic>[];

    // water_target_ml compat: new format puts it inside daily_targets
    if (data['water_target_ml'] == null) {
      final targets = data['daily_targets'] as Map<String, dynamic>?;
      data['water_target_ml'] = targets?['water_ml'] ?? 2500;
    }

    return jsonEncode(data);
  }

  /// Generates a personalized weekly workout plan.
  /// [weekNumber] drives periodization phase (1-4 adaptation, 5-8 progress, 9-12 intensification).
  /// [recentHealth] injects sleep/HR data so the AI can adjust load.
  /// [previousPlanFeedback] lets user corrections carry over to the next week.
  @override
  Future<String> generateWorkoutPlan(
    UserProfile profile, {
    HealthData? recentHealth,
    int weekNumber = 1,
    String? previousPlanFeedback,
  }) async {
    final volumeBlock = _weeklyVolumeBlock(profile.intensity, weekNumber);
    final progressionBlock = _progressionBlock(profile.intensity);
    final recoveryBlock = _recoveryBlock(recentHealth);
    final targetBlock = _targetBlock(profile);
    final locationBlock = _locationBlock(profile.workoutLocation);
    final runningBlock = _runningBlock(profile.runningPreference);
    final healthBlock = _healthBlock(profile.medicalRestrictions, profile.exerciseRestrictions);

    final prompt = '''
Ты — сертифицированный персональный тренер (NSCA-CPT) и специалист по силовой подготовке.
Составь тренировочную программу на неделю №$weekNumber.

═══ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ═══
Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'}
Возраст: ${profile.age} лет | Вес: ${profile.weight} кг | Рост: ${profile.height} см
ИМТ: ${profile.bmi.toStringAsFixed(1)} | Уровень активности: ${profile.activityLevel.label}

═══ ЦЕЛЬ И ВРЕМЕННЫЕ РАМКИ ═══
$targetBlock

═══ ТРЕНИРОВОЧНЫЕ ПАРАМЕТРЫ ═══
Интенсивность: ${_intensityLabel(profile.intensity)}
$volumeBlock
$progressionBlock

${recoveryBlock.isNotEmpty ? '═══ ДАННЫЕ О ВОССТАНОВЛЕНИИ ═══\n$recoveryBlock\n' : ''}${locationBlock.isNotEmpty ? '═══ МЕСТО ТРЕНИРОВКИ И ОБОРУДОВАНИЕ ═══\n$locationBlock\n' : ''}${runningBlock.isNotEmpty ? '═══ КАРДИО-ПРОТОКОЛ ═══\n$runningBlock\n' : ''}${healthBlock.isNotEmpty ? '═══ МЕДИЦИНСКИЕ ОГРАНИЧЕНИЯ (СТРОГО СОБЛЮДАТЬ) ═══\n$healthBlock\n' : ''}${previousPlanFeedback != null ? '═══ ОБРАТНАЯ СВЯЗЬ ОТ ПОЛЬЗОВАТЕЛЯ ═══\n$previousPlanFeedback\n' : ''}
═══ ТРЕБОВАНИЯ К ПРОГРАММЕ ═══
1. Применяй принцип прогрессивной перегрузки — укажи конкретные диапазоны веса и % от 1ПМ где возможно
2. Обеспечь баланс объёма: каждая мышечная группа получает 10-20 рабочих подходов в неделю
3. Включи разминку (5-7 мин) и заминку (5 мин) для каждой тренировки
4. Для многосуставных упражнений укажи технические акценты (1-2 ключевых момента техники)
5. RPE (Rate of Perceived Exertion) для каждого упражнения по шкале 1-10
6. Чередуй мышечные группы для оптимального восстановления (минимум 48ч между тренировками одной группы)
7. Указывай темп выполнения там, где это критично

Ответь СТРОГО в формате JSON без markdown-обёртки:
{
  "week_number": $weekNumber,
  "phase": "Адаптация/Прогресс/Интенсификация/Пик",
  "weekly_volume_sets": 0,
  "plan": [
    {
      "day": 1,
      "name": "Грудь + Трицепс — Гипертрофия",
      "type": "strength",
      "duration_minutes": 60,
      "warmup": ["Упражнение 1 — 5 мин"],
      "exercises": [
        {
          "name": "Жим штанги лёжа",
          "muscle_primary": "грудь",
          "muscle_secondary": ["передние дельты", "трицепс"],
          "sets": 4,
          "reps": "6-8",
          "weight_guideline": "75-80% от 1ПМ",
          "rest_seconds": 120,
          "rpe": 8,
          "tempo": "2-0-1-1",
          "technique_cue": "Лопатки сведены и прижаты к скамье, локти под углом 45°",
          "progression": "Добавляй 2.5 кг при выполнении 8 повт. в 4 подходах"
        }
      ],
      "cooldown": ["Растяжка груди у стены — 30 сек × 2"],
      "cardio_minutes": 0,
      "estimated_calories_burned": 350,
      "notes": "Фокус на контролируемом негативном движении"
    }
  ],
  "weekly_summary": {
    "total_sessions": 4,
    "rest_days": [3, 6, 7],
    "muscle_groups_frequency": {"грудь": 1, "спина": 2, "ноги": 1},
    "estimated_weekly_calories": 1200
  },
  "recommendations": ["Совет с числами 1", "Совет 2", "Предупреждение о восстановлении"],
  "next_week_preview": "Что изменится на следующей неделе"
}
''';

    return _validateWorkoutJson(_extractJson(await _sendMessage(prompt)));
  }

  /// Generates a detailed daily nutrition plan with per-meal macros and timing.
  /// [stepsToday] from Health Connect adjusts total calorie budget.
  /// [recentHealth] provides additional context (sleep, HR) for load adjustment.
  /// [city] — user's city/town for regional product availability analysis.
  @override
  Future<String> generateMealPlan(
    UserProfile profile, {
    int stepsToday = 0,
    HealthData? recentHealth,
    List<String>? dislikedFoods,
    String? cuisinePreference,
    String? city,
  }) async {

    final macroBlock = _detailedMacroBlock(profile);
    final timingBlock = _mealTimingBlock();
    final activityBlock = _activityBlock(profile, stepsToday);
    final now = DateTime.now();
    final weekOfYear = (now.difference(DateTime(now.year)).inDays ~/ 7) + 1;
    final varietyBlock = _weekVarietyBlock(weekOfYear);
    final cityBlock = _cityFoodBlock(city ?? profile.city);
    final nutritionRestrictionBlock = _nutritionRestrictionBlock(profile.medicalRestrictions);

    final prompt = '''
Ты — клинический диетолог со специализацией в спортивном питании (ISSN-SNS).
Составь персонализированный план питания на день.

═══ БИОМЕТРИЧЕСКИЕ ДАННЫЕ ═══
Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'} | Возраст: ${profile.age} лет
Вес: ${profile.weight} кг | Рост: ${profile.height} см | ИМТ: ${profile.bmi.toStringAsFixed(1)}
BMR (Mifflin-St Jeor): ${profile.bmr.toStringAsFixed(0)} ккал/сут
TDEE (с учётом активности): ${profile.tdee.toStringAsFixed(0)} ккал/сут
Целевой калораж: ${profile.dailyCalorieTarget.toStringAsFixed(0)} ккал/сут

═══ ЦЕЛЬ И МАКРОНУТРИЕНТЫ ═══
Цель: ${_fitnessGoalLabel(profile.goal)}
$macroBlock

═══ ТАЙМИНГ ПИТАНИЯ ═══
$timingBlock

$activityBlock

═══ РАЗНООБРАЗИЕ РАЦИОНА (НЕДЕЛЯ $weekOfYear) ═══
$varietyBlock
ВАЖНО: составь УНИКАЛЬНЫЙ план с блюдами, которые не повторяются из недели в неделю. Чередуй крупы, источники белка и овощи ежедневно.

${cityBlock.isNotEmpty ? '═══ РЕГИОН И ДОСТУПНОСТЬ ПРОДУКТОВ ═══\n$cityBlock\n' : ''}${nutritionRestrictionBlock.isNotEmpty ? '═══ ПРОТИВОПОКАЗАНИЯ В ПИТАНИИ (СТРОГО СОБЛЮДАТЬ!) ═══\n$nutritionRestrictionBlock\n' : ''}${dislikedFoods != null && dislikedFoods.isNotEmpty ? '═══ НЕ ЛЮБИТ / НЕ ЕСТ ═══\n${dislikedFoods.join(', ')}\n' : ''}${cuisinePreference != null ? '═══ ПРЕДПОЧТИТЕЛЬНАЯ КУХНЯ ═══\n$cuisinePreference\n' : ''}
═══ ТРЕБОВАНИЯ К ПЛАНУ ═══
1. Каждый приём пищи — минимум 25-30г белка (для оптимального мышечного протеинового синтеза)
2. Укажи КОНКРЕТНЫЕ продукты с граммовкой, доступные в регионе пользователя
3. Учти тайминг: предтренировочный приём за 1.5-2ч, послетренировочный в течение 30-60 мин
4. До тренировки — сложные углеводы; сразу после — быстрые углеводы + белок
5. Клетчатка: 25-35г/день
6. Для каждого продукта укажи функцию (например: "источник лейцина", "медленный углевод")
7. ВСЕ названия продуктов, блюд, добавок и описания выводи СТРОГО на русском языке
8. ОБЯЗАТЕЛЬНО: для каждого приёма пищи укажи 2-3 альтернативы в поле "alternatives" — чем можно заменить основные продукты при их отсутствии в продаже
9. Добавь в ответ поле "basket_estimate" с оценкой НЕДЕЛЬНОЙ стоимости продуктов из плана: min_rub (нижняя граница), max_rub (верхняя граница), note (краткая заметка об оценке с учётом города пользователя). Умножь дневную стоимость на 7 для недельного расчёта.

Ответь СТРОГО в JSON без markdown:
{
  "daily_targets": {
    "calories": ${profile.dailyCalorieTarget.toStringAsFixed(0)},
    "protein_g": 0,
    "carbs_g": 0,
    "fat_g": 0,
    "fiber_g": 0,
    "water_ml": 0
  },
  "meals": [
    {
      "type": "breakfast",
      "name": "Название завтрака",
      "time": "07:30",
      "pre_workout": false,
      "post_workout": false,
      "total_calories": 0,
      "macros": {"protein": 0, "carbs": 0, "fat": 0},
      "foods": [
        {
          "name": "Овсянка (сухая)",
          "grams": 80,
          "calories": 290,
          "protein_g": 10,
          "carbs_g": 54,
          "fat_g": 5,
          "function": "медленный углевод, источник бета-глюкана"
        }
      ],
      "alternatives": [
        "Вместо овсянки → гречка (80г) или рис (70г)",
        "Вместо куриной грудки → индейка (150г) или консервированный тунец (130г)"
      ],
      "preparation": "Краткий способ приготовления",
      "timing_note": "Почему этот приём в это время"
    }
  ],
  "supplements": [
    {"name": "Протеин", "dose": "30г", "timing": "сразу после тренировки", "reason": "быстрое закрытие белкового окна"}
  ],
  "basket_estimate": {
    "min_rub": 1500,
    "max_rub": 2500,
    "note": "Оценка стоимости с учётом региона: Курган (средний город)"
  },
  "daily_tips": ["Нутриционный совет с научным обоснованием"],
  "meal_prep_hint": "Что можно приготовить заранее для экономии времени"
}
''';

    return _validateMealJson(_extractJson(await _sendMessage(prompt)));
  }

  /// Refines workout plan using real test-week performance data.
  /// Calibrates weights and volume to the user's proven capability.
  @override
  Future<String> refineWorkoutPlan(UserProfile profile, List<TestExerciseResult> exercises) async {

    final exerciseLines = exercises.map((e) {
      final w = e.comfortableWeightKg > 0 ? '${e.comfortableWeightKg} кг' : 'без веса';
      return '- ${e.exerciseName}: $w, ${e.comfortableSets} подх. × ${e.comfortableReps} повт'
          '${e.notes != null && e.notes!.isNotEmpty ? ' (заметка: ${e.notes})' : ''}';
    }).join('\n');

    final volumeBlock = _weeklyVolumeBlock(profile.intensity, 1);
    final progressionBlock = _progressionBlock(profile.intensity);
    final locationBlock = _locationBlock(profile.workoutLocation);
    final runningBlock = _runningBlock(profile.runningPreference);
    final healthBlock = _healthBlock(profile.medicalRestrictions, profile.exerciseRestrictions);
    final targetBlock = _targetBlock(profile);

    final prompt = '''
Ты — сертифицированный персональный тренер (NSCA-CPT). Пользователь завершил тестовую неделю.
Составь скорректированную программу тренировок на 7 дней на основе РЕАЛЬНЫХ показателей.

═══ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ═══
Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'}
Возраст: ${profile.age} лет | Вес: ${profile.weight} кг | Рост: ${profile.height} см
Интенсивность: ${_intensityLabel(profile.intensity)}

═══ ЦЕЛЬ ═══
$targetBlock

═══ РЕЗУЛЬТАТЫ ТЕСТОВОЙ НЕДЕЛИ (РЕАЛЬНЫЕ ПОКАЗАТЕЛИ) ═══
$exerciseLines

Используй эти веса как стартовую базу. НЕ назначай упражнения с весами, которые пользователь не тестировал.

═══ ПАРАМЕТРЫ ПРОГРАММЫ ═══
$volumeBlock
$progressionBlock

${locationBlock.isNotEmpty ? '═══ МЕСТО ТРЕНИРОВКИ ═══\n$locationBlock\n' : ''}${runningBlock.isNotEmpty ? '═══ КАРДИО-ПРОТОКОЛ ═══\n$runningBlock\n' : ''}${healthBlock.isNotEmpty ? '═══ МЕДИЦИНСКИЕ ОГРАНИЧЕНИЯ (СТРОГО СОБЛЮДАТЬ) ═══\n$healthBlock\n' : ''}
Ответь СТРОГО в формате JSON без markdown-обёртки:
{
  "week_number": 1,
  "phase": "Адаптация",
  "weekly_volume_sets": 0,
  "plan": [
    {
      "day": 1,
      "name": "Название тренировки",
      "type": "strength",
      "duration_minutes": 60,
      "warmup": ["Упражнение разминки"],
      "exercises": [
        {
          "name": "Упражнение",
          "muscle_primary": "группа мышц",
          "muscle_secondary": [],
          "sets": 3,
          "reps": "8-10",
          "weight_guideline": "конкретный вес из теста + 0-5%",
          "rest_seconds": 90,
          "rpe": 7,
          "tempo": "2-0-1-0",
          "technique_cue": "Ключевой момент техники",
          "progression": "Правило добавления веса"
        }
      ],
      "cooldown": ["Упражнение заминки"],
      "cardio_minutes": 0,
      "estimated_calories_burned": 0,
      "notes": "Заметки к тренировке"
    }
  ],
  "weekly_summary": {
    "total_sessions": 0,
    "rest_days": [],
    "muscle_groups_frequency": {},
    "estimated_weekly_calories": 0
  },
  "recommendations": ["Совет 1", "Совет 2"],
  "next_week_preview": "Что изменится на следующей неделе"
}
''';

    return _validateWorkoutJson(_extractJson(await _sendMessage(prompt)));
  }

  /// Analyzes body measurement progress and generates actionable recommendations.
  @override
  Future<String> analyzeProgress({
    required UserProfile profile,
    required Map<String, double?> latest,
    Map<String, double?>? previous,
    bool hasPhotos = false,
  }) async {

    final buf = StringBuffer();
    buf.writeln('Текущие замеры тела:');
    if (latest['chest'] != null) buf.writeln('- Грудь: ${latest['chest']} см');
    if (latest['waist'] != null) buf.writeln('- Талия: ${latest['waist']} см');
    if (latest['hips'] != null) buf.writeln('- Бёдра: ${latest['hips']} см');
    if (latest['bodyFat'] != null) buf.writeln('- Жир тела: ${latest['bodyFat']}%');

    String changesBlock = '';
    if (previous != null) {
      final ch = StringBuffer('Изменения с предыдущего замера:\n');
      bool any = false;
      void diff(String key, String label) {
        if (latest[key] != null && previous[key] != null) {
          final d = latest[key]! - previous[key]!;
          ch.writeln('- $label: ${d >= 0 ? '+' : ''}${d.toStringAsFixed(1)}');
          any = true;
        }
      }
      diff('chest', 'Грудь, см');
      diff('waist', 'Талия, см');
      diff('hips', 'Бёдра, см');
      diff('bodyFat', 'Жир тела, %');
      if (any) changesBlock = ch.toString();
    }

    final prompt = '''
Ты — AI-тренер FitnesBuster. Проанализируй прогресс пользователя на основе замеров тела.

Данные пользователя:
- Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'}
- Вес: ${profile.weight} кг | Рост: ${profile.height} см
- Цель: ${_fitnessGoalLabel(profile.goal)} | Интенсивность: ${_intensityLabel(profile.intensity)}

${buf.toString()}${changesBlock.isNotEmpty ? '\n$changesBlock' : ''}${hasPhotos ? '\nПользователь добавил фото прогресса для наглядного сравнения.' : ''}

Дай ответ в формате:
1. **Оценка прогресса** (2-3 предложения — честно и мотивирующе, используй конкретные цифры)
2. **Корректировка тренировок** (2-3 конкретных совета с числами)
3. **Корректировка питания** (2-3 конкретных совета с числами)

Отвечай на русском языке. Будь конкретным, ссылайся на данные из замеров.
''';

    return _sendMessage(prompt);
  }

  /// Generates a weekly AI debrief analysing workouts, nutrition, hydration,
  /// and personal records. Returns extracted JSON string for screen-side parsing.
  @override
  Future<String> generateWeeklyDebrief({
    required UserProfile profile,
    required int workoutsDone,
    required List<int> dailyWorkoutKcal,
    required List<int> dailyWaterMl,
    required List<int> dailyEatenCal,
    required int dailyCalTarget,
    required int dailyWaterTarget,
    required List<String> weekPrNames,
  }) async {

    final prompt = '''
Ты — персональный AI-тренер FitnesBuster. Проанализируй прошедшую неделю пользователя и дай объективный дебриф.

═══ ПРОФИЛЬ ═══
Цель: ${_fitnessGoalLabel(profile.goal)} | Интенсивность: ${_intensityLabel(profile.intensity)}
Вес: ${profile.weight} кг | Целевой калораж: $dailyCalTarget ккал/день | Вода: $dailyWaterTarget мл/день

═══ ТРЕНИРОВКИ (Пн–Вс) ═══
Выполнено: $workoutsDone из 7 дней
Ккал по дням (Пн..Вс): ${dailyWorkoutKcal.join(', ')}
Итого ккал за неделю: ${dailyWorkoutKcal.fold(0, (a, b) => a + b)}
${weekPrNames.isNotEmpty ? 'Личные рекорды: ${weekPrNames.join(", ")}' : 'Личных рекордов не установлено'}

═══ ПИТАНИЕ (Пн–Вс) ═══
Съедено ккал по дням: ${dailyEatenCal.join(', ')}
Среднее: ${dailyEatenCal.fold(0, (a, b) => a + b) ~/ 7} ккал/день (цель: $dailyCalTarget)
Дней в норме: ${dailyEatenCal.where((c) => c > 0 && (c - dailyCalTarget).abs() < dailyCalTarget * 0.15).length}

═══ ГИДРАТАЦИЯ (Пн–Вс) ═══
Вода мл по дням: ${dailyWaterMl.join(', ')}
Среднее: ${dailyWaterMl.fold(0, (a, b) => a + b) ~/ 7} мл/день (цель: $dailyWaterTarget)

Ответь СТРОГО в JSON без markdown-обёртки:
{
  "overall_score": 7,
  "workout_adherence": ${(workoutsDone / 7 * 100).round()},
  "workout_summary": "...",
  "nutrition_summary": "...",
  "highlights": ["Достижение 1", "Достижение 2"],
  "improvements": ["Область роста 1", "Область роста 2"],
  "next_week_focus": "...",
  "recovery_tips": ["Совет 1"]
}
''';

    return _extractJson(await _sendMessage(prompt));
  }

  /// Multi-turn chat: sends the full conversation history to the API.
  /// [history] — previous messages in the conversation (before the new question).
  /// [newQuestion] — the user's latest message text.
  /// Sends max 20 messages from history to stay within token limits.
  @override
  Future<String> askWithHistory(
    List<ChatMessage> history,
    String newQuestion, {
    UserProfile? profile,
  }) async {

    final systemContent = profile != null
        ? 'Ты — персональный фитнес-эксперт и нутрициолог FitnesBuster с 15-летним опытом.\n'
            'Ты сертифицирован NSCA, ISSN, обладаешь знаниями в спортивной физиологии и диетологии.\n'
            'Отвечай на русском языке, будь конкретным, используй цифры и факты.\n\n'
            '━━━ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ━━━\n'
            'Пол: ${profile.gender == Gender.male ? "Мужской" : "Женский"} | Возраст: ${profile.age} лет\n'
            'Вес: ${profile.weight} кг | Рост: ${profile.height} см | ИМТ: ${profile.bmi.toStringAsFixed(1)}\n'
            'Цель: ${_fitnessGoalLabel(profile.goal)} | Интенсивность: ${_intensityLabel(profile.intensity)}\n'
            'Активность: ${profile.activityLevel.label}\n'
            'Калораж: ${profile.dailyCalorieTarget.toStringAsFixed(0)} ккал/день'
            '${profile.medicalRestrictions.isNotEmpty ? "\nОграничения: ${profile.medicalRestrictions.join(", ")}" : ""}'
        : 'Ты — персональный фитнес-эксперт и нутрициолог FitnesBuster с 15-летним опытом.\n'
            'Ты сертифицирован NSCA, ISSN, обладаешь знаниями в спортивной физиологии и диетологии.\n'
            'Отвечай на русском языке, будь конкретным, используй цифры и факты.';

    final recentHistory =
        history.length > 20 ? history.sublist(history.length - 20) : history;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      ...recentHistory.map((m) => {'role': m.role, 'content': m.content}),
      {'role': 'user', 'content': newQuestion},
    ];

    return _sendMessagesList(messages);
  }

  /// Answers a fitness/nutrition question with full user profile context.
  /// [recentTopics] — список тем из текущей сессии чата для поддержания связности.
  @override
  Future<String> askQuestion(
    String question, {
    UserProfile? profile,
    List<String>? recentTopics,
  }) async {

    final context = profile != null ? '''
━━━ КОНТЕКСТ ПОЛЬЗОВАТЕЛЯ ━━━
Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'} | Возраст: ${profile.age} лет
Вес: ${profile.weight} кг | Рост: ${profile.height} см | ИМТ: ${profile.bmi.toStringAsFixed(1)}
Цель: ${_fitnessGoalLabel(profile.goal)} | Интенсивность: ${_intensityLabel(profile.intensity)}
Активность: ${profile.activityLevel.label}
Калораж: ${profile.dailyCalorieTarget.toStringAsFixed(0)} ккал/день (TDEE: ${profile.tdee.toStringAsFixed(0)})
${profile.medicalRestrictions.isNotEmpty ? 'Ограничения: ${profile.medicalRestrictions.join(", ")}' : ''}
''' : '';

    final topicsContext = recentTopics != null && recentTopics.isNotEmpty
        ? '\n━━━ ТЕМЫ ТЕКУЩЕЙ СЕССИИ ━━━\n${recentTopics.join(', ')}\n'
        : '';

    final prompt = '''
Ты — персональный фитнес-эксперт и нутрициолог FitnesBuster с 15-летним опытом.
Ты сертифицирован NSCA, ISSN, обладаешь знаниями в спортивной физиологии и диетологии.

$context$topicsContext
━━━ ВОПРОС ПОЛЬЗОВАТЕЛЯ ━━━
$question

━━━ ТРЕБОВАНИЯ К ОТВЕТУ ━━━
1. Отвечай КОНКРЕТНО — не общими фразами, а с точными числами, протоколами, временными рамками
2. Если вопрос о тренировках — укажи конкретные упражнения, подходы, повторения
3. Если вопрос о питании — укажи конкретные продукты, граммовку, тайминг
4. Если вопрос спорный в науке — честно укажи это и объясни что показывают исследования
5. Учитывай данные пользователя выше при ответе — персонализируй совет
6. Если вопрос требует консультации врача — прямо скажи об этом
7. Структурируй: Краткий ответ (1-2 предложения) → Детали → Практическое действие

Максимум 5-6 предложений или 3 пункта. Отвечай на русском языке.
''';

    return _sendMessage(prompt);
  }

  // ─── Внутренние блоки для генерации промтов ───────────────────────────────

  /// Generates a city-aware food availability block for the meal plan prompt.
  /// Instructs AI to use regionally available products and provide alternatives.
  String _cityFoodBlock(String? city) {
    if (city == null || city.trim().isEmpty) {
      return '''Населённый пункт пользователя не указан. Составляй план из универсально доступных продуктов:
- Мясо/птица: куриная грудка, куриные бёдра, говядина, свинина, яйца
- Рыба: консервированный тунец, консервированная сайра, замороженная минтай
- Молочное: творог, кефир, молоко, сыр
- Крупы: гречка, рис, овсянка, перловка, пшено
- Овощи: картофель, морковь, капуста, лук, свёкла, помидоры, огурцы
- Фрукты: яблоки, бананы, апельсины, груши
- Масла: подсолнечное, сливочное
НЕ используй: авокадо, киноа, тофу, лосось, форель, семга — эти продукты есть не везде.
ОБЯЗАТЕЛЬНО: для каждого приёма пищи укажи 2-3 альтернативы продуктов в поле "alternatives".''';
    }
    return '''Населённый пункт пользователя: $city

ВАЖНО — анализируй доступность продуктов в данном регионе:

1. КРУПНЫЕ ГОРОДА (Москва, Санкт-Петербург, Екатеринбург, Новосибирск, Казань, Нижний Новгород, Челябинск, Самара, Уфа, Ростов-на-Дону, Краснодар, Воронеж и города 500к+):
   → Полный ассортимент супермаркетов (Перекрёсток, Азбука Вкуса, Лента, Auchan). Допустимы: лосось, авокадо, брокколи, шпинат, киноа, хумус, греческий йогурт, нутовая мука, тофу, тёмный шоколад, протеиновые смеси.

2. СРЕДНИЕ ГОРОДА (100-500к жителей):
   → Федеральные сети (Магнит, Пятёрочка, Дикси, Лента). Используй: куриная грудка/бёдра, говядина, свинина, яйца, гречка, рис, овсянка, картофель, морковь, капуста, творог, кефир, молоко, сыр, консервированная рыба (тунец, сайра), яблоки, бананы, подсолнечное масло. Ограниченно: семга, брокколи, шпинат.

3. МАЛЫЕ ГОРОДА И ПОСЁЛКИ (менее 100к жителей, районные центры, сельская местность):
   → ТОЛЬКО самые распространённые продукты из сетей Магнит/Пятёрочка и местных рынков:
   Белки: куриные бёдра/грудка, яйца, говядина, свинина, консервы (тунец, сайра, горбуша)
   Молочное: молоко, кефир, творог (5-9%), сметана, сыр твёрдый
   Крупы: гречка, рис, овсянка геркулес, пшено, перловка, макароны
   Овощи: картофель, морковь, лук, капуста белокочанная, свёкла, чеснок, огурцы, помидоры (сезонно)
   Фрукты: яблоки, бананы, апельсины (доступны круглый год)
   Масло: подсолнечное рафинированное, сливочное
   НЕ ИСПОЛЬЗОВАТЬ: авокадо, брокколи, шпинат, лосось, форель, киноа, тофу, хумус, протеиновые порошки, ореховые пасты специальных сортов

Определи категорию населённого пункта "$city" и строго соблюдай ограничения доступности.
ОБЯЗАТЕЛЬНО: для каждого приёма пищи добавь поле "alternatives" с 2-3 заменами продуктов на случай их отсутствия в магазине.
Формат: "Вместо [продукт] → [альтернатива 1] ([граммовка]) или [альтернатива 2] ([граммовка])"''';
  }

  /// Generates a nutrition-specific restriction block (not workout-focused).
  /// Maps common dietary restrictions to exact food exclusions for the meal plan.
  String _nutritionRestrictionBlock(List<String> restrictions) {
    if (restrictions.isEmpty) return '';
    final buf = StringBuffer('Диетические противопоказания пользователя (АБСОЛЮТНЫЙ ЗАПРЕТ — нарушение опасно для здоровья):');
    for (final r in restrictions) {
      switch (r) {
        case 'Аллергия на орехи':
          buf.write('\n❌ Аллергия на орехи: ИСКЛЮЧИТЬ — грецкие орехи, миндаль, кешью, фундук, фисташки, арахис, арахисовое масло, миндальное молоко, любые ореховые пасты и смеси с орехами.');
          break;
        case 'Непереносимость лактозы':
          buf.write('\n❌ Непереносимость лактозы: ИСКЛЮЧИТЬ — молоко, мягкие сыры, сливки, сметану. МОЖНО: твёрдый сыр (лактозы мало), кефир (частично ферментирован), безлактозное молоко, растительные аналоги.');
          break;
        case 'Без глютена':
          buf.write('\n❌ Целиакия / без глютена: ИСКЛЮЧИТЬ — пшеницу, рожь, ячмень, полбу, манку, большинство видов хлеба и макарон. МОЖНО: гречка, рис, кукурузная крупа, пшено, картофель, специальные безглютеновые продукты.');
          break;
        case 'Вегетарианец':
          buf.write('\n❌ Вегетарианство: ИСКЛЮЧИТЬ — мясо (говядина, свинина, птица), рыбу, морепродукты. МОЖНО: яйца, молочные продукты, бобовые (чечевица, нут, фасоль), тофу, темпе, грибы.');
          break;
        case 'Веган':
          buf.write('\n❌ Веганство: ИСКЛЮЧИТЬ — мясо, рыбу, яйца, молочные продукты, мёд, желатин. Весь белок — только из растительных источников: бобовые, тофу, темпе, сейтан, орехи, семена.');
          break;
        case 'Без красного мяса':
          buf.write('\n❌ Без красного мяса: ИСКЛЮЧИТЬ — говядину, свинину, баранину, телятину. МОЖНО: курица, индейка, рыба, яйца, молочные продукты, бобовые.');
          break;
        case 'Диабетическая диета':
          buf.write('\n❌ Сахарный диабет: ИСКЛЮЧИТЬ — сахар, мёд, белый хлеб, выпечку, сладкие фрукты (виноград, бананы в большом кол-ве), соки, сладкие напитки. Приоритет: низкий ГИ — гречка, бурый рис, бобовые, овощи, нежирное мясо/рыба. НЕ превышать 50-60г углеводов за один приём.');
          break;
        case 'Низкое содержание соли':
          buf.write('\n❌ Ограничение соли: не более 2г натрия/день. ИСКЛЮЧИТЬ — готовые соусы, консервы с высоким содержанием соли, копчёности, колбасы. Готовить без добавления соли или с минимальным количеством.');
          break;
        case 'Кето':
          buf.write('\n❌ Кето-диета: углеводы не более 20-30г/день. ИСКЛЮЧИТЬ — крупы, хлеб, макароны, картофель, бананы, виноград, большинство фруктов, бобовые. ОСНОВА: мясо, рыба, яйца, сыр, масло, орехи, авокадо, листовые овощи.');
          break;
        default:
          buf.write('\n❌ $r: строго учти это ограничение при выборе всех продуктов и блюд.');
      }
    }
    return buf.toString();
  }

  String _weeklyVolumeBlock(IntensityLevel intensity, int weekNumber) {
    final sets = switch (intensity) {
      IntensityLevel.relaxed  => '10-12 рабочих подходов/мышечную группу/неделю',
      IntensityLevel.gradual  => '12-15 рабочих подходов/мышечную группу/неделю',
      IntensityLevel.balanced => '15-18 рабочих подходов/мышечную группу/неделю',
      IntensityLevel.intensive => '18-22 рабочих подхода/мышечную группу/неделю',
      IntensityLevel.hardcore => '22-30 рабочих подходов/мышечную группу/неделю',
    };
    final phase = weekNumber <= 4  ? 'Адаптация (сниженный объём, отработка техники)'
        : weekNumber <= 8  ? 'Прогресс (наращивание объёма)'
        : weekNumber <= 12 ? 'Интенсификация (максимальный объём)'
        : 'Пик (снижение объёма, максимальные веса)';
    return 'Целевой объём: $sets\nФаза мезоцикла: $phase (неделя $weekNumber из 12)';
  }

  String _progressionBlock(IntensityLevel intensity) {
    return switch (intensity) {
      IntensityLevel.relaxed || IntensityLevel.gradual =>
        'Схема прогрессии: линейная — добавляй вес только когда выполняешь ВСЕ подходы в верхней границе диапазона повторений. Шаг: 1.25-2.5 кг на изолирующих, 2.5-5 кг на базовых.',
      IntensityLevel.balanced =>
        'Схема прогрессии: двойная прогрессия — сначала доводи повторения до верхней границы диапазона, затем добавляй вес и начинай заново с нижней границы. Шаг: 2.5 кг на изолирующих, 5 кг на базовых.',
      IntensityLevel.intensive || IntensityLevel.hardcore =>
        'Схема прогрессии: волновая — Неделя А (тяжёлая, 3-5 повт, 85%+ 1ПМ) → Неделя Б (умеренная, 8-12 повт, 70-75% 1ПМ). Применяй AMRAP в последнем сете для мониторинга прогресса.',
    };
  }

  String _recoveryBlock(HealthData? health) {
    if (health == null) return '';
    final buf = StringBuffer();
    if (health.sleepMinutes != null) {
      final hours = (health.sleepMinutes! / 60).toStringAsFixed(1);
      buf.writeln('Сон: $hours ч — ${health.sleepMinutes! < 420 ? "НЕДОСТАТОЧНО — снизь интенсивность на 15%, избегай тяжёлых базовых упражнений" : "в норме"}');
    }
    if (health.heartRateResting != null) {
      buf.writeln('Пульс покоя: ${health.heartRateResting} уд/мин — ${health.heartRateResting! > 70 ? "повышен, возможно накопленная усталость — увеличь время разминки" : "в норме"}');
    }
    if (health.steps != null) {
      buf.writeln('Средняя активность: ${(health.steps! / 7).round()} шаг/день');
    }
    return buf.toString();
  }

  String _targetBlock(UserProfile profile) {
    final buf = StringBuffer();
    buf.writeln('Фитнес-цель: ${_fitnessGoalLabel(profile.goal)}');
    final diff = profile.targetWeight != null
        ? (profile.weight - profile.targetWeight!).abs()
        : null;
    if (profile.targetWeight != null) {
      final direction = profile.weight > profile.targetWeight! ? 'снизить' : 'набрать';
      buf.writeln('Целевой вес: ${profile.targetWeight!.toStringAsFixed(1)} кг (нужно $direction ${diff!.toStringAsFixed(1)} кг)');
    }
    if (profile.targetDate != null) {
      final weeks = profile.targetDate!.difference(DateTime.now()).inDays ~/ 7;
      if (weeks > 0) {
        final rateNote = diff != null
            ? ', темп: ${(diff / weeks).toStringAsFixed(2)} кг/нед${(diff / weeks) > 0.8 ? " ⚠️ возможно нереалистично" : ""}'
            : '';
        buf.writeln('Дедлайн: $weeks нед$rateNote');
      }
    }
    buf.writeln('Дневной калораж: ${profile.dailyCalorieTarget.toStringAsFixed(0)} ккал (TDEE = ${profile.tdee.toStringAsFixed(0)})');
    return buf.toString();
  }

  String _detailedMacroBlock(UserProfile profile) {
    final (proteinPct, carbsPct, fatPct) = switch (profile.goal) {
      FitnessGoal.loseWeight      => (0.35, 0.35, 0.30),
      FitnessGoal.gainWeight      => (0.30, 0.45, 0.25),
      FitnessGoal.maintain        => (0.30, 0.40, 0.30),
      FitnessGoal.beachBody       => (0.40, 0.30, 0.30),
      FitnessGoal.sportPerformance => (0.25, 0.55, 0.20),
    };
    final cal = profile.dailyCalorieTarget;
    final protein = (cal * proteinPct / 4).round();
    final carbs = (cal * carbsPct / 4).round();
    final fat = (cal * fatPct / 9).round();
    final proteinPerKg = (protein / profile.weight).toStringAsFixed(1);
    return 'Белок: $proteinг ($proteinPerKgг/кг) — цель ≥1.6г/кг для сохранения/роста мышц\n'
        'Углеводы: $carbsг — приоритет сложным (овсянка, гречка, батат, рис)\n'
        'Жиры: $fatг — приоритет ненасыщенным (авокадо, оливковое масло, орехи, лосось)\n'
        'Клетчатка: ≥25г/день';
  }

  String _mealTimingBlock() {
    return '''Оптимальное распределение приёмов пищи:
- Завтрак: 07:00-08:00 (запуск метаболизма, белок ≥30г)
- Предтренировочный: за 1.5-2ч до тренировки (углеводы + умеренный белок)
- Послетренировочный: в течение 30-60 мин после (белок ≥30г + быстрые углеводы)
- Ужин: за 2-3ч до сна (белок + овощи, минимум углеводов)
- Перекус перед сном (при необходимости): казеин / творог для МПС''';
  }

  // ─── Существующие блоки (не изменились) ──────────────────────────────────

  String _locationBlock(String? location) {
    switch (location) {
      case 'gym':
        return '''Место тренировки: ТРЕНАЖЁРНЫЙ ЗАЛ
Доступное оборудование: штанги, гантели, силовые тренажёры, кабельный кроссовер, скамьи для жима, стойки для приседаний, беговые дорожки, велотренажёры, эллипс.
ОБЯЗАТЕЛЬНО: составляй упражнения с использованием штанги, гантелей и тренажёров — это позволяет точно дозировать нагрузку и прогрессировать в весах.''';
      case 'outdoor':
        return '''Место тренировки: СТАДИОН / УЛИЧНАЯ ПЛОЩАДКА
Доступное оборудование: турники, брусья, параллельные брусья, шведская стенка, скамейки, открытое пространство для бега и спринтов.
ОБЯЗАТЕЛЬНО: используй упражнения с собственным весом (подтягивания, отжимания на брусьях, приседания с прыжком, берпи) и беговые дорожки стадиона. Никаких штанг и тренажёров — только то, что доступно на улице.''';
      case 'home':
        return '''Место тренировки: ДОМА
Доступное оборудование: только собственный вес тела, возможно резиновые эспандеры и лёгкие разборные гантели (не более 20 кг).
ОБЯЗАТЕЛЬНО: используй ИСКЛЮЧИТЕЛЬНО упражнения с весом тела (отжимания, приседания, выпады, планка, берпи, скалолаз) и эспандеры. Никаких штанг, силовых тренажёров или тяжёлого оборудования.''';
      default:
        return '';
    }
  }

  String _runningBlock(String? running) {
    switch (running) {
      case 'withRunning':
        return '''Беговые упражнения: ОБЯЗАТЕЛЬНО ВКЛЮЧИТЬ
Бег является ключевым элементом программы. Включи пробежки минимум 2–3 раза в неделю: равномерный бег, интервальный бег, спринты или фартлек. Кардио-блок в беговые дни — не менее 20–30 минут.''';
      case 'noRunning':
        return '''Беговые упражнения: ПОЛНОСТЬЮ ИСКЛЮЧИТЬ
СТРОГО ЗАПРЕЩЕНО: бег, джоггинг, спринты, любые упражнения с активным бегом. Кардио допустимо ТОЛЬКО в форматах без бега: велотренажёр, эллипс, прыжки со скакалкой. Если локация не позволяет кардио-оборудование — замени кардио на круговые тренировки с коротким отдыхом между подходами. Поле "cardio_minutes" должно быть 0 или минимальным (не более 5).''';
      default:
        return '';
    }
  }

  String _weekVarietyBlock(int weekOfYear) {
    final cycle = weekOfYear % 4;
    return switch (cycle) {
      0 => 'АКЦЕНТ ЭТОЙ НЕДЕЛИ — РЫБА И МОРЕПРОДУКТЫ: используй лосось, треску, тунец, скумбрию, минтай. Крупы: гречка и бурый рис. Добавь чечевицу или фасоль.',
      1 => 'АКЦЕНТ ЭТОЙ НЕДЕЛИ — РАЗНООБРАЗНОЕ МЯСО: говядина, индейка, кролик (или свинина). Крупы: перловка, пшено, булгур. Больше свежих овощей.',
      2 => 'АКЦЕНТ ЭТОЙ НЕДЕЛИ — ЯЙЦА И ТВОРОГ: яичница, омлет, запеканки, творог с фруктами. Крупы: овсянка, рис. Добавь больше зелени и клетчатки.',
      _ => 'АКЦЕНТ ЭТОЙ НЕДЕЛИ — ПТИЦА: куриная грудка, куриные бёдра, индейка. Крупы: гречка, рис. Добавь разнообразные овощи и бобовые.',
    };
  }

  String _activityBlock(UserProfile profile, int stepsToday) {
    final bmr = calcBmr(profile);
    final stepKcal = stepsToday > 0
        ? (stepsToday * 0.04 * (profile.weight / 70)).round()
        : 0;
    final totalBurned = bmr + stepKcal;

    final buf = StringBuffer();
    buf.writeln('Метаболизм и активность пользователя:');
    buf.writeln('- Базовый обмен веществ (BMR, Mifflin-St Jeor): $bmr ккал/сут');
    if (stepsToday > 0) {
      buf.writeln('- Шагов сегодня: $stepsToday (~$stepKcal ккал от ходьбы)');
      buf.writeln('- Итого сожжено сегодня: ~$totalBurned ккал (BMR + ходьба)');
      buf.writeln('→ При составлении рациона создай дефицит/профицит от реального расхода $totalBurned ккал.');
    } else {
      buf.writeln('- Данных о шагах нет. Ориентируйся на TDEE: ${profile.tdee.toStringAsFixed(0)} ккал.');
    }
    return buf.toString();
  }

  String _healthBlock(List<String> medical, List<String> exercise) {
    if (medical.isEmpty && exercise.isEmpty) return '';
    final buf = StringBuffer('Ограничения по здоровью (СТРОГО СОБЛЮДАТЬ — нарушение опасно для пользователя):');
    if (medical.isNotEmpty) {
      buf.write('\n- Медицинские ограничения: ${medical.join(', ')}');
      buf.write('\n  → Исключи все упражнения и нагрузки, противопоказанные при этих состояниях.');
    }
    if (exercise.isNotEmpty) {
      buf.write('\n- Запрещённые упражнения: ${exercise.join(', ')}');
      buf.write('\n  → Эти упражнения НЕЛЬЗЯ включать в программу ни в каком виде.');
    }
    return buf.toString();
  }

  String _fitnessGoalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.loseWeight: return 'Снижение веса';
      case FitnessGoal.gainWeight: return 'Набор массы';
      case FitnessGoal.maintain: return 'Поддержание формы';
      case FitnessGoal.beachBody: return 'К пляжному сезону';
      case FitnessGoal.sportPerformance: return 'Спортивные результаты';
    }
  }

  String _intensityLabel(IntensityLevel intensity) {
    switch (intensity) {
      case IntensityLevel.hardcore: return 'Хардкор';
      case IntensityLevel.intensive: return 'Интенсив';
      case IntensityLevel.balanced: return 'Баланс';
      case IntensityLevel.gradual: return 'Постепенный';
      case IntensityLevel.relaxed: return 'Лайт';
    }
  }

  /// Calculates BMR using Mifflin-St Jeor equation (used in activity block).
  static int calcBmr(UserProfile profile) {
    final base = (10 * profile.weight) + (6.25 * profile.height) - (5 * profile.age);
    return (profile.gender == Gender.male ? base + 5 : base - 161).round();
  }

  // ─── Сеть ────────────────────────────────────────────────────────────────

  static const _maxRetries = 3;

  Future<String> _sendMessage(String prompt) async {
    AiException? lastError;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await _sendOnce(prompt);
      } on AiException catch (e) {
        lastError = e;
        if (e.statusCode == 401 || e.statusCode == 429) rethrow;
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    throw lastError!;
  }

  Future<String> _sendOnce(String prompt) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('deepseekProxy');
    final result = await callable.call<Map<String, dynamic>>({
      'messages': [
        {'role': 'system', 'content': 'Ты — профессиональный персональный тренер и диетолог. Отвечай строго на русском языке.'},
        {'role': 'user', 'content': prompt},
      ],
      'maxTokens': 8192,
      'temperature': 0.7,
    });
    final content = result.data['content'] as String?;
    if (content == null || content.isEmpty) {
      throw AiException('Пустой ответ от AI. Попробуйте ещё раз.');
    }
    return content;
  }

  // ── Multi-turn chat network helpers ──────────────────────────────────────

  Future<String> _sendMessagesList(List<Map<String, String>> messages) async {
    AiException? lastError;
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await _sendOnceMessages(messages);
      } on AiException catch (e) {
        lastError = e;
        if (e.statusCode == 401 || e.statusCode == 429) rethrow;
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    throw lastError!;
  }

  Future<String> _sendOnceMessages(List<Map<String, String>> messages) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('deepseekProxy');
    final result = await callable.call<Map<String, dynamic>>({
      'messages': messages,
      'maxTokens': 2048,
      'temperature': 0.8,
    });
    final content = result.data['content'] as String?;
    if (content == null || content.isEmpty) {
      throw AiException('Пустой ответ от AI. Попробуйте ещё раз.');
    }
    return content;
  }

  @override
  void dispose() {
    // Cloud Functions proxy — no HTTP client to close
  }
}

class AiException implements Exception {
  final String message;
  final int? statusCode;
  const AiException(this.message, {this.statusCode});

  @override
  String toString() => 'AiException: $message';
}
