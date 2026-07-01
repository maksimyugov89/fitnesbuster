// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TestWeekResultImpl _$$TestWeekResultImplFromJson(Map<String, dynamic> json) =>
    _$TestWeekResultImpl(
      completedAt: DateTime.parse(json['completedAt'] as String),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => TestExerciseResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageHeartRate: (json['averageHeartRate'] as num?)?.toDouble() ?? 0,
      averageSessionDuration:
          (json['averageSessionDuration'] as num?)?.toInt() ?? 0,
      perceivedDifficulty: (json['perceivedDifficulty'] as num?)?.toInt() ?? 5,
      feedback: json['feedback'] as String?,
    );

Map<String, dynamic> _$$TestWeekResultImplToJson(
  _$TestWeekResultImpl instance,
) => <String, dynamic>{
  'completedAt': instance.completedAt.toIso8601String(),
  'exercises': instance.exercises,
  'averageHeartRate': instance.averageHeartRate,
  'averageSessionDuration': instance.averageSessionDuration,
  'perceivedDifficulty': instance.perceivedDifficulty,
  'feedback': instance.feedback,
};

_$WorkoutPlanImpl _$$WorkoutPlanImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutPlanImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      goal: $enumDecode(_$FitnessGoalEnumMap, json['goal']),
      intensity: $enumDecode(_$IntensityLevelEnumMap, json['intensity']),
      durationWeeks: (json['durationWeeks'] as num).toInt(),
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => WorkoutWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      startDate: DateTime.parse(json['startDate'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      status:
          $enumDecodeNullable(_$WorkoutPlanStatusEnumMap, json['status']) ??
          WorkoutPlanStatus.active,
    );

Map<String, dynamic> _$$WorkoutPlanImplToJson(_$WorkoutPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'goal': _$FitnessGoalEnumMap[instance.goal]!,
      'intensity': _$IntensityLevelEnumMap[instance.intensity]!,
      'durationWeeks': instance.durationWeeks,
      'weeks': instance.weeks,
      'startDate': instance.startDate.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'status': _$WorkoutPlanStatusEnumMap[instance.status]!,
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

const _$WorkoutPlanStatusEnumMap = {
  WorkoutPlanStatus.active: 'active',
  WorkoutPlanStatus.completed: 'completed',
  WorkoutPlanStatus.paused: 'paused',
};

_$WorkoutWeekImpl _$$WorkoutWeekImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutWeekImpl(
      weekNumber: (json['weekNumber'] as num).toInt(),
      days: (json['days'] as List<dynamic>)
          .map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklyFocus: json['weeklyFocus'] as String?,
    );

Map<String, dynamic> _$$WorkoutWeekImplToJson(_$WorkoutWeekImpl instance) =>
    <String, dynamic>{
      'weekNumber': instance.weekNumber,
      'days': instance.days,
      'weeklyFocus': instance.weeklyFocus,
    };

_$WorkoutDayImpl _$$WorkoutDayImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutDayImpl(
      dayNumber: (json['dayNumber'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      type: $enumDecode(_$WorkoutDayTypeEnumMap, json['type']),
      session: json['session'] == null
          ? null
          : WorkoutSession.fromJson(json['session'] as Map<String, dynamic>),
      log: json['log'] == null
          ? null
          : WorkoutLog.fromJson(json['log'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$WorkoutDayImplToJson(_$WorkoutDayImpl instance) =>
    <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'date': instance.date.toIso8601String(),
      'type': _$WorkoutDayTypeEnumMap[instance.type]!,
      'session': instance.session,
      'log': instance.log,
    };

const _$WorkoutDayTypeEnumMap = {
  WorkoutDayType.workout: 'workout',
  WorkoutDayType.rest: 'rest',
  WorkoutDayType.activeRecovery: 'activeRecovery',
  WorkoutDayType.cardio: 'cardio',
};

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      primaryMuscle: $enumDecode(_$MuscleGroupEnumMap, json['primaryMuscle']),
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
              .toList() ??
          const [],
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num)
          .toInt(),
      estimatedCaloriesBurn: (json['estimatedCaloriesBurn'] as num).toInt(),
      difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
  _$WorkoutSessionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'primaryMuscle': _$MuscleGroupEnumMap[instance.primaryMuscle]!,
  'secondaryMuscles': instance.secondaryMuscles
      .map((e) => _$MuscleGroupEnumMap[e]!)
      .toList(),
  'exercises': instance.exercises,
  'estimatedDurationMinutes': instance.estimatedDurationMinutes,
  'estimatedCaloriesBurn': instance.estimatedCaloriesBurn,
  'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
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

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.advanced: 'advanced',
  DifficultyLevel.elite: 'elite',
};

_$ExerciseSetImpl _$$ExerciseSetImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseSetImpl(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      sets: (json['sets'] as List<dynamic>)
          .map((e) => SetData.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 60,
    );

Map<String, dynamic> _$$ExerciseSetImplToJson(_$ExerciseSetImpl instance) =>
    <String, dynamic>{
      'exercise': instance.exercise,
      'sets': instance.sets,
      'notes': instance.notes,
      'restSeconds': instance.restSeconds,
    };

_$SetDataImpl _$$SetDataImplFromJson(Map<String, dynamic> json) =>
    _$SetDataImpl(
      setNumber: (json['setNumber'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      completed: json['completed'] as bool?,
      actualWeight: (json['actualWeight'] as num?)?.toDouble(),
      actualReps: (json['actualReps'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SetDataImplToJson(_$SetDataImpl instance) =>
    <String, dynamic>{
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'weightKg': instance.weightKg,
      'durationSeconds': instance.durationSeconds,
      'completed': instance.completed,
      'actualWeight': instance.actualWeight,
      'actualReps': instance.actualReps,
    };

_$ExerciseImpl _$$ExerciseImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      primaryMuscle: $enumDecode(_$MuscleGroupEnumMap, json['primaryMuscle']),
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
              .toList() ??
          const [],
      type: $enumDecode(_$ExerciseTypeEnumMap, json['type']),
      equipment:
          (json['equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
      instructions: (json['instructions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      contraindications: (json['contraindications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$ExerciseImplToJson(_$ExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'videoUrl': instance.videoUrl,
      'imageUrl': instance.imageUrl,
      'primaryMuscle': _$MuscleGroupEnumMap[instance.primaryMuscle]!,
      'secondaryMuscles': instance.secondaryMuscles
          .map((e) => _$MuscleGroupEnumMap[e]!)
          .toList(),
      'type': _$ExerciseTypeEnumMap[instance.type]!,
      'equipment': instance.equipment,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'instructions': instance.instructions,
      'contraindications': instance.contraindications,
    };

const _$ExerciseTypeEnumMap = {
  ExerciseType.strength: 'strength',
  ExerciseType.cardio: 'cardio',
  ExerciseType.flexibility: 'flexibility',
  ExerciseType.balance: 'balance',
  ExerciseType.hiit: 'hiit',
  ExerciseType.yoga: 'yoga',
};

_$WorkoutLogImpl _$$WorkoutLogImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutLogImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      exerciseLogs: (json['exerciseLogs'] as List<dynamic>)
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble(),
      heartRateAvg: (json['heartRateAvg'] as num?)?.toInt(),
      heartRateMax: (json['heartRateMax'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      mood: (json['mood'] as num?)?.toInt(),
      perceivedEffort: (json['perceivedEffort'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$WorkoutLogImplToJson(_$WorkoutLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'exerciseLogs': instance.exerciseLogs,
      'caloriesBurned': instance.caloriesBurned,
      'heartRateAvg': instance.heartRateAvg,
      'heartRateMax': instance.heartRateMax,
      'notes': instance.notes,
      'mood': instance.mood,
      'perceivedEffort': instance.perceivedEffort,
    };

_$ExerciseLogImpl _$$ExerciseLogImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseLogImpl(
      exerciseId: json['exerciseId'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => SetLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ExerciseLogImplToJson(_$ExerciseLogImpl instance) =>
    <String, dynamic>{'exerciseId': instance.exerciseId, 'sets': instance.sets};

_$SetLogImpl _$$SetLogImplFromJson(Map<String, dynamic> json) => _$SetLogImpl(
  setNumber: (json['setNumber'] as num).toInt(),
  reps: (json['reps'] as num).toInt(),
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  completed: json['completed'] as bool? ?? true,
);

Map<String, dynamic> _$$SetLogImplToJson(_$SetLogImpl instance) =>
    <String, dynamic>{
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'weightKg': instance.weightKg,
      'durationSeconds': instance.durationSeconds,
      'completed': instance.completed,
    };
