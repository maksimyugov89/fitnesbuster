import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fitnesbuster/domain/entities/user_entities.dart';

part 'workout_entities.freezed.dart';
part 'workout_entities.g.dart';

enum WorkoutDayType { workout, rest, activeRecovery, cardio }
enum WorkoutPlanStatus { active, completed, paused }
enum ExerciseType { strength, cardio, flexibility, balance, hiit, yoga }
enum DifficultyLevel { beginner, intermediate, advanced, elite }

@freezed
class TestWeekResult with _$TestWeekResult {
  const factory TestWeekResult({
    required DateTime completedAt,
    required List<TestExerciseResult> exercises,
    @Default(0) double averageHeartRate,
    @Default(0) int averageSessionDuration,
    @Default(5) int perceivedDifficulty,
    String? feedback,
  }) = _TestWeekResult;

  factory TestWeekResult.fromJson(Map<String, dynamic> json) => _$TestWeekResultFromJson(json);
}

@freezed
class WorkoutPlan with _$WorkoutPlan {
  const factory WorkoutPlan({
    required String id,
    required String userId,
    required String title,
    required FitnessGoal goal,
    required IntensityLevel intensity,
    required int durationWeeks,
    required List<WorkoutWeek> weeks,
    required DateTime startDate,
    DateTime? completedAt,
    @Default(WorkoutPlanStatus.active) WorkoutPlanStatus status,
  }) = _WorkoutPlan;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => _$WorkoutPlanFromJson(json);
}

@freezed
class WorkoutWeek with _$WorkoutWeek {
  const factory WorkoutWeek({
    required int weekNumber,
    required List<WorkoutDay> days,
    String? weeklyFocus,
  }) = _WorkoutWeek;

  factory WorkoutWeek.fromJson(Map<String, dynamic> json) => _$WorkoutWeekFromJson(json);
}

@freezed
class WorkoutDay with _$WorkoutDay {
  const WorkoutDay._();

  const factory WorkoutDay({
    required int dayNumber,
    required DateTime date,
    required WorkoutDayType type,
    WorkoutSession? session,
    WorkoutLog? log,
  }) = _WorkoutDay;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => _$WorkoutDayFromJson(json);

  bool get isCompleted => log != null;
  bool get isRest => type == WorkoutDayType.rest;
}

@freezed
class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    required String title,
    String? description,
    required MuscleGroup primaryMuscle,
    @Default([]) List<MuscleGroup> secondaryMuscles,
    required List<ExerciseSet> exercises,
    required int estimatedDurationMinutes,
    required int estimatedCaloriesBurn,
    required DifficultyLevel difficulty,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
}

@freezed
class ExerciseSet with _$ExerciseSet {
  const factory ExerciseSet({
    required Exercise exercise,
    required List<SetData> sets,
    String? notes,
    @Default(60) int restSeconds,
  }) = _ExerciseSet;

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
}

@freezed
class SetData with _$SetData {
  const factory SetData({
    required int setNumber,
    required int reps,
    double? weightKg,
    int? durationSeconds,
    bool? completed,
    double? actualWeight,
    int? actualReps,
  }) = _SetData;

  factory SetData.fromJson(Map<String, dynamic> json) => _$SetDataFromJson(json);
}

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    String? description,
    String? videoUrl,
    String? imageUrl,
    required MuscleGroup primaryMuscle,
    @Default([]) List<MuscleGroup> secondaryMuscles,
    required ExerciseType type,
    @Default([]) List<String> equipment,
    required DifficultyLevel difficulty,
    required List<String> instructions,
    List<String>? contraindications,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
}

@freezed
class WorkoutLog with _$WorkoutLog {
  const WorkoutLog._();

  const factory WorkoutLog({
    required String id,
    required String sessionId,
    required DateTime startTime,
    DateTime? endTime,
    required List<ExerciseLog> exerciseLogs,
    double? caloriesBurned,
    int? heartRateAvg,
    int? heartRateMax,
    String? notes,
    int? mood,
    int? perceivedEffort,
  }) = _WorkoutLog;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => _$WorkoutLogFromJson(json);

  int get durationMinutes =>
      endTime != null ? endTime!.difference(startTime).inMinutes : 0;

  bool get isCompleted => endTime != null;
}

@freezed
class ExerciseLog with _$ExerciseLog {
  const factory ExerciseLog({
    required String exerciseId,
    required List<SetLog> sets,
  }) = _ExerciseLog;

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => _$ExerciseLogFromJson(json);
}

@freezed
class SetLog with _$SetLog {
  const factory SetLog({
    required int setNumber,
    required int reps,
    double? weightKg,
    int? durationSeconds,
    @Default(true) bool completed,
  }) = _SetLog;

  factory SetLog.fromJson(Map<String, dynamic> json) => _$SetLogFromJson(json);
}
