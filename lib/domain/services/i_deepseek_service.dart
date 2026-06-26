import 'package:fitnesbuster/domain/entities/entities.dart';

abstract interface class IDeepSeekService {
  Future<String> generateWorkoutPlan(
    UserProfile profile, {
    HealthData? recentHealth,
    int weekNumber,
    String? previousPlanFeedback,
  });

  Future<String> generateMealPlan(
    UserProfile profile, {
    int stepsToday,
    HealthData? recentHealth,
    List<String>? dislikedFoods,
    String? cuisinePreference,
    String? city,
  });

  Future<String> refineWorkoutPlan(
    UserProfile profile,
    List<TestExerciseResult> exercises,
  );

  Future<String> analyzeProgress({
    required UserProfile profile,
    required Map<String, double?> latest,
    Map<String, double?>? previous,
    bool hasPhotos,
  });

  Future<String> generateWeeklyDebrief({
    required UserProfile profile,
    required int workoutsDone,
    required List<int> dailyWorkoutKcal,
    required List<int> dailyWaterMl,
    required List<int> dailyEatenCal,
    required int dailyCalTarget,
    required int dailyWaterTarget,
    required List<String> weekPrNames,
  });

  Future<String> askWithHistory(
    List<ChatMessage> history,
    String newQuestion, {
    UserProfile? profile,
  });

  Future<String> askQuestion(
    String question, {
    UserProfile? profile,
    List<String>? recentTopics,
  });

  void dispose();
}
