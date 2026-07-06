// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HealthDataImpl _$$HealthDataImplFromJson(Map<String, dynamic> json) =>
    _$HealthDataImpl(
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      steps: (json['steps'] as num?)?.toInt(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble(),
      heartRateAvg: (json['heartRateAvg'] as num?)?.toInt(),
      heartRateResting: (json['heartRateResting'] as num?)?.toInt(),
      heartRateVariability: (json['heartRateVariability'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt(),
      waterIntakeMl: (json['waterIntakeMl'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$HealthDataImplToJson(_$HealthDataImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'date': instance.date.toIso8601String(),
      'steps': instance.steps,
      'caloriesBurned': instance.caloriesBurned,
      'heartRateAvg': instance.heartRateAvg,
      'heartRateResting': instance.heartRateResting,
      'heartRateVariability': instance.heartRateVariability,
      'weight': instance.weight,
      'bodyFatPercent': instance.bodyFatPercent,
      'sleepMinutes': instance.sleepMinutes,
      'waterIntakeMl': instance.waterIntakeMl,
      'distanceKm': instance.distanceKm,
    };

_$ProgressEntryImpl _$$ProgressEntryImplFromJson(Map<String, dynamic> json) =>
    _$ProgressEntryImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num?)?.toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      measurements: (json['measurements'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$ProgressEntryImplToJson(_$ProgressEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date.toIso8601String(),
      'weight': instance.weight,
      'bodyFatPercent': instance.bodyFatPercent,
      'measurements': instance.measurements,
      'photoUrl': instance.photoUrl,
      'notes': instance.notes,
    };
