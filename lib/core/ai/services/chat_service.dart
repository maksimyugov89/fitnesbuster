import 'package:fitnesbuster/core/ai/base_client.dart';
import 'package:fitnesbuster/core/ai/validators/json_validator.dart';
import 'package:fitnesbuster/core/ai/exercise_catalog_prompt.dart';
import 'package:fitnesbuster/core/ai/knowledge/training_knowledge.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

class ChatService {
  final BaseClient _client;

  ChatService(this._client);

  Future<String> askWithHistory(
    List<ChatMessage> history,
    String newQuestion, {
    UserProfile? profile,
  }) async {
    final systemContent = profile != null
        ? 'Ты — персональный фитнес-эксперт и нутрициолог FitnesBuster с 15-летним опытом.\n'
              'Ты сертифицирован NSCA, ISSN, обладаешь знаниями в спортивной физиологии и диетологии.\n'
              '${_client.languageInstruction} Будь конкретным, используй цифры и факты.\n\n'
              '$trainingPrinciplesCore\n'
              '${methodologyEmphasisBlock(profile)}\n'
              '━━━ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ━━━\n'
              'Пол: ${profile.gender == Gender.male ? "Мужской" : "Женский"} | Возраст: ${profile.age} лет\n'
              'Вес: ${profile.weight} кг | Рост: ${profile.height} см | ИМТ: ${profile.bmi.toStringAsFixed(1)}\n'
              'Цель: ${_fitnessGoalLabel(profile.goal)} | Интенсивность: ${_intensityLabel(profile.intensity)}\n'
              'Активность: ${profile.activityLevel.label}\n'
              'Калораж: ${profile.dailyCalorieTarget.toStringAsFixed(0)} ккал/день'
              '${profile.medicalRestrictions.isNotEmpty ? "\nОграничения: ${profile.medicalRestrictions.join(", ")}" : ""}'
        : 'Ты — персональный фитнес-эксперт и нутрициолог FitnesBuster с 15-летним опытом.\n'
              'Ты сертифицирован NSCA, ISSN, обладаешь знаниями в спортивной физиологии и диетологии.\n'
              '${_client.languageInstruction} Будь конкретным, используй цифры и факты.';

    final recentHistory = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      ...recentHistory.map((m) => {'role': m.role, 'content': m.content}),
      {'role': 'user', 'content': newQuestion},
    ];

