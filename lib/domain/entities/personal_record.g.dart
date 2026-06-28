// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonalRecordImpl _$$PersonalRecordImplFromJson(Map<String, dynamic> json) =>
    _$PersonalRecordImpl(
      id: json['id'] as String,
      exerciseName: json['exerciseName'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      sets: (json['sets'] as num?)?.toInt(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$$PersonalRecordImplToJson(
        _$PersonalRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseName': instance.exerciseName,
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'sets': instance.sets,
      'date': instance.date.toIso8601String(),
      'notes': instance.notes,
    };
