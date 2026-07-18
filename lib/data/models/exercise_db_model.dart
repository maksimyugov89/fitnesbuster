import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/data/models/free_exercise_db.dart';
import 'package:fitnesbuster/data/models/exercise_localization.dart';
import 'package:fitnesbuster/domain/entities/exercise_info.dart';

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
      movementType: ExMovementType.fromJson(
        json['movementType'] as String? ?? '',
      ),
      tags: ((json['tags'] as List?) ?? []).map((e) => e as String).toList(),
      exerciseDbId: json['exerciseDbId'] as String?,
    );
  }

  /// GIF URL served from Firebase Hosting (immutable CDN, no API key needed).
  String? get gifUrl {
    if (exerciseDbId == null) return null;
    return 'https://fitnesbuster.web.app/gifs/$exerciseDbId.gif';
  }

  /// Russian display name: JSON value → asset map → English fallback.
  String get nameRu =>
      _nameRu ?? ExerciseLocalization.instance.translate(name) ?? name;

  /// Keeps the Russian catalog used by AI prompts separate from the name shown
  /// in the UI.  Until a locale-specific exercise catalog is available, every
  /// non-Russian locale receives the canonical English exercise name.
  String displayNameForLocale(String localeCode) =>
      localeCode == 'ru' ? nameRu : name;

  ExerciseInfo toExerciseInfo() => ExerciseInfo(
    id: id,
    name: name,
    muscleGroup: primaryMuscles.isNotEmpty ? primaryMuscles.first.name : null,
    gifUrl: gifUrl,
  );

  static const String _freeExDbBase =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

  /// Returns [count] image URLs from free-exercise-db matched by English name.
  /// Returns empty list if no match found.
  List<String> freeDbImageUrls({int count = 2}) {
    final freeId = FreeExerciseDb.instance.idForName(name);
    if (freeId == null) return const [];
    return List.generate(count, (i) => '$_freeExDbBase/$freeId/$i.jpg');
  }

  static List<String> imageUrlsForRussianName(String ruName, {int count = 2}) {
    final lower = ruName.toLowerCase().trim();
    String? englishName;
    for (final entry in ExerciseLocalization.instance.all.entries) {
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
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final loadFreeDb = FreeExerciseDb.instance.load();
    final loadLocalization = ExerciseLocalization.instance.init();
    final list = jsonDecode(raw) as List;
    _cache = list
        .map((e) => ExerciseDbModel.fromJson(e as Map<String, dynamic>))
        .toList();
    await loadFreeDb;
    await loadLocalization;
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
    'neck': ExMuscle.levatorScapulae,
    'upper_trapezius': ExMuscle.trapezius,
    'middle_trapezius': ExMuscle.trapezius,
    'lower_trapezius': ExMuscle.trapezius,
    'anterior_deltoid': ExMuscle.anteriorDeltoid,
    'lateral_deltoid': ExMuscle.lateralDeltoid,
    'posterior_deltoid': ExMuscle.posteriorDeltoid,
    'rotator_cuff': ExMuscle.rotatorCuff,
    'pectoralis_upper': ExMuscle.pectoralisMajor,
    'pectoralis_lower': ExMuscle.pectoralisMajor,
    'pectoralis_minor': ExMuscle.pectoralisMinor,
    'serratus_anterior': ExMuscle.serratusAnterior,
    'biceps': ExMuscle.biceps,
    'brachialis': ExMuscle.brachialis,
    'triceps': ExMuscle.triceps,
    'forearm_flexors': ExMuscle.forearmFlexors,
    'rectus_abdominis': ExMuscle.rectusAbdominis,
    'external_oblique': ExMuscle.obliques,
    'transverse_abdominis': ExMuscle.transverseAbdominis,
    'latissimus': ExMuscle.latissimusDorsi,
    'teres_major': ExMuscle.rhomboids,
    'erector_spinae': ExMuscle.erectorSpinae,
    'hip_flexors': ExMuscle.hipFlexors,
    'adductors': ExMuscle.adductors,
    'gluteus_medius': ExMuscle.gluteusMedius,
    'gluteus_maximus': ExMuscle.gluteusMaximus,
    'quadriceps': ExMuscle.quadriceps,
    'hamstrings': ExMuscle.hamstrings,
    'gastrocnemius': ExMuscle.calves,
    'soleus': ExMuscle.calves,
    'tibialis_anterior': ExMuscle.calves,
  };

  // Zone tap → ExMuscle (for exercise filtering)
  static ExMuscle? fromZoneId(String zoneId) => _zoneMap[zoneId];

  // ExMuscle → all zone IDs that belong to it (for anatomy highlighting)
  static List<String> zoneIdsFor(ExMuscle muscle) => _zoneMap.entries
      .where((e) => e.value == muscle)
      .map((e) => e.key)
      .toList();

  String get displayNameRu => const <ExMuscle, String>{
    ExMuscle.pectoralisMajor: 'Грудные (большая)',
    ExMuscle.pectoralisMinor: 'Грудные (малая)',
    ExMuscle.latissimusDorsi: 'Широчайшие',
    ExMuscle.rhomboids: 'Ромбовидные',
    ExMuscle.trapezius: 'Трапеция',
    ExMuscle.anteriorDeltoid: 'Дельта передняя',
    ExMuscle.lateralDeltoid: 'Дельта средняя',
    ExMuscle.posteriorDeltoid: 'Дельта задняя',
    ExMuscle.biceps: 'Бицепс',
    ExMuscle.triceps: 'Трицепс',
    ExMuscle.quadriceps: 'Квадрицепс',
    ExMuscle.hamstrings: 'Задняя бедра',
    ExMuscle.gluteusMaximus: 'Ягодичная',
    ExMuscle.calves: 'Икроножная',
    ExMuscle.rectusAbdominis: 'Пресс',
    ExMuscle.obliques: 'Косые мышцы',
    ExMuscle.erectorSpinae: 'Разгибатели спины',
    ExMuscle.transverseAbdominis: 'Поперечный пресс',
    ExMuscle.brachialis: 'Плечевая мышца',
    ExMuscle.hipFlexors: 'Сгибатели бедра',
    ExMuscle.forearmFlexors: 'Предплечье',
    ExMuscle.adductors: 'Приводящие',
    ExMuscle.rotatorCuff: 'Вращательная манжета',
    ExMuscle.serratusAnterior: 'Передняя зубчатая',
    ExMuscle.levatorScapulae: 'Шея / лопатка',
    ExMuscle.gluteusMedius: 'Ягодичная средняя',
  }[this]!;

  String displayNameForLocale(String localeCode) =>
      localeCode == 'ru' ? displayNameRu : displayNameEn;

  String get displayNameEn => const <ExMuscle, String>{
    ExMuscle.pectoralisMajor: 'Pectoralis major',
    ExMuscle.pectoralisMinor: 'Pectoralis minor',
    ExMuscle.latissimusDorsi: 'Latissimus dorsi',
    ExMuscle.rhomboids: 'Rhomboids',
    ExMuscle.trapezius: 'Trapezius',
    ExMuscle.anteriorDeltoid: 'Anterior deltoid',
    ExMuscle.lateralDeltoid: 'Lateral deltoid',
    ExMuscle.posteriorDeltoid: 'Posterior deltoid',
    ExMuscle.biceps: 'Biceps',
    ExMuscle.triceps: 'Triceps',
    ExMuscle.quadriceps: 'Quadriceps',
    ExMuscle.hamstrings: 'Hamstrings',
    ExMuscle.gluteusMaximus: 'Gluteus maximus',
    ExMuscle.calves: 'Calves',
    ExMuscle.rectusAbdominis: 'Rectus abdominis',
    ExMuscle.obliques: 'Obliques',
    ExMuscle.erectorSpinae: 'Erector spinae',
    ExMuscle.transverseAbdominis: 'Transverse abdominis',
    ExMuscle.brachialis: 'Brachialis',
    ExMuscle.hipFlexors: 'Hip flexors',
    ExMuscle.forearmFlexors: 'Forearm flexors',
    ExMuscle.adductors: 'Adductors',
    ExMuscle.rotatorCuff: 'Rotator cuff',
    ExMuscle.serratusAnterior: 'Serratus anterior',
    ExMuscle.levatorScapulae: 'Levator scapulae',
    ExMuscle.gluteusMedius: 'Gluteus medius',
  }[this]!;
}