    return _client.sendMessagesList(messages);
  }

  Future<String> askQuestion(
    String question, {
    UserProfile? profile,
    List<String>? recentTopics,
  }) async {
    final context = profile != null
        ? '''
━━━ КОНТЕКСТ ПОЛЬЗОВАТЕЛЯ ━━━
Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'} | Возраст: ${profile.age} лет
Вес: ${profile.weight} кг | Рост: ${profile.height} см | ИМТ: ${profile.bmi.toStringAsFixed(1)}
Цель: ${_fitnessGoalLabel(profile.goal)} | Интенсивность: ${_intensityLabel(profile.intensity)}
Активность: ${profile.activityLevel.label}
Калораж: ${profile.dailyCalorieTarget.toStringAsFixed(0)} ккал/день (TDEE: ${profile.tdee.toStringAsFixed(0)})
${profile.medicalRestrictions.isNotEmpty ? 'Ограничения: ${profile.medicalRestrictions.join(", ")}' : ''}
'''
        : '';

    final topicsContext = recentTopics != null && recentTopics.isNotEmpty
        ? '\n━━━ ТЕМЫ ТЕКУЩЕЙ СЕССИИ ━━━\n${recentTopics.join(', ')}\n'
        : '';

    final prompt =
        '''
Ты — персональный фитнес-эксперт и нутрициолог FitnesBuster с 15-летним опытом.
Ты сертифицирован NSCA, ISSN, обладаешь знаниями в спортивной физиологии и диетологии.

$trainingPrinciplesCore
${profile != null ? methodologyEmphasisBlock(profile) : ''}
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

Максимум 5-6 предложений или 3 пункта. ${_client.languageInstruction}
''';

    return _client.sendMessage(prompt);
  }

  Future<String> parseWorkoutFromContent(
    String content, {
    String sourceHint = 'текст',
    UserProfile? profile,
  }) async {
    final truncated = content.length > 8000
        ? content.substring(0, 8000)
        : content;
    final exerciseCatalog = await ExerciseCatalogPrompt().build(
      profile?.workoutLocation,
    );

    final prompt =
        '''
Ты — AI-тренер FitnesBuster. Пользователь импортирует тренировочную программу.

ИСТОЧНИК: $sourceHint

СОДЕРЖИМОЕ:
$truncated

КАТАЛОГ УПРАЖНЕНИЙ И ОГРАНИЧЕНИЯ ПО МЕСТУ:
${exerciseCatalog.promptBlock}

Задача: извлечь все тренировки и преобразовать их в JSON-формат приложения.

Правила:
1. Если найдено несколько дней — создай отдельный элемент в "plan" для каждого.
2. Если день не указан — все упражнения объедини в 1 тренировочный день.
3. Названия упражнений переводи на РУССКИЙ язык.
4. Если подходы/повторения не указаны — ставь 3×10.
5. Если тип тренировки неизвестен — ставь "strength".
6. muscle_primary на русском: "грудь", "спина", "ноги", "плечи", "бицепс" и т.д.
7. Если данных недостаточно — сгенерируй разумный план на основе того, что есть.
8. Сопоставляй импортированные названия с точными названиями каталога; новое упражнение оставляй только при отсутствии безопасного аналога.

Ответь СТРОГО в формате JSON без markdown и пояснений:
{
  "week_number": 1,
  "phase": "Импорт",
  "weekly_volume_sets": 0,
  "plan": [
    {
      "day": 1,
      "name": "Название тренировки",
      "focus": "Группа мышц",
      "type": "strength",
      "duration_minutes": 60,
      "warmup": [],
      "exercises": [
        {
          "name": "Название упражнения",
          "catalog_status": "existing",
          "muscle_primary": "группа мышц",
          "muscle_secondary": [],
          "sets": 3,
          "reps": "10",
          "weight_guideline": "",
          "rest_seconds": 90,
          "rpe": 7,
          "tempo": "",
          "technique_cue": "",
          "progression": ""
        }
      ],
      "cooldown": [],
      "cardio_minutes": 0,
      "estimated_calories_burned": 0,
      "notes": ""
    }
  ],
  "recommendations": ["Импортировано из внешнего источника"],
  "next_week_preview": "",
  "weekly_summary": "Импортированная программа"
}
''';

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Ты — профессиональный AI-тренер. Преобразуй любой формат описания тренировок в структурированный JSON. ${_client.languageInstruction}',
      },
      {'role': 'user', 'content': prompt},
    ];

    return _client.callWithValidation(
      messages: messages,
      maxTokens: 4096,
      temperature: 0.3,
      validator: (raw) => validateWorkoutCatalogPreference(
        validateWorkoutJson(raw),
        exerciseCatalog.exactNames,
      ),
    );
  }

  String _fitnessGoalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.loseWeight:
        return 'Снижение веса';
      case FitnessGoal.gainWeight:
        return 'Набор массы';
      case FitnessGoal.maintain:
        return 'Поддержание формы';
      case FitnessGoal.beachBody:
        return 'К пляжному сезону';
      case FitnessGoal.sportPerformance:
        return 'Спортивные результаты';
    }
  }

  String _intensityLabel(IntensityLevel intensity) {
    switch (intensity) {
      case IntensityLevel.hardcore:
        return 'Хардкор';
      case IntensityLevel.intensive:
        return 'Интенсив';
      case IntensityLevel.balanced:
        return 'Баланс';
      case IntensityLevel.gradual:
        return 'Постепенный';
      case IntensityLevel.relaxed:
        return 'Лайт';
    }
  }

  void dispose() {}
}
