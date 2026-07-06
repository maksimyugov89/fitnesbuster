import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_entities.freezed.dart';
part 'health_entities.g.dart';

@freezed
class HealthData with _$HealthData {
  const factory HealthData({
    required String userId,
    required DateTime date,
    int? steps,
    double? caloriesBurned,
    int? heartRateAvg,
    int? heartRateResting,
    double? heartRateVariability,
    double? weight,
    double? bodyFatPercent,
    int? sleepMinutes,
    double? waterIntakeMl,
    double? distanceKm,
  }) = _HealthData;

  factory HealthData.fromJson(Map<String, dynamic> json) =>
      _$HealthDataFromJson(json);
}

@freezed
class ProgressEntry with _$ProgressEntry {
  const factory ProgressEntry({
    required String id,
    required String userId,
    required DateTime date,
    double? weight,
    double? bodyFatPercent,
    Map<String, double>? measurements,
    String? photoUrl,
    String? notes,
  }) = _ProgressEntry;

  factory ProgressEntry.fromJson(Map<String, dynamic> json) =>
      _$ProgressEntryFromJson(json);
}
