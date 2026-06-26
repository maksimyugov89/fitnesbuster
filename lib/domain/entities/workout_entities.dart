import 'package:fitnesbuster/domain/entities/user_entities.dart';

class TestWeekResult {
  final DateTime completedAt;
  final List<TestExerciseResult> exercises;
  final double averageHeartRate;
  final int averageSessionDuration;
  final int perceivedDifficulty;
  final String? feedback;

  const TestWeekResult({
    required this.completedAt,
    required this.exercises,
    this.averageHeartRate = 0,
    this.averageSessionDuration = 0,
    this.perceivedDifficulty = 5,
    this.feedback,
  });
}

enum WorkoutDayType { workout, rest, activeRecovery, cardio }
enum WorkoutPlanStatus { active, completed, paused }
enum ExerciseType { strength, cardio, flexibility, balance, hiit, yoga }
enum DifficultyLevel { beginner, intermediate, advanced, elite }

class WorkoutPlan {
  final String id;
  final String userId;
  final String title;
  final FitnessGoal goal;
  final IntensityLevel intensity;
  final int durationWeeks;
  final List<WorkoutWeek> weeks;
  final DateTime startDate;
  final DateTime? completedAt;
  final WorkoutPlanStatus status;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.title,
    required this.goal,
    required this.intensity,
    required this.durationWeeks,
    required this.weeks,
    required this.startDate,
    this.completedAt,
    this.status = WorkoutPlanStatus.active,
  });
}

class WorkoutWeek {
  final int weekNumber;
  final List<WorkoutDay> days;
  final String? weeklyFocus;

  const WorkoutWeek({
    required this.weekNumber,
    required this.days,
    this.weeklyFocus,
  });
}

class WorkoutDay {
  final int dayNumber;
  final DateTime date;
  final WorkoutDayType type;
  final WorkoutSession? session;
  final WorkoutLog? log;

  const WorkoutDay({
    required this.dayNumber,
    required this.date,
    required this.type,
    this.session,
    this.log,
  });

  bool get isCompleted => log != null;
  bool get isRest => type == WorkoutDayType.rest;
}

class WorkoutSession {
  final String id;
  final String title;
  final String? description;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final List<ExerciseSet> exercises;
  final int estimatedDurationMinutes;
  final int estimatedCaloriesBurn;
  final DifficultyLevel difficulty;

  const WorkoutSession({
    required this.id,
    required this.title,
    this.description,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.exercises,
    required this.estimatedDurationMinutes,
    required this.estimatedCaloriesBurn,
    required this.difficulty,
  });
}

class ExerciseSet {
  final Exercise exercise;
  final List<SetData> sets;
  final String? notes;
  final int restSeconds;

  const ExerciseSet({
    required this.exercise,
    required this.sets,
    this.notes,
    this.restSeconds = 60,
  });
}

class SetData {
  final int setNumber;
  final int reps;
  final double? weightKg;
  final int? durationSeconds;
  final bool? completed;
  final double? actualWeight;
  final int? actualReps;

  const SetData({
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
    this.completed,
    this.actualWeight,
    this.actualReps,
  });
}

class Exercise {
  final String id;
  final String name;
  final String? description;
  final String? videoUrl;
  final String? imageUrl;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final ExerciseType type;
  final List<String> equipment;
  final DifficultyLevel difficulty;
  final List<String> instructions;
  final List<String>? contraindications;

  const Exercise({
    required this.id,
    required this.name,
    this.description,
    this.videoUrl,
    this.imageUrl,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    required this.type,
    this.equipment = const [],
    required this.difficulty,
    required this.instructions,
    this.contraindications,
  });
}

class WorkoutLog {
  final String id;
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<ExerciseLog> exerciseLogs;
  final double? caloriesBurned;
  final int? heartRateAvg;
  final int? heartRateMax;
  final String? notes;
  final int? mood;
  final int? perceivedEffort;

  const WorkoutLog({
    required this.id,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.exerciseLogs,
    this.caloriesBurned,
    this.heartRateAvg,
    this.heartRateMax,
    this.notes,
    this.mood,
    this.perceivedEffort,
  });

  int get durationMinutes =>
      endTime != null ? endTime!.difference(startTime).inMinutes : 0;

  bool get isCompleted => endTime != null;
}

class ExerciseLog {
  final String exerciseId;
  final List<SetLog> sets;

  const ExerciseLog({required this.exerciseId, required this.sets});
}

class SetLog {
  final int setNumber;
  final int reps;
  final double? weightKg;
  final int? durationSeconds;
  final bool completed;

  const SetLog({
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
    this.completed = true,
  });
}
