import 'dart:convert';

String? _safeString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return null;
}

String _safeStringOrList(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is List) return v.map((e) => e.toString()).join(', ');
  return '';
}

class WorkoutExercise {
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  // Block 5 — rich AI fields (all optional, backward-compatible)
  final String musclePrimary;
  final String muscleSecondary;
  final String weightGuideline;
  final int rpe;
  final String tempo;
  final String techniqueCue;
  final String progression;

  const WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.musclePrimary = '',
    this.muscleSecondary = '',
    this.weightGuideline = '',
    this.rpe = 0,
    this.tempo = '',
    this.techniqueCue = '',
    this.progression = '',
  });

  bool get isTimedReps {
    final l = reps.toLowerCase();
    return l.contains('сек') ||
        l.contains('sec') ||
        l.contains('мин') ||
        l.contains('min');
  }

  int get durationSeconds {
    final l = reps.toLowerCase();
    final firstNum =
        int.tryParse(RegExp(r'\d+').firstMatch(l)?.group(0) ?? '') ?? 30;
    if (l.contains('мин') || l.contains('min')) {
      return firstNum * 60;
    }
    return firstNum;
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
    name: j['name'] as String? ?? 'Упражнение',
    sets: (j['sets'] as num?)?.toInt() ?? 3,
    reps: j['reps']?.toString() ?? '10',
    restSeconds: (j['rest_seconds'] as num?)?.toInt() ?? 60,
    musclePrimary:
        _safeString(j['muscle_primary']) ??
        _safeString(j['muscle_group']) ??
        '',
    muscleSecondary: _safeStringOrList(j['muscle_secondary']),
    weightGuideline: _safeString(j['weight_guideline']) ?? '',
    rpe: (j['rpe'] as num?)?.toInt() ?? 0,
    tempo: _safeString(j['tempo']) ?? '',
    techniqueCue:
        _safeString(j['technique_cue']) ??
        _safeString(j['technique_tip']) ??
        '',
    progression: _safeString(j['progression']) ?? '',
  );
}

class WorkoutDay {
  final int day;
  final String focus;
  final List<WorkoutExercise> exercises;
  final int cardioMinutes;
  final String notes;
  // Block 5 — rich AI fields (all optional, backward-compatible)
  final String name;
  final String type;
  final int durationMinutes;
  final List<String> warmup;
  final List<String> cooldown;
  final int estimatedCaloriesBurned;

  const WorkoutDay({
    required this.day,
    required this.focus,
    required this.exercises,
    this.cardioMinutes = 0,
    this.notes = '',
    this.name = '',
    this.type = '',
    this.durationMinutes = 0,
    this.warmup = const [],
    this.cooldown = const [],
    this.estimatedCaloriesBurned = 0,
  });

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets);

  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
    day: (j['day'] as num?)?.toInt() ?? 1,
    focus: j['focus'] as String? ?? j['name'] as String? ?? '',
    exercises:
        (j['exercises'] as List<dynamic>?)
            ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    cardioMinutes: (j['cardio_minutes'] as num?)?.toInt() ?? 0,
    notes: j['notes'] as String? ?? '',
    name: j['name'] as String? ?? j['focus'] as String? ?? '',
    type: j['type'] as String? ?? '',
    durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 0,
    warmup:
        (j['warmup'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [],
    cooldown:
        (j['cooldown'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [],
    estimatedCaloriesBurned:
        (j['estimated_calories_burned'] as num?)?.toInt() ?? 0,
  );

  static WorkoutDay? todayFromPlanJson(String planJson) {
    try {
      final decoded = jsonDecode(planJson) as Map<String, dynamic>;
      final plan = decoded['plan'] as List<dynamic>?;
      if (plan == null || plan.isEmpty) return null;
      final todayWeekday = DateTime.now().weekday;
      WorkoutDay? match;
      WorkoutDay? first;
      for (final item in plan) {
        final d = WorkoutDay.fromJson(item as Map<String, dynamic>);
        first ??= d;
        if (d.day == todayWeekday) {
          match = d;
          break;
        }
      }
      return match ?? first;
    } catch (_) {
      return null;
    }
  }
}

class WorkoutPlanMeta {
  final int weekNumber;
  final String phase;
  final int weeklyVolumeSets;
  final String weeklySummary;
  final List<String> recommendations;
  final String nextWeekPreview;

  const WorkoutPlanMeta({
    this.weekNumber = 1,
    this.phase = '',
    this.weeklyVolumeSets = 0,
    this.weeklySummary = '',
    this.recommendations = const [],
    this.nextWeekPreview = '',
  });

  factory WorkoutPlanMeta.fromJson(Map<String, dynamic> j) => WorkoutPlanMeta(
    weekNumber: (j['week_number'] as num?)?.toInt() ?? 1,
    phase: _safeString(j['phase']) ?? '',
    weeklyVolumeSets: (j['weekly_volume_sets'] as num?)?.toInt() ?? 0,
    weeklySummary: _safeString(j['weekly_summary']) ?? '',
    recommendations:
        (j['recommendations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    nextWeekPreview: _safeString(j['next_week_preview']) ?? '',
  );

  static String? _safeString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return null;
  }

  static WorkoutPlanMeta fromPlanJson(Map<String, dynamic> data) {
    final meta = data['meta'] as Map<String, dynamic>?;
    return WorkoutPlanMeta(
      weekNumber:
          (data['week_number'] as num?)?.toInt() ??
          (meta?['week_number'] as num?)?.toInt() ??
          1,
      phase: _safeString(data['phase']) ?? _safeString(meta?['phase']) ?? '',
      weeklyVolumeSets:
          (data['weekly_volume_sets'] as num?)?.toInt() ??
          (meta?['weekly_volume_sets'] as num?)?.toInt() ??
          0,
      weeklySummary:
          _safeString(data['weekly_summary']) ??
          _safeString(meta?['weekly_summary']) ??
          '',
      recommendations:
          (data['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nextWeekPreview:
          _safeString(data['next_week_preview']) ??
          _safeString(meta?['next_week_preview']) ??
          '',
    );
  }
}
