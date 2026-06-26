import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/data/models/free_exercise_db.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ExMuscle {
  // Original 16
  pectoralisMajor,
  pectoralisMinor,
  latissimusDorsi,
  rhomboids,
  trapezius,
  anteriorDeltoid,
  lateralDeltoid,
  posteriorDeltoid,
  biceps,
  triceps,
  quadriceps,
  hamstrings,
  gluteusMaximus,
  calves,
  rectusAbdominis,
  obliques,
  // Extended 10
  erectorSpinae,
  transverseAbdominis,
  brachialis,
  hipFlexors,
  forearmFlexors,
  adductors,
  rotatorCuff,
  serratusAnterior,
  levatorScapulae,
  gluteusMedius;

  static ExMuscle? fromJson(String value) {
    try {
      return ExMuscle.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}

enum ExEquipment {
  barbell,
  dumbbell,
  machine,
  bodyweight,
  cables,
  kettlebell,
  none;

  static ExEquipment fromJson(String value) {
    try {
      return ExEquipment.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ExEquipment.none;
    }
  }
}

enum ExMovementType {
  push,
  pull,
  hinge,
  squat,
  lunge,
  rotation,
  isolation;

  static ExMovementType fromJson(String value) {
    try {
      return ExMovementType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ExMovementType.push;
    }
  }
}

enum ExDifficulty {
  beginner,
  intermediate,
  advanced;

  static ExDifficulty fromJson(String value) {
    try {
      return ExDifficulty.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ExDifficulty.intermediate;
    }
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class ExerciseDbModel {
  final String id;
  final String name;
  // Stored from JSON when available; getter falls back to static map then English.
  final String? _nameRu;
  final String description;
  final ExDifficulty difficulty;
  final List<ExEquipment> equipment;
  final List<ExMuscle> primaryMuscles;
  final List<ExMuscle> secondaryMuscles;
  final List<String> instructions;
  final ExMovementType movementType;
  final List<String> tags;
  final String? exerciseDbId;

  ExerciseDbModel({
    required this.id,
    required this.name,
    String? nameRu,
    this.description = '',
    required this.difficulty,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.movementType,
    required this.tags,
    this.exerciseDbId,
  }) : _nameRu = nameRu;

  factory ExerciseDbModel.fromJson(Map<String, dynamic> json) {
    return ExerciseDbModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameRu: json['nameRu'] as String?,
      description: json['description'] as String? ?? '',
      difficulty: ExDifficulty.fromJson(json['difficulty'] as String? ?? ''),
      equipment: ((json['equipment'] as List?) ?? [])
          .map((e) => ExEquipment.fromJson(e as String))
          .toList(),
      primaryMuscles: ((json['primaryMuscles'] as List?) ?? [])
          .map((e) => ExMuscle.fromJson(e as String))
          .whereType<ExMuscle>()
          .toList(),
      secondaryMuscles: ((json['secondaryMuscles'] as List?) ?? [])
          .map((e) => ExMuscle.fromJson(e as String))
          .whereType<ExMuscle>()
          .toList(),
      instructions: ((json['instructions'] as List?) ?? [])
          .map((e) => e as String)
          .toList(),
      movementType:
          ExMovementType.fromJson(json['movementType'] as String? ?? ''),
      tags: ((json['tags'] as List?) ?? []).map((e) => e as String).toList(),
      exerciseDbId: json['exerciseDbId'] as String?,
    );
  }

  /// GIF URL served from Firebase Hosting (immutable CDN, no API key needed).
  String? get gifUrl {
    if (exerciseDbId == null) return null;
    return 'https://fitnesbuster.web.app/gifs/$exerciseDbId.gif';
  }

  /// Russian display name: JSON value → static map → English fallback.
  String get nameRu => _nameRu ?? _ruNames[name] ?? name;

  static const String _freeExDbBase =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

  /// Returns [count] image URLs from free-exercise-db matched by English name.
  /// Returns empty list if no match found.
  List<String> freeDbImageUrls({int count = 2}) {
    final freeId = FreeExerciseDb.instance.idForName(name);
    if (freeId == null) return const [];
    return List.generate(count, (i) => '$_freeExDbBase/$freeId/$i.jpg');
  }

  // ignore: prefer_constructors_over_static_methods
  static const _ruNames = <String, String>{
    'Abdominal Twist Machine': 'Скручивание в тренажёре',
    'Alternating Dumbbell Curl': 'Поочерёдное сгибание с гантелями',
    'Arch Push-Up': 'Дугообразное отжимание',
    'Archery Pull-Up': 'Подтягивание «Лучник»',
    'Arm Circles': 'Круговые вращения руками',
    'Backward Arm Circles': 'Обратные вращения руками',
    'Barbell Back Squat': 'Приседание со штангой',
    'Barbell Bench Press': 'Жим штанги лёжа',
    'Barbell Bent-Over Row': 'Тяга штанги в наклоне',
    'Barbell Biceps Curl': 'Сгибание рук со штангой',
    'Barbell Bulgarian Split Squats': 'Болгарские выпады со штангой',
    'Barbell Calf Raise': 'Подъём на носки со штангой',
    'Barbell Calf Raise Reverse Grip': 'Подъём на носки обратным хватом',
    'Barbell Calf Raise on Decline': 'Подъём на носки в наклоне',
    'Barbell Calf Raise with Pause': 'Подъём на носки с паузой',
    'Barbell Calf Raise with Tempo Control': 'Подъём на носки с контролем темпа',
    'Barbell Chest Dip': 'Отжимание на брусьях для груди',
    'Barbell Chest Flye': 'Разведение со штангой лёжа',
    'Barbell Chest Press': 'Жим штанги для груди',
    'Barbell Clean and Press': 'Тяга со штангой и жим',
    'Barbell Close-Grip Curl': 'Сгибание штанги узким хватом',
    'Barbell Crunches': 'Скручивания со штангой',
    'Barbell Curl with Pause': 'Сгибание штанги с паузой',
    'Barbell Curl with Tempo Control': 'Сгибание штанги с контролем темпа',
    'Barbell Dead Bugs': 'Мёртвый жук со штангой',
    'Barbell Deadlift': 'Становая тяга',
    'Barbell Decline Bench Press': 'Жим штанги лёжа вниз',
    'Barbell Decline Chest Press': 'Жим штанги в наклоне вниз',
    'Barbell Face Pull': 'Тяга штанги к лицу',
    'Barbell Flyes': 'Разведение со штангой',
    'Barbell Front Raise': 'Подъём штанги перед собой',
    'Barbell Front Squats': 'Фронтальные приседания со штангой',
    'Barbell Glute Bridge': 'Ягодичный мостик со штангой',
    'Barbell Hammer Curl': 'Молотковые сгибания со штангой',
    'Barbell Hang Clean': 'Подъём штанги на грудь с виса',
    'Barbell Hanging Leg Raises': 'Подъём ног в висе со штангой',
    'Barbell Hip Raise': 'Подъём таза со штангой',
    'Barbell Hip Thrust': 'Ягодичный мостик со штангой',
    'Barbell Hip Thrust with Pause': 'Ягодичный мостик с паузой',
    'Barbell Hyperextensions': 'Гиперэкстензия со штангой',
    'Barbell Incline Bench Press': 'Жим штанги лёжа в наклоне вверх',
    'Barbell Incline Chest Press': 'Жим штанги в наклоне вверх',
    'Barbell Lateral Raise': 'Подъём штанги в стороны',
    'Barbell Lateral Raise (Behind the Back)': 'Подъём штанги из-за спины',
    'Barbell Leaning Press': 'Жим в наклоне',
    'Barbell Leg Curl': 'Сгибание ног со штангой',
    'Barbell Leg Raises': 'Подъём ног со штангой',
    'Barbell Lunges': 'Выпады со штангой',
    'Barbell Oblique Twist': 'Скручивание на косые со штангой',
    'Barbell Overhead Press': 'Жим штанги над головой',
    'Barbell Pec Minor Press': 'Жим штанги для малой грудной',
    'Barbell Pullover': 'Пуловер со штангой',
    'Barbell Push Press': 'Толчковый жим штанги',
    'Barbell Rear Lateral Raise': 'Подъём штанги назад в стороны',
    'Barbell Reverse Fly': 'Обратное разведение со штангой',
    'Barbell Rocking Bench': 'Жим штанги с раскачкой',
    'Barbell Rollouts': 'Катание на штанге',
    'Barbell Romanian Deadlift': 'Румынская тяга со штангой',
    'Barbell Row': 'Тяга штанги в наклоне',
    'Barbell Russian Twist': 'Русский твист со штангой',
    'Barbell Seated Calf Raise': 'Подъём на носки сидя со штангой',
    'Barbell Shoulder Press': 'Жим штанги на плечи',
    'Barbell Shrug': 'Шраги со штангой',
    'Barbell Shrugs': 'Шраги со штангой',
    'Barbell Side Bend': 'Наклоны в стороны со штангой',
    'Barbell Side Lateral Raise': 'Подъём штанги в сторону',
    'Barbell Side Raise': 'Подъём штанги в стороны',
    'Barbell Single-Arm Row': 'Тяга штанги одной рукой',
    'Barbell Split Squats': 'Разножка со штангой',
    'Barbell Squats': 'Приседания со штангой',
    'Barbell Step-Ups': 'Зашагивания со штангой',
    'Barbell Sumo Deadlift': 'Становая тяга сумо',
    'Barbell Tricep Extension': 'Разгибание трицепса со штангой',
    'Barbell Tricep Kickback': 'Разгибание трицепса назад',
    'Barbell Tricep Overhead Extension': 'Французский жим со штангой',
    'Barbell Tricep Press': 'Жим на трицепс',
    'Barbell Tricep Push': 'Толчок на трицепс',
    'Barbell Tricep Twist': 'Скручивание на трицепс',
    'Barbell Twisting Crunch': 'Скручивание с разворотом',
    'Barbell Umbilical Row': 'Тяга штанги к животу',
    'Barbell Upright Row': 'Тяга штанги к подбородку',
    'Barbell Wide-Grip Curl': 'Сгибание широким хватом',
    'Barbell Woodchoppers': 'Дровосек со штангой',
    'Bear Crawl with Shoulder Lifts': 'Медвежья ходьба с подъёмом плеч',
    'Bicep Curl Machine': 'Сгибание бицепса в тренажёре',
    'Bicycle Crunch': 'Велосипедное скручивание',
    'Bicycle Crunches': 'Велосипедные скручивания',
    'Bodyweight Bicep Curl': 'Сгибание бицепса с весом тела',
    'Bodyweight Curls': 'Сгибания с весом тела',
    'Bodyweight Curtsy Lunge': 'Реверанс',
    'Bodyweight Deadlift': 'Становая тяга без отягощения',
    'Bodyweight Hamstring Curl': 'Сгибание бедра с весом тела',
    'Bodyweight Lateral Raise': 'Подъём в сторону без отягощения',
    'Bodyweight Lunge': 'Выпад без отягощения',
    'Bodyweight Pistol Squat': 'Пистолет',
    'Bodyweight Rows (Pull-Up Bar)': 'Горизонтальные подтягивания',
    'Bodyweight Squat': 'Приседание без отягощения',
    'Bodyweight Step-Up': 'Зашагивание без отягощения',
    'Bodyweight Wall Sit': 'Стульчик',
    'Cable Angled Curl': 'Сгибание в блоке под углом',
    'Cable Behind-the-Back Row': 'Тяга в блоке из-за спины',
    'Cable Bent-Over Reverse Flyes': 'Обратное разведение в блоке',
    'Cable Bent-Over Row': 'Тяга в блоке в наклоне',
    'Cable Bicep Curl': 'Сгибание бицепса в блоке',
    'Cable Bicep Curl Machine': 'Сгибание бицепса в тренажёре-блоке',
    'Cable Calf Raise': 'Подъём на носки в блоке',
    'Cable Chest Dip': 'Отжимание на брусьях с блоком',
    'Cable Chest Press': 'Жим в блоке для груди',
    'Cable Concentration Curl': 'Концентрированное сгибание в блоке',
    'Cable Crossover': 'Кроссовер в блоке',
    'Cable Crunch': 'Скручивание в блоке',
    'Cable Curl': 'Сгибание в блоке',
    'Cable Dead Bug': 'Мёртвый жук с блоком',
    'Cable Deadbugs': 'Мёртвые жуки с блоком',
    'Cable Deadlift': 'Становая тяга в блоке',
    'Cable Deadlifts': 'Становая тяга в блоке',
    'Cable Decline Chest Press': 'Жим в блоке в наклоне вниз',
    'Cable Face Pull': 'Тяга к лицу в блоке',
    'Cable Face Pulls': 'Тяга к лицу в блоке',
    'Cable Fly': 'Разведение в блоке',
    'Cable Front Lunge': 'Выпад вперёд с блоком',
    'Cable Front Raise': 'Подъём перед собой в блоке',
    'Cable Glute Bridges': 'Ягодичный мостик с блоком',
    'Cable Glute Kickbacks': 'Отведение ноги назад в блоке',
    'Cable Hammer Curl': 'Молотковое сгибание в блоке',
    'Cable Hamstring Curl': 'Сгибание ног в блоке',
    'Cable Hamstring Flip': 'Нордическое сгибание в блоке',
    'Cable Hip Lift': 'Подъём таза в блоке',
    'Cable Hip Rotations': 'Вращение таза в блоке',
    'Cable Hip Thrusts': 'Ягодичный мостик с тягой блока',
    'Cable Hyperextension': 'Гиперэкстензия в блоке',
    'Cable Incline Chest Press': 'Жим в блоке в наклоне вверх',
    'Cable Incline Fly': 'Разведение в блоке в наклоне',
    'Cable Lat Pulldown': 'Тяга блока к груди',
    'Cable Lat Row': 'Горизонтальная тяга в блоке',
    'Cable Lateral Raise': 'Подъём в сторону в блоке',
    'Cable Lateral Raise with Rope': 'Подъём в сторону с канатом',
    'Cable Leg Press': 'Жим ногами в блоке',
    'Cable Leg Raise': 'Подъём ног в блоке',
    'Cable Lunge': 'Выпад с блоком',
    'Cable Overhead Lateral Raise': 'Подъём в сторону над головой в блоке',
    'Cable Overhead Press': 'Жим над головой в блоке',
    'Cable Overhead Press (Reverse Grip)': 'Жим обратным хватом над головой',
    'Cable Pec Minor Fly': 'Разведение малой грудной в блоке',
    'Cable Pec Minor Isolation': 'Изоляция малой грудной в блоке',
    'Cable Pec Minor Press': 'Жим малой грудной в блоке',
    'Cable Preacher Curl': 'Сгибание Скотта в блоке',
    'Cable Pullover': 'Пуловер в блоке',
    'Cable Rear Delt Fly': 'Разведение задней дельты в блоке',
    'Cable Rear Delt Flyes': 'Разведение задней дельты в блоке',
    'Cable Rear Fly': 'Обратное разведение в блоке',
    'Cable Reverse Curl': 'Обратное сгибание в блоке',
    'Cable Reverse Lunges': 'Обратные выпады с блоком',
    'Cable Rhomboid Fly': 'Разведение ромбовидных в блоке',
    'Cable Rhomboid Squeeze': 'Сведение лопаток в блоке',
    'Cable Rollout': 'Катание ролика в блоке',
    'Cable Romanian Deadlift': 'Румынская тяга в блоке',
    'Cable Rotational Twists': 'Скручивание с поворотом в блоке',
    'Cable Scapular Pull': 'Тяга лопаток в блоке',
    'Cable Shoulder Press': 'Жим на плечи в блоке',
    'Cable Shoulder Shrug': 'Шраги в блоке',
    'Cable Side Bends': 'Наклоны в стороны в блоке',
    'Cable Side Lateral Raise': 'Боковой подъём в блоке',
    'Cable Side Raise': 'Подъём в сторону в блоке',
    'Cable Single-Arm Row': 'Тяга одной рукой в блоке',
    'Cable Single-Arm Rows': 'Тяга одной рукой в блоке',
    'Cable Single-Leg Deadlift': 'Становая тяга на одной ноге в блоке',
    'Cable Split Squat': 'Разножка в блоке',
    'Cable Squat': 'Приседание в блоке',
    'Cable Step-Up': 'Зашагивание с блоком',
    'Cable Step-Ups': 'Зашагивания с блоком',
    'Cable Straight Arm Pulldown': 'Тяга прямых рук в блоке',
    'Cable Trap Extension': 'Разгибание трапеции в блоке',
    'Cable Trap Flye': 'Разведение трапеции в блоке',
    'Cable Tricep Extension': 'Разгибание трицепса в блоке',
    'Cable Tricep Fly': 'Разведение трицепса в блоке',
    'Cable Tricep Kickback': 'Разгибание трицепса назад в блоке',
    'Cable Tricep Overhead Press': 'Жим трицепса над головой в блоке',
    'Cable Tricep Preacher Press': 'Жим трицепса Скотта в блоке',
    'Cable Tricep Pushdown': 'Жим трицепса вниз в блоке',
    'Cable Twisting Crunch': 'Скручивание с поворотом в блоке',
    'Cable Upright Row': 'Тяга к подбородку в блоке',
    'Cable Wide-Grip Pulldown': 'Тяга широким хватом в блоке',
    'Cable Windmill': 'Мельница в блоке',
    'Cable Woodchopper': 'Дровосек в блоке',
    'Cable Woodchoppers': 'Дровосек в блоке',
    'Cable YTW': 'YTW в блоке',
    'Calf Raises on Toes': 'Подъём на носки',
    'Calf Raises on a Wall': 'Подъём на носки у стены',
    'Chest Press Machine': 'Жим для груди в тренажёре',
    'Chest-Supported Push-Up': 'Отжимание с упором на грудь',
    'Chin-Up': 'Подтягивание обратным хватом',
    'Chin-Ups': 'Подтягивания обратным хватом',
    'Close-Grip Pull-Ups': 'Подтягивания узким хватом',
    'Close-Grip Push Up': 'Отжимание узким хватом',
    'Concentration Curl': 'Концентрированное сгибание',
    'Crunch Machine': 'Скручивание в тренажёре',
    'Crunches': 'Скручивания',
    'Curtsy Lunge': 'Реверанс',
    'Dead Bug': 'Мёртвый жук',
    'Decline Crunch Machine': 'Скручивание в наклоне вниз',
    'Decline Dumbbell Press': 'Жим гантелей в наклоне вниз',
    'Decline Kettlebell Press': 'Жим гири в наклоне вниз',
    'Decline Leg Press': 'Жим ногами в наклоне',
    'Decline Machine Chest Press': 'Жим в тренажёре в наклоне вниз',
    'Decline Machine Shoulder Press': 'Жим на плечи в тренажёре в наклоне',
    'Decline Push Up': 'Отжимание с ногами на возвышении',
    'Diamond Push Up': 'Алмазное отжимание',
    'Donkey Kick': 'Удар ослика',
    'Dumbbell Arnold Press': 'Жим Арнольда',
    'Dumbbell Bench Press': 'Жим гантелей лёжа',
    'Dumbbell Bent-Over Lateral Raise': 'Подъём гантелей в стороны в наклоне',
    'Dumbbell Bent-Over Row': 'Тяга гантелей в наклоне',
    'Dumbbell Bent-Over Rows': 'Тяга гантелей в наклоне',
    'Dumbbell Box Squats': 'Приседание на тумбу с гантелями',
    'Dumbbell Calf Raise on Step': 'Подъём на носки на ступеньке',
    'Dumbbell Calf Raise with Ankle Tilt': 'Подъём на носки с наклоном стопы',
    'Dumbbell Calf Raise with Eccentric Focus': 'Подъём на носки с акцентом на опускание',
    'Dumbbell Calf Raise with Knee Lift': 'Подъём на носки с подъёмом колена',
    'Dumbbell Chest Fly': 'Разведение гантелей лёжа',
    'Dumbbell Chest Press': 'Жим гантелей для груди',
    'Dumbbell Chest Press with Leg Raise': 'Жим гантелей с подъёмом ног',
    'Dumbbell Chest Press with Shoulder Rotation': 'Жим гантелей с поворотом',
    'Dumbbell Clamshell': 'Моллюск с гантелью',
    'Dumbbell Crunches': 'Скручивания с гантелями',
    'Dumbbell Curl': 'Сгибание рук с гантелями',
    'Dumbbell Dead Bug': 'Мёртвый жук с гантелями',
    'Dumbbell Deadlift': 'Становая тяга с гантелями',
    'Dumbbell Decline Fly': 'Разведение гантелей в наклоне вниз',
    'Dumbbell Donkey Kick': 'Удар ослика с гантелью',
    'Dumbbell Face Pull': 'Тяга гантелей к лицу',
    'Dumbbell Face Pulls': 'Тяга гантелей к лицу',
    'Dumbbell Fire Hydrant': 'Гидрант с гантелью',
    'Dumbbell Floor Press': 'Жим гантелей лёжа на полу',
    'Dumbbell Fly': 'Разведение гантелей',
    'Dumbbell Front Raise': 'Подъём гантелей перед собой',
    'Dumbbell Front Raise with Twist': 'Подъём гантелей с поворотом',
    'Dumbbell Glute Bridge': 'Ягодичный мостик с гантелью',
    'Dumbbell Hack Squats': 'Гакк-приседания с гантелями',
    'Dumbbell Hamstring Curl': 'Сгибание ног с гантелями',
    'Dumbbell Hanging Leg Raises': 'Подъём ног в висе с гантелями',
    'Dumbbell Hip Thrust': 'Ягодичный мостик с гантелью',
    'Dumbbell Incline Fly': 'Разведение гантелей в наклоне вверх',
    'Dumbbell Lat Pulldown': 'Тяга гантели к груди',
    'Dumbbell Lateral Raise': 'Подъём гантелей в стороны',
    'Dumbbell Leg Curl': 'Сгибание ног с гантелями',
    'Dumbbell Leg Raises': 'Подъём ног с гантелями',
    'Dumbbell Lunges': 'Выпады с гантелями',
    'Dumbbell One-Arm Rows': 'Тяга гантели одной рукой',
    'Dumbbell Overhead Lateral Raise': 'Подъём гантелей в стороны над головой',
    'Dumbbell Overhead Press': 'Жим гантелей над головой',
    'Dumbbell Pec Minor Fly': 'Разведение для малой грудной',
    'Dumbbell Pec Minor Raise': 'Подъём для малой грудной',
    'Dumbbell Pronated Side Raise': 'Подъём в стороны пронацией',
    'Dumbbell Pull Over': 'Пуловер с гантелями',
    'Dumbbell Pullover': 'Пуловер с гантелью',
    'Dumbbell Pullovers': 'Пуловер с гантелями',
    'Dumbbell Rear Delt Fly': 'Разведение задней дельты с гантелями',
    'Dumbbell Rear Flyes': 'Обратное разведение гантелей',
    'Dumbbell Rear Lateral Raise': 'Подъём гантелей назад в стороны',
    'Dumbbell Reverse Fly': 'Обратное разведение гантелей',
    'Dumbbell Romanian Deadlift': 'Румынская тяга с гантелями',
    'Dumbbell Russian Twist': 'Русский твист с гантелями',
    'Dumbbell Russian Twists': 'Русские твисты с гантелями',
    'Dumbbell Seated Calf Raise': 'Подъём на носки сидя с гантелями',
    'Dumbbell Shoulder Press': 'Жим гантелей на плечи',
    'Dumbbell Shrug': 'Шраги с гантелями',
    'Dumbbell Shrugs': 'Шраги с гантелями',
    'Dumbbell Side Bend': 'Наклоны в стороны с гантелью',
    'Dumbbell Side Raise': 'Подъём гантели в сторону',
    'Dumbbell Single-Arm Row': 'Тяга гантели в наклоне одной рукой',
    'Dumbbell Single-Leg Deadlift': 'Становая тяга на одной ноге',
    'Dumbbell Slow Lateral Raise': 'Медленный подъём гантелей в стороны',
    'Dumbbell Squat': 'Приседание с гантелями',
    'Dumbbell Squats': 'Приседания с гантелями',
    'Dumbbell Standing Calf Raise': 'Подъём на носки стоя с гантелями',
    'Dumbbell Step-Up': 'Зашагивание с гантелями',
    'Dumbbell Step-Ups': 'Зашагивания с гантелями',
    'Dumbbell Stiff-Leg Deadlift': 'Тяга гантелей на прямых ногах',
    'Dumbbell Tricep Bench Press': 'Жим гантелей узким хватом',
    'Dumbbell Tricep Dip': 'Отжимание на брусьях с гантелью',
    'Dumbbell Tricep Extension': 'Разгибание трицепса с гантелями',
    'Dumbbell Tricep Kickback': 'Разгибание трицепса с гантелью',
    'Dumbbell Tricep Pushdown': 'Жим трицепса вниз с гантелями',
    'Dumbbell Twist Lateral Raise': 'Подъём с поворотом в стороны',
    'Dumbbell Upright Row': 'Тяга гантелей к подбородку',
    'Dumbbell Wall Sits': 'Стульчик с гантелями',
    'Dumbbell Windmill': 'Мельница с гантелями',
    'Dumbbell Woodchoppers': 'Дровосек с гантелями',
    'Dumbbell YTW Flyes': 'YTW разведение с гантелями',
    'Elevated Feet Calf Raise Machine': 'Подъём на носки с ногами выше',
    'Face Pull': 'Тяга к лицу',
    'Face Pulls (Bodyweight)': 'Тяга к лицу с весом тела',
    'Fire Hydrant': 'Гидрант',
    'Front Dumbbell Raise': 'Подъём гантелей перед собой',
    'Front Raise': 'Подъём перед собой',
    'Glute-Ham Raise Machine': 'Подъём бедра в тренажёре',
    'Hack Squat': 'Гакк-приседание',
    'Hammer Curl': 'Молотковое сгибание',
    'Hammer Curl Machine': 'Молотковое сгибание в тренажёре',
    'Hanging Leg Raise': 'Подъём ног в висе',
    'Hanging Leg Raise Machine': 'Подъём ног в висе в тренажёре',
    'Head Pull': 'Тяга к голове',
    'Headscratcher': 'Французский жим стоя',
    'High-Pulley Cable Calf Raise': 'Подъём на носки через верхний блок',
    'Hip Thrust': 'Ягодичный мостик',
    'Hip Thrust Machine': 'Ягодичный мостик в тренажёре',
    'Hyperextension Machine': 'Гиперэкстензия в тренажёре',
    'Incline Barbell Press': 'Жим штанги в наклоне',
    'Incline Bicep Curl Machine': 'Сгибание бицепса в наклонном тренажёре',
    'Incline Calf Raise Machine': 'Подъём на носки в тренажёре в наклоне',
    'Incline Chest Press': 'Жим лёжа в наклоне вверх',
    'Incline Dumbbell Curl': 'Сгибание гантелей в наклоне',
    'Incline Dumbbell Press': 'Жим гантелей в наклоне',
    'Incline Kettlebell Press': 'Жим гири в наклоне',
    'Incline Leg Press': 'Жим ногами в наклоне',
    'Incline Machine Chest Press': 'Жим в тренажёре в наклоне',
    'Incline Machine Row': 'Тяга в наклоне в тренажёре',
    'Incline Machine Shoulder Press': 'Жим на плечи в наклоне в тренажёре',
    'Incline Push Up': 'Отжимание с опорой',
    'Inverted Rows': 'Горизонтальные подтягивания',
    'Isometric Shoulder Blade Squeezes': 'Изометрическое сжатие лопаток',
    'Jump Squats': 'Прыжковые приседания',
    'Kettlebell Alternating Curl': 'Поочерёдное сгибание с гирей',
    'Kettlebell Back Squat': 'Приседание с гирей сзади',
    'Kettlebell Behind-the-Back Raise': 'Подъём гири из-за спины',
    'Kettlebell Bent Over Row': 'Тяга гири в наклоне',
    'Kettlebell Bent-Over Lateral Raise': 'Подъём гири в сторону в наклоне',
    'Kettlebell Calf Raises': 'Подъём на носки с гирей',
    'Kettlebell Calf Raises with Explosive Motion': 'Взрывной подъём на носки с гирей',
    'Kettlebell Calf Raises with Heel Elevation': 'Подъём на носки с гирей на пятке',
    'Kettlebell Calf Raises with Weight Shift': 'Подъём на носки с гирей со сдвигом',
    'Kettlebell Chest Dip': 'Отжимание на брусьях с гирей',
    'Kettlebell Chest Fly': 'Разведение с гирей лёжа',
    'Kettlebell Chest Pass': 'Бросок гири от груди',
    'Kettlebell Chest Press': 'Жим гири лёжа',
    'Kettlebell Chest Raise': 'Подъём гири для груди',
    'Kettlebell Clean': 'Подрыв гири',
    'Kettlebell Clean and Press': 'Подрыв и жим гири',
    'Kettlebell Crossover Raise': 'Подъём гири крест-накрест',
    'Kettlebell Curl': 'Сгибание с гирей',
    'Kettlebell Curl with Pause': 'Сгибание с гирей и паузой',
    'Kettlebell Deadlift': 'Становая тяга с гирей',
    'Kettlebell Face Pull': 'Тяга гири к лицу',
    'Kettlebell Floor Press': 'Жим гири лёжа на полу',
    'Kettlebell Front Raise': 'Подъём гири перед собой',
    'Kettlebell Front Squat': 'Фронтальное приседание с гирей',
    'Kettlebell Glute Bridge': 'Ягодичный мостик с гирей',
    'Kettlebell Goblet Squat': 'Кубковое приседание с гирей',
    'Kettlebell Hammer Curl': 'Молотковое сгибание с гирей',
    'Kettlebell Hip Thrust': 'Ягодичный мостик с гирей',
    'Kettlebell Hollow Body Hold': 'Полое тело с гирей',
    'Kettlebell Incline Press': 'Жим гири в наклоне',
    'Kettlebell Lateral Raise': 'Подъём гири в сторону',
    'Kettlebell Lateral Raise with Pause': 'Подъём гири в сторону с паузой',
    'Kettlebell Lateral Raise with Rotation': 'Подъём гири в сторону с вращением',
    'Kettlebell Lunge': 'Выпад с гирей',
    'Kettlebell Overhead Press': 'Жим гири над головой',
    'Kettlebell Pallof Press': 'Жим Паллофа с гирей',
    'Kettlebell Pec Fly': 'Разведение гири для груди',
    'Kettlebell Pec Minor Raise': 'Подъём для малой грудной с гирей',
    'Kettlebell Pectoralis Minor Press': 'Жим гири для малой грудной',
    'Kettlebell Plank Twist': 'Планка с поворотом с гирей',
    'Kettlebell Press': 'Жим гири',
    'Kettlebell Pullover': 'Пуловер с гирей',
    'Kettlebell Push Press': 'Толчковый жим гири',
    'Kettlebell Rear Delt Fly': 'Разведение задней дельты с гирей',
    'Kettlebell Reverse Curl': 'Обратное сгибание с гирей',
    'Kettlebell Reverse Fly': 'Обратное разведение с гирей',
    'Kettlebell Romanian Deadlift': 'Румынская тяга с гирей',
    'Kettlebell Row': 'Тяга гири в наклоне',
    'Kettlebell Russian Twist': 'Русский твист с гирей',
    'Kettlebell Seated Calf Raises': 'Подъём на носки сидя с гирей',
    'Kettlebell Shoulder Press': 'Жим гири на плечи',
    'Kettlebell Shrug': 'Шраги с гирей',
    'Kettlebell Side Plank with Raise': 'Боковая планка с гирей',
    'Kettlebell Side Raise': 'Подъём гири в сторону',
    'Kettlebell Side Raise with Twist': 'Подъём гири с поворотом',
    'Kettlebell Single-Arm Curl': 'Сгибание одной рукой с гирей',
    'Kettlebell Single-Arm Lateral Raise': 'Подъём гири в сторону одной рукой',
    'Kettlebell Single-Leg Calf Raises': 'Подъём на носки на одной ноге с гирей',
    'Kettlebell Single-Leg Deadlift': 'Становая тяга на одной ноге с гирей',
    'Kettlebell Snatch': 'Рывок гири',
    'Kettlebell Split Squat': 'Разножка с гирей',
    'Kettlebell Squat': 'Приседание с гирей',
    'Kettlebell Step-Up': 'Зашагивание с гирей',
    'Kettlebell Stiff-Legged Deadlift': 'Тяга на прямых ногах с гирей',
    'Kettlebell Sumo Deadlift': 'Становая тяга сумо с гирей',
    'Kettlebell Sumo Squat': 'Приседание сумо с гирей',
    'Kettlebell Swing': 'Махи с гирей',
    'Kettlebell Swings': 'Махи с гирей',
    'Kettlebell Trap Shrug': 'Шраги для трапеции с гирей',
    'Kettlebell Tricep Burn': 'Прожигание трицепса с гирей',
    'Kettlebell Tricep Curl Press': 'Сгибание-жим на трицепс',
    'Kettlebell Tricep Dips': 'Отжимания на брусьях с гирей',
    'Kettlebell Tricep Extension': 'Разгибание трицепса с гирей',
    'Kettlebell Tricep Overhead Press': 'Жим гири над головой для трицепса',
    'Kettlebell Tricep Pushdown': 'Жим трицепса вниз с гирей',
    'Kettlebell Upright Row': 'Тяга гири к подбородку',
    'Kettlebell Windmill': 'Мельница с гирей',
    'Kettlebell Woodchopper': 'Дровосек с гирей',
    'L-Sit Pull-Up': 'Подтягивание в L-сиде',
    'Lat Pulldown': 'Тяга блока к груди',
    'Lat Pulldown Machine': 'Тяга блока к груди в тренажёре',
    'Lateral Cable Calf Raise': 'Боковой подъём на носки в блоке',
    'Leg Curl Machine': 'Сгибание ног в тренажёре',
    'Leg Extension': 'Разгибание ног',
    'Leg Press': 'Жим ногами',
    'Leg Raise': 'Подъём ног',
    'Leg Raise Machine': 'Подъём ног в тренажёре',
    'Leg Raises': 'Подъём ног',
    'Machine Anti-Rotation': 'Антиротация в тренажёре',
    'Machine Back Extensions': 'Гиперэкстензия в тренажёре',
    'Machine Bent-Over Rows': 'Тяга в наклоне в тренажёре',
    'Machine Bicep Curl': 'Сгибание бицепса в тренажёре',
    'Machine Cable Chop': 'Рубка в тренажёре',
    'Machine Cable Lateral Raise': 'Подъём в сторону в тренажёре',
    'Machine Chest Crossover': 'Кроссовер в тренажёре',
    'Machine Chest Fly (Decline)': 'Сведение рук в тренажёре (вниз)',
    'Machine Chest Fly (Flat)': 'Сведение рук в тренажёре (горизонтально)',
    'Machine Chest Fly (Incline)': 'Сведение рук в тренажёре (вверх)',
    'Machine Chest Press': 'Жим в тренажёре',
    'Machine Chest Press (Decline)': 'Жим в тренажёре в наклоне вниз',
    'Machine Chest Press (Flat)': 'Горизонтальный жим в тренажёре',
    'Machine Chest Press (Incline)': 'Жим в тренажёре в наклоне вверх',
    'Machine Deadlift': 'Становая тяга в тренажёре',
    'Machine Decline Lateral Raise': 'Подъём в сторону в тренажёре в наклоне',
    'Machine Face Pull': 'Тяга к лицу в тренажёре',
    'Machine Face Pulls': 'Тяга к лицу в тренажёре',
    'Machine Fly': 'Разведение в тренажёре',
    'Machine Front Raise with Weight': 'Подъём перед собой с весом в тренажёре',
    'Machine Glute Bridge': 'Ягодичный мостик в тренажёре',
    'Machine Hip Twist': 'Скручивание таза в тренажёре',
    'Machine Hyperextension': 'Гиперэкстензия в тренажёре',
    'Machine Hyperextensions': 'Гиперэкстензия в тренажёре',
    'Machine Incline Lateral Raise': 'Подъём в сторону в наклоне в тренажёре',
    'Machine Incline Rows': 'Тяга в наклоне в тренажёре',
    'Machine Lateral Raise': 'Подъём в сторону в тренажёре',
    'Machine Oblique Crunch': 'Скручивание на косые в тренажёре',
    'Machine Pec Deck': 'Бабочка в тренажёре',
    'Machine Pec Minor Fly': 'Разведение малой грудной в тренажёре',
    'Machine Pec Minor Press': 'Жим малой грудной в тренажёре',
    'Machine Pull': 'Тяга в тренажёре',
    'Machine Pullover': 'Пуловер в тренажёре',
    'Machine Rear Delt Flyes': 'Разведение задней дельты в тренажёре',
    'Machine Rear Flye': 'Обратное разведение в тренажёре',
    'Machine Reverse Flyes': 'Обратное разведение в тренажёре',
    'Machine Rhomboid Fly': 'Разведение ромбовидных в тренажёре',
    'Machine Rhomboid Flye': 'Разведение ромбовидных в тренажёре',
    'Machine Rhomboid Row': 'Тяга ромбовидных в тренажёре',
    'Machine Row': 'Тяга в тренажёре',
    'Machine Russian Twist': 'Русский твист в тренажёре',
    'Machine Seated Cable Rows': 'Горизонтальная тяга сидя',
    'Machine Shoulder Press with Lateral Emphasis': 'Жим на плечи с акцентом на бока',
    'Machine Shrugs': 'Шраги в тренажёре',
    'Machine Side Bend': 'Наклоны в стороны в тренажёре',
    'Machine Side Fly': 'Подъём в сторону в тренажёре',
    'Machine Squat': 'Приседание в тренажёре',
    'Machine Trap Pulls': 'Тяга для трапеции в тренажёре',
    'Machine Upright Row': 'Тяга к подбородку в тренажёре',
    'Machine Upright Rows': 'Тяга к подбородку в тренажёре',
    'Machine YTW Raise': 'YTW подъём в тренажёре',
    'Mountain Climber': 'Скалолаз',
    'Mountain Climbers': 'Скалолаз',
    'Neck Bridge': 'Борцовский мостик',
    'Overhead Arm Pulls': 'Тяга рук над головой',
    'Overhead Press': 'Жим над головой',
    'Overhead Tricep Extension': 'Разгибание трицепса над головой',
    'Pec Deck Machine Fly': 'Бабочка в тренажёре',
    'Pec Minor Fly': 'Разведение малой грудной',
    'Pec Minor Isometric Hold': 'Изометрическое удержание малой грудной',
    'Pec Minor Push-Up': 'Отжимание для малой грудной',
    'Pectoralis Minor Push-Up': 'Отжимание для малой грудной',
    'Plank': 'Планка',
    'Plyometric Box Jumps': 'Плиометрические прыжки на тумбу',
    'Preacher Curl': 'Сгибание Скотта',
    'Preacher Curl Machine': 'Сгибание Скотта в тренажёре',
    'Pull Up': 'Подтягивание',
    'Push Up': 'Отжимание',
    'Reverse Cable Calf Raise': 'Тяга носка в блоке',
    'Reverse Crunch Machine': 'Обратное скручивание в тренажёре',
    'Reverse Fly': 'Обратное разведение',
    'Reverse Fly (Bodyweight)': 'Обратное разведение с весом тела',
    'Reverse Flyes Against Wall': 'Обратное разведение у стены',
    'Reverse Grip Bicep Curl Machine': 'Обратное сгибание бицепса в тренажёре',
    'Reverse Lunge': 'Обратный выпад',
    'Romanian Deadlift Machine': 'Румынская тяга в тренажёре',
    'Russian Twist': 'Русский твист',
    'Russian Twists': 'Русские твисты',
    'Scapular Push-Ups': 'Отжимание лопатками',
    'Seated Cable Calf Raise': 'Подъём на носки сидя в блоке',
    'Seated Calf Raise Machine': 'Подъём на носки сидя в тренажёре',
    'Seated Dumbbell Twist': 'Скручивание сидя с гантелью',
    'Seated Machine Row': 'Тяга сидя в тренажёре',
    'Seated Machine Shoulder Press': 'Жим на плечи сидя в тренажёре',
    'Shrugs': 'Шраги',
    'Side Lateral Raise': 'Подъём в стороны',
    'Side Lateral Raises': 'Подъём в стороны',
    'Side Plank': 'Боковая планка',
    'Side Plank with Arm Raises': 'Боковая планка с подъёмом руки',
    'Side Plank with Dumbbell Raise': 'Боковая планка с гантелью',
    'Side Shuffle with Shoulder Press': 'Боковой шаг с жимом',
    'Single-Arm Kettlebell Chest Press': 'Жим гири лёжа одной рукой',
    'Single-Arm Kettlebell Row': 'Тяга гири одной рукой',
    'Single-Leg Cable Calf Raise': 'Подъём на носки на одной ноге в блоке',
    'Single-Leg Calf Raises': 'Подъём на носки на одной ноге',
    'Single-Leg Romanian Deadlift': 'Румынская тяга на одной ноге',
    'Smith Machine Squat': 'Приседание в Смите',
    'Split Stance Calf Raise Machine': 'Подъём на носки с разной постановкой',
    'Stability Ball Hamstring Curl': 'Сгибание ног на фитболе',
    'Stability Ball Shoulder Press': 'Жим на плечи на фитболе',
    'Standard Push-Up': 'Классическое отжимание',
    'Standard Push-Ups': 'Классические отжимания',
    'Standing Calf Raise Machine': 'Подъём на носки стоя в тренажёре',
    'Standing Lateral Raise': 'Подъём в стороны стоя',
    'Standing Machine Front Raise': 'Подъём перед собой стоя в тренажёре',
    'Step-Ups': 'Зашагивания',
    'Stiff-Legged Deadlift Machine': 'Тяга на прямых ногах в тренажёре',
    'Sumo Squat': 'Приседание сумо',
    'Superman Arm Pulls': 'Супермен',
    'Suspending Chin-Ups': 'Подтягивания с паузой',
    'Tricep Dips': 'Отжимания на брусьях',
    'Tricep Push-Up': 'Отжимание для трицепса',
    'Tricep Push-Up Variation': 'Отжимание для трицепса (вариация)',
    'Triceps Curl': 'Сгибание для трицепса',
    'Triceps Dip Machine': 'Отжимания на брусьях в тренажёре',
    'Triceps Extension': 'Разгибание трицепса',
    'Triceps Fly': 'Разведение трицепса',
    'Triceps Pushdown': 'Жим трицепса вниз',
    'Wall Lateral Raise': 'Подъём у стены',
    'Wall Push-Up with Arm Raise': 'Отжимание от стены с подъёмом',
    'Wall Shoulder Press': 'Жим от стены',
    'Weighted Calf Raise Machine': 'Подъём на носки с весом в тренажёре',
    'Wide Grip Pull-Up': 'Подтягивание широким хватом',
    'Wide-Grip Push Up': 'Отжимание широким хватом',
    'YTW (Y-Shape T-Shape W-Shape)': 'Упражнение YTW',
    'YTW Flyes (Bodyweight)': 'YTW разведение',
    'YTW Position': 'Позиция YTW',
    'YTW Raises': 'YTW подъём',
    'YTW Stabilization': 'YTW стабилизация',
  };

  static List<String> imageUrlsForRussianName(String ruName, {int count = 2}) {
    final lower = ruName.toLowerCase().trim();
    String? englishName;
    for (final entry in _ruNames.entries) {
      if (entry.value.toLowerCase().trim() == lower) {
        englishName = entry.key;
        break;
      }
    }
    if (englishName == null) return const [];
    final freeId = FreeExerciseDb.instance.idForName(englishName);
    if (freeId == null) return const [];
    return List.generate(count, (i) => '$_freeExDbBase/$freeId/$i.jpg');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (_nameRu != null) 'nameRu': _nameRu,
        if (description.isNotEmpty) 'description': description,
        'difficulty': difficulty.name,
        'equipment': equipment.map((e) => e.name).toList(),
        'primaryMuscles': primaryMuscles.map((e) => e.name).toList(),
        'secondaryMuscles': secondaryMuscles.map((e) => e.name).toList(),
        'instructions': instructions,
        'movementType': movementType.name,
        'tags': tags,
      };
}

// ─── Repository ───────────────────────────────────────────────────────────────

class ExerciseDatabase {
  static List<ExerciseDbModel>? _cache;

  static Future<List<ExerciseDbModel>> load() async {
    if (_cache != null) return _cache!;
    final raw =
        await rootBundle.loadString('assets/data/exercises.json');
    // Parse JSON and load free-exercise-db in parallel
    final loadFreeDb = FreeExerciseDb.instance.load();
    final list = jsonDecode(raw) as List;
    _cache = list
        .map((e) => ExerciseDbModel.fromJson(e as Map<String, dynamic>))
        .toList();
    await loadFreeDb;
    return _cache!;
  }

  static List<ExerciseDbModel> getLoaded() => _cache ?? [];

  static List<ExerciseDbModel> filterBy({
    ExMuscle? muscle,
    ExEquipment? equipment,
    ExDifficulty? difficulty,
    ExMovementType? movementType,
  }) {
    return getLoaded().where((ex) {
      if (muscle != null &&
          !ex.primaryMuscles.contains(muscle) &&
          !ex.secondaryMuscles.contains(muscle)) {
        return false;
      }
      if (equipment != null && !ex.equipment.contains(equipment)) {
        return false;
      }
      if (difficulty != null && ex.difficulty != difficulty) {
        return false;
      }
      if (movementType != null && ex.movementType != movementType) {
        return false;
      }
      return true;
    }).toList();
  }

  static ExerciseDbModel? getById(String id) {
    try {
      return getLoaded().firstWhere((ex) => ex.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─── Zone ↔ Muscle mapping ────────────────────────────────────────────────────
// Bridges MuscleMapWidget zone IDs (snake_case SVG ids) with ExMuscle enum values.

extension ExMuscleZone on ExMuscle {
  // Zone IDs match GLB material names.
  // L+R sides share ONE material name → selecting any muscle highlights both sides.
  static const _zoneMap = <String, ExMuscle>{
    'neck':                 ExMuscle.levatorScapulae,
    'upper_trapezius':      ExMuscle.trapezius,
    'middle_trapezius':     ExMuscle.trapezius,
    'lower_trapezius':      ExMuscle.trapezius,
    'anterior_deltoid':     ExMuscle.anteriorDeltoid,
    'lateral_deltoid':      ExMuscle.lateralDeltoid,
    'posterior_deltoid':    ExMuscle.posteriorDeltoid,
    'rotator_cuff':         ExMuscle.rotatorCuff,
    'pectoralis_upper':     ExMuscle.pectoralisMajor,
    'pectoralis_lower':     ExMuscle.pectoralisMajor,
    'pectoralis_minor':     ExMuscle.pectoralisMinor,
    'serratus_anterior':    ExMuscle.serratusAnterior,
    'biceps':               ExMuscle.biceps,
    'brachialis':           ExMuscle.brachialis,
    'triceps':              ExMuscle.triceps,
    'forearm_flexors':      ExMuscle.forearmFlexors,
    'rectus_abdominis':     ExMuscle.rectusAbdominis,
    'external_oblique':     ExMuscle.obliques,
    'transverse_abdominis': ExMuscle.transverseAbdominis,
    'latissimus':           ExMuscle.latissimusDorsi,
    'teres_major':          ExMuscle.rhomboids,
    'erector_spinae':       ExMuscle.erectorSpinae,
    'hip_flexors':          ExMuscle.hipFlexors,
    'adductors':            ExMuscle.adductors,
    'gluteus_medius':       ExMuscle.gluteusMedius,
    'gluteus_maximus':      ExMuscle.gluteusMaximus,
    'quadriceps':           ExMuscle.quadriceps,
    'hamstrings':           ExMuscle.hamstrings,
    'gastrocnemius':        ExMuscle.calves,
    'soleus':               ExMuscle.calves,
    'tibialis_anterior':    ExMuscle.calves,
  };

  // Zone tap → ExMuscle (for exercise filtering)
  static ExMuscle? fromZoneId(String zoneId) => _zoneMap[zoneId];

  // ExMuscle → all zone IDs that belong to it (for anatomy highlighting)
  static List<String> zoneIdsFor(ExMuscle muscle) => _zoneMap.entries
      .where((e) => e.value == muscle)
      .map((e) => e.key)
      .toList();

  String get displayNameRu => const <ExMuscle, String>{
    ExMuscle.pectoralisMajor:     'Грудные (большая)',
    ExMuscle.pectoralisMinor:     'Грудные (малая)',
    ExMuscle.latissimusDorsi:     'Широчайшие',
    ExMuscle.rhomboids:           'Ромбовидные',
    ExMuscle.trapezius:           'Трапеция',
    ExMuscle.anteriorDeltoid:     'Дельта передняя',
    ExMuscle.lateralDeltoid:      'Дельта средняя',
    ExMuscle.posteriorDeltoid:    'Дельта задняя',
    ExMuscle.biceps:              'Бицепс',
    ExMuscle.triceps:             'Трицепс',
    ExMuscle.quadriceps:          'Квадрицепс',
    ExMuscle.hamstrings:          'Задняя бедра',
    ExMuscle.gluteusMaximus:      'Ягодичная',
    ExMuscle.calves:              'Икроножная',
    ExMuscle.rectusAbdominis:     'Пресс',
    ExMuscle.obliques:            'Косые мышцы',
    ExMuscle.erectorSpinae:       'Разгибатели спины',
    ExMuscle.transverseAbdominis: 'Поперечный пресс',
    ExMuscle.brachialis:          'Плечевая мышца',
    ExMuscle.hipFlexors:          'Сгибатели бедра',
    ExMuscle.forearmFlexors:      'Предплечье',
    ExMuscle.adductors:           'Приводящие',
    ExMuscle.rotatorCuff:         'Вращательная манжета',
    ExMuscle.serratusAnterior:    'Передняя зубчатая',
    ExMuscle.levatorScapulae:     'Шея / лопатка',
    ExMuscle.gluteusMedius:       'Ягодичная средняя',
  }[this]!;
}
