import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'personal_record.freezed.dart';
part 'personal_record.g.dart';

@freezed
class PersonalRecord with _$PersonalRecord {
  const PersonalRecord._();

  const factory PersonalRecord({
    required String id,
    required String exerciseName,
    double? weightKg,
    int? reps,
    int? sets,
    required DateTime date,
    @Default('') String notes,
  }) = _PersonalRecord;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => _$PersonalRecordFromJson(json);

  bool get isBodyweight => weightKg == null || weightKg == 0;

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
