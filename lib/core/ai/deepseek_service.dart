// cspell:disable
import 'package:fitnesbuster/core/ai/services/workout_plan_service.dart';
import 'package:fitnesbuster/core/ai/services/meal_plan_service.dart';
import 'package:fitnesbuster/core/ai/services/plan_refinement_service.dart';
import 'package:fitnesbuster/core/ai/services/progress_analyzer.dart';
import 'package:fitnesbuster/core/ai/services/chat_service.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';

export 'package:fitnesbuster/core/ai/ai_exception.dart';

class DeepSeekService implements IDeepSeekService {
  final WorkoutPlanService _workoutPlan;
  final MealPlanService _mealPlan;
  final PlanRefinementService _refinement;
  final ProgressAnalyzer _progress;
  final ChatService _chat;

  DeepSeekService({
    required WorkoutPlanService workoutPlan,
    required MealPlanService mealPlan,
    required PlanRefinementService refinement,
    required ProgressAnalyzer progress,
    required ChatService chat,
  }) : _workoutPlan = workoutPlan,
       _mealPlan = mealPlan,
       _refinement = refinement,
       _progress = progress,
       _chat = chat;

  @override
  Future<String> generateWorkoutPlan(
    UserProfile profile, {
    HealthData? recentHealth,
    int weekNumber = 1,
    String? previousPlanFeedback,
    int? recentAvgRpe,
    int? domsLevel,
  }) => _workoutPlan.generateWorkoutPlan(
    profile,
    recentHealth: recentHealth,
    weekNumber: weekNumber,
    previousPlanFeedback: previousPlanFeedback,
    recentAvgRpe: recentAvgRpe,
    domsLevel: domsLevel,
  );

  @override
  Future<String> generateMealPlan(
    UserProfile profile, {
    int stepsToday = 0,
    HealthData? recentHealth,
    List<String>? dislikedFoods,
    String? cuisinePreference,
    String? city,
  }) => _mealPlan.generateMealPlan(
    profile,
    stepsToday: stepsToday,
    recentHealth: recentHealth,
    dislikedFoods: dislikedFoods,
    cuisinePreference: cuisinePreference,
    city: city,
  );

  @override
  Future<String> refineWorkoutPlan(
    UserProfile profile,
    List<TestExerciseResult> exercises,
  ) => _refinement.refineWorkoutPlan(profile, exercises);

  @override
  Future<String> analyzeProgress({
    required UserProfile profile,
    required Map<String, double?> latest,
    Map<String, double?>? previous,
    bool hasPhotos = false,
  }) => _progress.analyzeProgress(
    profile: profile,
    latest: latest,
    previous: previous,
    hasPhotos: hasPhotos,
  );

  @override
  Future<String> generateWeeklyDebrief({
    required UserProfile profile,
    required int workoutsDone,
    required List<int> dailyWorkoutKcal,
    required List<int> dailyWaterMl,
    required List<int> dailyEatenCal,
    required int dailyCalTarget,
    required int dailyWaterTarget,
    required List<String> weekPrNames,
  }) => _progress.generateWeeklyDebrief(
    profile: profile,
    workoutsDone: workoutsDone,
    dailyWorkoutKcal: dailyWorkoutKcal,
    dailyWaterMl: dailyWaterMl,
    dailyEatenCal: dailyEatenCal,
    dailyCalTarget: dailyCalTarget,
    dailyWaterTarget: dailyWaterTarget,
    weekPrNames: weekPrNames,
  );

  @override
  Future<String> askWithHistory(
    List<ChatMessage> history,
    String newQuestion, {
    UserProfile? profile,
  }) => _chat.askWithHistory(history, newQuestion, profile: profile);

  @override
  Future<String> askQuestion(
    String question, {
    UserProfile? profile,
    List<String>? recentTopics,
  }) =>
      _chat.askQuestion(question, profile: profile, recentTopics: recentTopics);

  @override
  Future<String> parseWorkoutFromContent(
    String content, {
    String sourceHint = '',
    UserProfile? profile,
  }) => _chat.parseWorkoutFromContent(
    content,
    sourceHint: sourceHint,
    profile: profile,
  );

  @override
  Future<String> correctWorkoutPlan({
    required String currentPlanJson,
    required String userInput,
    String correctionType = 'merge',
    String sourceHint = '',
    UserProfile? profile,
  }) => _refinement.correctWorkoutPlan(
    currentPlanJson: currentPlanJson,
    userInput: userInput,
    correctionType: correctionType,
    sourceHint: sourceHint,
    profile: profile,
  );

  @override
  void dispose() => _chat.dispose();
}
