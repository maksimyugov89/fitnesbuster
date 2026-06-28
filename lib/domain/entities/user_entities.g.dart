// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserEntityImpl _$$UserEntityImplFromJson(Map<String, dynamic> json) =>
    _$UserEntityImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      profile: json['profile'] == null
          ? null
          : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$UserEntityImplToJson(_$UserEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'profile': instance.profile,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      age: (json['age'] as num).toInt(),
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      goal: $enumDecode(_$FitnessGoalEnumMap, json['goal']),
      intensity: $enumDecode(_$IntensityLevelEnumMap, json['intensity']),
      medicalRestrictions: (json['medicalRestrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      exerciseRestrictions: (json['exerciseRestrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      activityLevel: $enumDecode(_$ActivityLevelEnumMap, json['activityLevel']),
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String),
      testWeekCompleted: json['testWeekCompleted'] as bool? ?? false,
      testResults: (json['testResults'] as List<dynamic>?)
              ?.map(
                  (e) => TestExerciseResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      workoutLocation: json['workoutLocation'] as String?,
      runningPreference: json['runningPreference'] as String?,
      city: json['city'] as String?,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'weight': instance.weight,
      'height': instance.height,
      'age': instance.age,
      'gender': _$GenderEnumMap[instance.gender]!,
      'goal': _$FitnessGoalEnumMap[instance.goal]!,
      'intensity': _$IntensityLevelEnumMap[instance.intensity]!,
      'medicalRestrictions': instance.medicalRestrictions,
      'exerciseRestrictions': instance.exerciseRestrictions,
      'activityLevel': _$ActivityLevelEnumMap[instance.activityLevel]!,
      'targetWeight': instance.targetWeight,
      'targetDate': instance.targetDate?.toIso8601String(),
      'testWeekCompleted': instance.testWeekCompleted,
      'testResults': instance.testResults,
      'workoutLocation': instance.workoutLocation,
      'runningPreference': instance.runningPreference,
      'city': instance.city,
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
};

const _$FitnessGoalEnumMap = {
  FitnessGoal.loseWeight: 'loseWeight',
  FitnessGoal.gainWeight: 'gainWeight',
  FitnessGoal.maintain: 'maintain',
  FitnessGoal.beachBody: 'beachBody',
  FitnessGoal.sportPerformance: 'sportPerformance',
};

const _$IntensityLevelEnumMap = {
  IntensityLevel.hardcore: 'hardcore',
  IntensityLevel.intensive: 'intensive',
  IntensityLevel.balanced: 'balanced',
  IntensityLevel.gradual: 'gradual',
  IntensityLevel.relaxed: 'relaxed',
};

const _$ActivityLevelEnumMap = {
  ActivityLevel.sedentary: 'sedentary',
  ActivityLevel.lightlyActive: 'lightlyActive',
  ActivityLevel.moderatelyActive: 'moderatelyActive',
  ActivityLevel.veryActive: 'veryActive',
  ActivityLevel.extraActive: 'extraActive',
};

_$TestExerciseResultImpl _$$TestExerciseResultImplFromJson(
        Map<String, dynamic> json) =>
    _$TestExerciseResultImpl(
      exerciseName: json['exerciseName'] as String,
      primaryMuscle: $enumDecode(_$MuscleGroupEnumMap, json['primaryMuscle']),
      comfortableWeightKg: (json['comfortableWeightKg'] as num).toDouble(),
      comfortableSets: (json['comfortableSets'] as num).toInt(),
      comfortableReps: (json['comfortableReps'] as num).toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$TestExerciseResultImplToJson(
        _$TestExerciseResultImpl instance) =>
    <String, dynamic>{
      'exerciseName': instance.exerciseName,
      'primaryMuscle': _$MuscleGroupEnumMap[instance.primaryMuscle]!,
      'comfortableWeightKg': instance.comfortableWeightKg,
      'comfortableSets': instance.comfortableSets,
      'comfortableReps': instance.comfortableReps,
      'notes': instance.notes,
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
