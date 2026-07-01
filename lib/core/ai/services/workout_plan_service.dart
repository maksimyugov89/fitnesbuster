import 'package:fitnesbuster/core/ai/base_client.dart';
import 'package:fitnesbuster/core/ai/validators/json_validator.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

class WorkoutPlanService {
  final BaseClient _client;

  WorkoutPlanService(this._client);

  Future<String> generateWorkoutPlan(
    UserProfile profile, {
    HealthData? recentHealth,
    int weekNumber = 1,
    String? previousPlanFeedback,
  }) async {
    final volumeBlock = weeklyVolumeBlock(profile.intensity, weekNumber);
    final progressionBlock2 = progressionBlock(profile.intensity);
    final recoveryBlock2 = recoveryBlock(recentHealth);
    final targetBlock2 = targetBlock(profile);
    final locationBlock2 = locationBlock(profile.workoutLocation);
    final runningBlock2 = runningBlock(profile.runningPreference);
    final healthBlock2 = healthBlock(
      profile.medicalRestrictions,
      profile.exerciseRestrictions,
    );

    final prompt =
        '''
Ты — сертифицированный персональный тренер (NSCA-CPT) и специалист по силовой подготовке.
Составь тренировочную программу на неделю №$weekNumber.

═══ ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ ═══
Пол: ${profile.gender == Gender.male ? 'Мужской' : 'Женский'}
Возраст: ${profile.age} лет | Вес: ${profile.weight} кг | Рост: ${profile.height} см
ИМТ: ${profile.bmi.toStringAsFixed(1)} | Уровень активности: ${profile.activityLevel.label}

═══ ЦЕЛЬ И ВРЕМЕННЫЕ РАМКИ ═══
$targetBlock2

═══ ТРЕНИРОВОЧНЫЕ ПАРАМЕТРЫ ═══
Интенсивность: ${intensityLabel(profile.intensity)}
$volumeBlock
$progressionBlock2

${recoveryBlock2.isNotEmpty ? '═══ ДАННЫЕ О ВОССТАНОВЛЕНИИ ═══\n$recoveryBlock2\n' : ''}${locationBlock2.isNotEmpty ? '═══ МЕСТО ТРЕНИРОВКИ И ОБОРУДОВАНИЕ ═══\n$locationBlock2\n' : ''}${runningBlock2.isNotEmpty ? '═══ КАРДИО-ПРОТОКОЛ ═══\n$runningBlock2\n' : ''}${healthBlock2.isNotEmpty ? '═══ МЕДИЦИНСКИЕ ОГРАНИЧЕНИЯ (СТРОГО СОБЛЮДАТЬ) ═══\n$healthBlock2\n' : ''}${previousPlanFeedback != null ? '═══ ОБРАТНАЯ СВЯЗЬ ОТ ПОЛЬЗОВАТЕЛЯ ═══\n$previousPlanFeedback\n' : ''}
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

    return validateWorkoutJson(extractJson(await _client.sendMessage(prompt)));
  }

  String weeklyVolumeBlock(IntensityLevel intensity, int weekNumber) {
    final sets = switch (intensity) {
      IntensityLevel.relaxed => '10-12 рабочих подходов/мышечную группу/неделю',
      IntensityLevel.gradual => '12-15 рабочих подходов/мышечную группу/неделю',
      IntensityLevel.balanced =>
        '15-18 рабочих подходов/мышечную группу/неделю',
      IntensityLevel.intensive =>
        '18-22 рабочих подхода/мышечную группу/неделю',
      IntensityLevel.hardcore =>
        '22-30 рабочих подходов/мышечную группу/неделю',
    };
    final phase = weekNumber <= 4
        ? 'Адаптация (сниженный объём, отработка техники)'
        : weekNumber <= 8
        ? 'Прогресс (наращивание объёма)'
        : weekNumber <= 12
        ? 'Интенсификация (максимальный объём)'
        : 'Пик (снижение объёма, максимальные веса)';
    return 'Целевой объём: $sets\nФаза мезоцикла: $phase (неделя $weekNumber из 12)';
  }

  String progressionBlock(IntensityLevel intensity) {
    return switch (intensity) {
      IntensityLevel.relaxed || IntensityLevel.gradual =>
        'Схема прогрессии: линейная — добавляй вес только когда выполняешь ВСЕ подходы в верхней границе диапазона повторений. Шаг: 1.25-2.5 кг на изолирующих, 2.5-5 кг на базовых.',
      IntensityLevel.balanced =>
        'Схема прогрессии: двойная прогрессия — сначала доводи повторения до верхней границы диапазона, затем добавляй вес и начинай заново с нижней границы. Шаг: 2.5 кг на изолирующих, 5 кг на базовых.',
      IntensityLevel.intensive || IntensityLevel.hardcore =>
        'Схема прогрессии: волновая — Неделя А (тяжёлая, 3-5 повт, 85%+ 1ПМ) → Неделя Б (умеренная, 8-12 повт, 70-75% 1ПМ). Применяй AMRAP в последнем сете для мониторинга прогресса.',
    };
  }

  String recoveryBlock(HealthData? health) {
    if (health == null) return '';
    final buf = StringBuffer();
    if (health.sleepMinutes != null) {
      final hours = (health.sleepMinutes! / 60).toStringAsFixed(1);
      buf.writeln(
        'Сон: $hours ч — ${health.sleepMinutes! < 420 ? "НЕДОСТАТОЧНО — снизь интенсивность на 15%, избегай тяжёлых базовых упражнений" : "в норме"}',
      );
    }
    if (health.heartRateResting != null) {
      buf.writeln(
        'Пульс покоя: ${health.heartRateResting} уд/мин — ${health.heartRateResting! > 70 ? "повышен, возможно накопленная усталость — увеличь время разминки" : "в норме"}',
      );
    }
    if (health.steps != null) {
      buf.writeln(
        'Средняя активность: ${(health.steps! / 7).round()} шаг/день',
      );
    }
    return buf.toString();
  }

  String targetBlock(UserProfile profile) {
    final buf = StringBuffer();
    buf.writeln('Фитнес-цель: ${fitnessGoalLabel(profile.goal)}');
    final diff = profile.targetWeight != null
        ? (profile.weight - profile.targetWeight!).abs()
        : null;
    if (profile.targetWeight != null) {
      final direction = profile.weight > profile.targetWeight!
          ? 'снизить'
          : 'набрать';
      buf.writeln(
        'Целевой вес: ${profile.targetWeight!.toStringAsFixed(1)} кг (нужно $direction ${diff!.toStringAsFixed(1)} кг)',
      );
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
    buf.writeln(
      'Дневной калораж: ${profile.dailyCalorieTarget.toStringAsFixed(0)} ккал (TDEE = ${profile.tdee.toStringAsFixed(0)})',
    );
    return buf.toString();
  }

  String locationBlock(String? location) {
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

  String runningBlock(String? running) {
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

  String healthBlock(List<String> medical, List<String> exercise) {
    if (medical.isEmpty && exercise.isEmpty) return '';
    final buf = StringBuffer(
      'Ограничения по здоровью (СТРОГО СОБЛЮДАТЬ — нарушение опасно для пользователя):',
    );
    if (medical.isNotEmpty) {
      buf.write('\n- Медицинские ограничения: ${medical.join(', ')}');
      buf.write(
        '\n  → Исключи все упражнения и нагрузки, противопоказанные при этих состояниях.',
      );
    }
    if (exercise.isNotEmpty) {
      buf.write('\n- Запрещённые упражнения: ${exercise.join(', ')}');
      buf.write(
        '\n  → Эти упражнения НЕЛЬЗЯ включать в программу ни в каком виде.',
      );
    }
    return buf.toString();
  }

  String fitnessGoalLabel(FitnessGoal goal) {
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

  String intensityLabel(IntensityLevel intensity) {
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
}
