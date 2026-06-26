import 'dart:convert';

class PersonalRecord {
  final String id;
  final String exerciseName;
  final double? weightKg;
  final int? reps;
  final int? sets;
  final DateTime date;
  final String notes;

  const PersonalRecord({
    required this.id,
    required this.exerciseName,
    this.weightKg,
    this.reps,
    this.sets,
    required this.date,
    this.notes = '',
  });

  bool get isBodyweight => weightKg == null || weightKg == 0;

  // Volume score for comparing records: weight × reps (bodyweight = reps only)
  double get score {
    final w = weightKg ?? 1.0;
    final r = reps ?? 0;
    return w * r;
  }

  String get displayWeight => weightKg != null && weightKg! > 0
      ? '${weightKg!.toStringAsFixed(weightKg! % 1 == 0 ? 0 : 1)} кг'
      : 'б/в';

  String get displayReps => reps != null ? '$reps повт' : '—';

  String get displaySets => sets != null ? '$sets×' : '';

  String get summary {
    final parts = <String>[];
    if (sets != null) parts.add('$sets×');
    if (reps != null) parts.add('$reps повт');
    if (weightKg != null && weightKg! > 0) parts.add('@ $displayWeight');
    return parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseName': exerciseName,
    'weightKg': weightKg,
    'reps': reps,
    'sets': sets,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory PersonalRecord.fromJson(Map<String, dynamic> j) => PersonalRecord(
    id: j['id'] as String,
    exerciseName: j['exerciseName'] as String,
    weightKg: (j['weightKg'] as num?)?.toDouble(),
    reps: (j['reps'] as num?)?.toInt(),
    sets: (j['sets'] as num?)?.toInt(),
    date: DateTime.parse(j['date'] as String),
    notes: j['notes'] as String? ?? '',
  );

  static String encodeList(List<PersonalRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  static List<PersonalRecord> decodeList(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
