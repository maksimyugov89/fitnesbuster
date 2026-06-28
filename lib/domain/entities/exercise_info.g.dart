// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseInfoImpl _$$ExerciseInfoImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseInfoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String?,
      gifUrl: json['gifUrl'] as String?,
    );

Map<String, dynamic> _$$ExerciseInfoImplToJson(_$ExerciseInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'muscleGroup': instance.muscleGroup,
      'gifUrl': instance.gifUrl,
    };
