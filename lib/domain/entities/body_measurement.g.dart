// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BodyMeasurementImpl _$$BodyMeasurementImplFromJson(
        Map<String, dynamic> json) =>
    _$BodyMeasurementImpl(
      date: _dateFromMillis(json['date']),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      hipsCm: (json['hipsCm'] as num?)?.toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$BodyMeasurementImplToJson(
        _$BodyMeasurementImpl instance) =>
    <String, dynamic>{
      'date': _dateToMillis(instance.date),
      'chestCm': instance.chestCm,
      'waistCm': instance.waistCm,
      'hipsCm': instance.hipsCm,
      'bodyFatPercent': instance.bodyFatPercent,
    };
