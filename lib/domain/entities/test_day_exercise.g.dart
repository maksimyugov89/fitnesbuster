// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_day_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TestDayExerciseImpl _$$TestDayExerciseImplFromJson(
        Map<String, dynamic> json) =>
    _$TestDayExerciseImpl(
      name: json['name'] as String,
      muscle: $enumDecode(_$MuscleGroupEnumMap, json['muscle']),
      baseWeight: (json['baseWeight'] as num).toDouble(),
    );

Map<String, dynamic> _$$TestDayExerciseImplToJson(
        _$TestDayExerciseImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'muscle': _$MuscleGroupEnumMap[instance.muscle]!,
      'baseWeight': instance.baseWeight,
    };

const _$MuscleGroupEnumMap = {
  MuscleGroup.chest: 'chest',
  MuscleGroup.back: 'back',
  MuscleGroup.shoulders: 'shoulders',
  MuscleGroup.biceps: 'biceps',
  MuscleGroup.triceps: 'triceps',
  MuscleGroup.forearms: 'forearms',
  MuscleGroup.abs: 'abs',
  MuscleGroup.glutes: 'glutes',
  MuscleGroup.quads: 'quads',
  MuscleGroup.hamstrings: 'hamstrings',
  MuscleGroup.calves: 'calves',
  MuscleGroup.fullBody: 'fullBody',
  MuscleGroup.cardio: 'cardio',
};
