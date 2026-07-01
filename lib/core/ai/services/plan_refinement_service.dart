import 'dart:convert';
import 'package:fitnesbuster/core/ai/base_client.dart';
import 'package:fitnesbuster/core/ai/validators/json_validator.dart';
import 'package:fitnesbuster/core/ai/services/workout_plan_service.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

class PlanRefinementService {
  final BaseClient _client;
  final WorkoutPlanService _workoutPlanService;

  PlanRefinementService(this._client, this._workoutPlanService);

  Future<String> refineWorkoutPlan(
    UserProfile profile,
    List<TestExerciseResult> exercises,
  ) async {
    final exerciseLines = exercises
        .map((e) {
          final w = e.comfortableWeightKg > 0
              ? '${e.comfortableWeightKg} кг'
              : 'без веса';
          return '- ${e.exerciseName}: $w, ${e.comfortableSets} подх. × ${e.comfortableReps} повт'
              '${e.notes != null && e.notes!.isNotEmpty ? ' (заметка: ${e.notes})' : ''}';
        })
        .join('\n');

    final volumeBlock = _workoutPlanService.weeklyVolumeBlock(
      profile.intensity,
      1,
    );
    final progressionBlock = _workoutPlanService.progressionBlock(
      profile.intensity,
    );
    final locationBlock = _workoutPlanService.locationBlock(
      profile.workoutLocation,
    );
    final runningBlock = _workoutPlanService.runningBlock(
      profile.runningPreference,
    );
    final healthBlock = _workoutPlanService.healthBlock(
      profile.medicalRestrictions,
      profile.exerciseRestrictions,
    );
    final targetBlock = _workoutPlanService.targetBlock(profile);

    final prompt =
        '''
Ты — сертифицированный персональный тренер (NSCA-CPT). Пользователь завершил тестовую неделю.
Составь скорректированную программу тренировок на 7 дней на основе РЕАЛЬНЫХ показателей.

═══ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ═══
Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'}
Возраст: ${profile.age} лет | Вес: ${profile.weight} кг | Рост: ${profile.height} см
Интенсивность: ${_workoutPlanService.intensityLabel(profile.intensity)}

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

    return validateWorkoutJson(extractJson(await _client.sendMessage(prompt)));
  }

  Future<String> correctWorkoutPlan({
    required String currentPlanJson,
    required String userInput,
    String correctionType = 'merge',
    String sourceHint = '',
  }) async {
    final truncatedInput = userInput.length > 6000
        ? userInput.substring(0, 6000)
        : userInput;

    final planSummary = _buildPlanSummary(currentPlanJson);

    final taskBlock = switch (correctionType) {
      'post_workout' =>
        '''Пользователь только что завершил тренировку (данные ниже). Задача:
1. Оцени нагрузку: была ли тренировка лёгкой, нормальной или тяжёлой?
2. При необходимости скорректируй следующие тренировочные дни (не текущий):
   — если перегрузка → снизь интенсивность следующего дня на 10-15%
   — если недогрузка → добавь 1-2 подхода к ключевым упражнениям
   — если пропущены упражнения → перенеси их на следующий подходящий день
3. НЕ меняй уже выполненные тренировки — только будущие.''',
      'preference' =>
        '''Пользователь хочет скорректировать план по личным предпочтениям. Задача:
1. Учти пожелание пользователя и внеси МИНИМАЛЬНЫЕ необходимые изменения.
2. Заменяй упражнения только на аналогичные по нагрузке и группе мышц.
3. Сохрани общий объём тренировок (±10% подходов).
4. Объясни каждое изменение в "changes".''',
      _ =>
        '''Пользователь добавил тренировку из внешнего источника. Задача:
1. Проанализируй добавляемую тренировку и найди подходящий день в плане.
2. Интегрируй новые упражнения: заменяй дублирующиеся, добавляй недостающие.
3. Если добавляемая тренировка на другие мышечные группы — создай/замени подходящий день.
4. Сохрани баланс плана (не перегружай одну группу мышц).
5. Объясни каждое изменение в "changes".''',
    };

    final prompt =
        '''
Ты — персональный AI-тренер FitnesBuster. Твоя задача — скорректировать тренировочный план пользователя.

═══ ТЕКУЩИЙ ПЛАН (структура) ═══
$planSummary

═══ ЗАПРОС НА КОРРЕКЦИЮ ═══
Тип: $correctionType
${sourceHint.isNotEmpty ? 'Источник: $sourceHint' : ''}

$truncatedInput

═══ ЗАДАЧА ═══
$taskBlock

ВАЖНО:
— Возвращай ПОЛНЫЙ обновлённый план (все 7 дней, даже если изменился только один)
— В поле "changes" перечисли ВСЕ изменения (каждое изменение = отдельная строка)
— В "correction_reasoning" — 1-2 предложения об общей логике коррекции
— Сохрани формат плана точно как в текущем

Ответь СТРОГО в JSON без markdown:
{
  "week_number": 1,
  "phase": "...",
  "weekly_volume_sets": 0,
  "plan": [
    {
      "day": 1,
      "name": "...",
      "focus": "...",
      "type": "strength",
      "duration_minutes": 60,
      "warmup": [],
      "exercises": [
        {
          "name": "Название упражнения",
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
  "changes": [
    "День X: [что изменено] — [причина]"
  ],
  "correction_reasoning": "Краткое объяснение логики коррекции",
  "recommendations": [],
  "next_week_preview": "",
  "weekly_summary": ""
}
''';

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Ты — персональный AI-тренер FitnesBuster. '
            'Корректируй планы тренировок профессионально и с обоснованием. '
            '${_client.languageInstruction} Формат ответа — JSON.',
      },
      {'role': 'user', 'content': prompt},
    ];

    return _client.callWithValidation(
      messages: messages,
      maxTokens: 5000,
      temperature: 0.4,
      validator: validateWorkoutJson,
    );
  }

  String _buildPlanSummary(String planJson) {
    try {
      final data = jsonDecode(planJson) as Map<String, dynamic>;
      final plan = data['plan'] as List? ?? [];
      final buf = StringBuffer();
      const dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      for (int i = 0; i < plan.length; i++) {
        final day = plan[i] as Map<String, dynamic>;
        final label = i < dayLabels.length ? dayLabels[i] : 'День ${i + 1}';
        final focus =
            day['focus'] as String? ?? day['name'] as String? ?? 'Отдых';
        final exercises = (day['exercises'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        if (exercises.isEmpty) {
          buf.writeln('$label: ОТДЫХ ($focus)');
        } else {
          final names = exercises
              .map((e) => '${e['name']} ${e['sets']}×${e['reps']}')
              .take(6)
              .join(', ');
          buf.writeln('$label — $focus: $names');
        }
      }
      final phase = data['phase'] as String? ?? '';
      final vol = data['weekly_volume_sets'] ?? 0;
      return '${phase.isNotEmpty ? 'Фаза: $phase | ' : ''}Объём: $vol подходов\n${buf.toString().trim()}';
    } catch (_) {
      return planJson.length > 2000 ? planJson.substring(0, 2000) : planJson;
    }
  }
}
