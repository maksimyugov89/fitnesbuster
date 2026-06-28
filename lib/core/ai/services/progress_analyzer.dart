import 'package:fitnesbuster/core/ai/base_client.dart';
import 'package:fitnesbuster/core/ai/validators/json_validator.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

class ProgressAnalyzer {
  final BaseClient _client;

  ProgressAnalyzer(this._client);

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

${_client.languageInstruction} Будь конкретным, ссылайся на данные из замеров.
''';

    return _client.sendMessage(prompt);
  }

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

    return extractJson(await _client.sendMessage(prompt));
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
}
