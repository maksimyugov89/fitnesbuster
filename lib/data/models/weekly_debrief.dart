import 'dart:convert';

class WeeklyDebrief {
  final int overallScore; // 1–10
  final int workoutAdherence; // 0–100 (процент выполненных тренировок)
  final String workoutSummary; // 1–2 предложения о тренировках недели
  final String nutritionSummary; // 1–2 предложения о питании
  final List<String> highlights; // 2–4 достижения (зелёные)
  final List<String> improvements; // 2–3 области роста (оранжевые)
  final String nextWeekFocus; // 1 предложение — фокус следующей недели
  final List<String> recoveryTips; // 1–2 совета по восстановлению
  final DateTime generatedAt;

  const WeeklyDebrief({
    required this.overallScore,
    required this.workoutAdherence,
    required this.workoutSummary,
    required this.nutritionSummary,
    required this.highlights,
    required this.improvements,
    required this.nextWeekFocus,
    required this.recoveryTips,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'overall_score': overallScore,
    'workout_adherence': workoutAdherence,
    'workout_summary': workoutSummary,
    'nutrition_summary': nutritionSummary,
    'highlights': highlights,
    'improvements': improvements,
    'next_week_focus': nextWeekFocus,
    'recovery_tips': recoveryTips,
    'generated_at': generatedAt.toIso8601String(),
  };

  factory WeeklyDebrief.fromJson(Map<String, dynamic> j) => WeeklyDebrief(
    overallScore: (j['overall_score'] as num?)?.toInt() ?? 5,
    workoutAdherence: (j['workout_adherence'] as num?)?.toInt() ?? 0,
    workoutSummary: j['workout_summary'] as String? ?? '',
    nutritionSummary: j['nutrition_summary'] as String? ?? '',
    highlights: _toStrList(j['highlights']),
    improvements: _toStrList(j['improvements']),
    nextWeekFocus: j['next_week_focus'] as String? ?? '',
    recoveryTips: _toStrList(j['recovery_tips']),
    generatedAt: j['generated_at'] != null
        ? DateTime.parse(j['generated_at'] as String)
        : DateTime.now(),
  );

  static List<String> _toStrList(dynamic v) =>
      (v as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  static String encode(WeeklyDebrief d) => jsonEncode(d.toJson());
  static WeeklyDebrief decode(String raw) =>
      WeeklyDebrief.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
