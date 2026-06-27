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

  /// Parses any workout description (text, URL content, file, QR) into the
  /// app's JSON plan format. [sourceHint] helps the AI understand the origin.
  Future<String> parseWorkoutFromContent(
    String content, {
    String sourceHint,
  });

  /// Corrects/adjusts an existing workout plan based on user input.
  ///
  /// [currentPlanJson] — the user's current 7-day plan JSON.
  /// [userInput] — what the user wants to change, add, or analyze.
  /// [correctionType] — 'merge' (import external workout), 'preference'
  ///   (user-stated change), or 'post_workout' (adjust after completed session).
  /// [sourceHint] — human-readable origin label for the AI prompt.
  Future<String> correctWorkoutPlan({
    required String currentPlanJson,
    required String userInput,
    String correctionType,
    String sourceHint,
  });

  void dispose();
}
