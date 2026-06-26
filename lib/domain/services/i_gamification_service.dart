abstract interface class IGamificationService {
  Future<int> getTotalXp();
  Future<int> addXp(int amount);
  Future<Set<String>> getUnlockedIds();
  Future<int> unlock(String achievementId);
  Future<int> incrementWorkouts();
  Future<int> getTotalWorkouts();
  Future<int> incrementPr();
  Future<int> getTotalPr();
  Future<int> onWorkoutCompleted({required int streak, required int workoutHour});
  Future<int> onPrSet();
  Future<int> onWaterGoalReached({required bool over3L});
  Future<int> onAllMealsCompleted();
  Future<void> onAiPlanCreated();
  Future<void> onTestWeekCompleted();
  Future<void> onDebriefReceived();
}
