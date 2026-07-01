import 'package:freezed_annotation/freezed_annotation.dart';

part 'body_measurement.freezed.dart';
part 'body_measurement.g.dart';

DateTime _dateFromMillis(dynamic value) {
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.parse(value as String);
}

int _dateToMillis(DateTime date) => date.millisecondsSinceEpoch;

@freezed
class BodyMeasurement with _$BodyMeasurement {
  const BodyMeasurement._();

  const factory BodyMeasurement({
    @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis)
    required DateTime date,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bodyFatPercent,
  }) = _BodyMeasurement;

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      _$BodyMeasurementFromJson(json);

  bool get hasData =>
      chestCm != null ||
      waistCm != null ||
      hipsCm != null ||
      bodyFatPercent != null;

  Map<String, dynamic> toMap() => toJson();

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) =>
      BodyMeasurement.fromJson(map);
}
