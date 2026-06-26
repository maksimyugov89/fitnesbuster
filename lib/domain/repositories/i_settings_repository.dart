abstract interface class ISettingsRepository {
  // ── Workout stats (date-keyed) ────────────────────────────────────
  Future<bool> getWorkoutDone(String dayKey);
  Future<void> setWorkoutDone(String dayKey, bool done);
  Future<int> getWorkoutKcal(String dayKey);
  Future<void> setWorkoutKcal(String dayKey, int kcal);
  Future<int> getWorkoutSets(String dayKey);
  Future<void> setWorkoutSets(String dayKey, int sets);
  Future<int> getWorkoutTime(String dayKey);
  Future<void> setWorkoutTime(String dayKey, int minuteOfDay);
  Future<int> getWorkoutRating(String dayKey);
  Future<void> setWorkoutRating(String dayKey, int rating);
  Future<String?> getWorkoutLogDetail(String dayKey);
  Future<void> setWorkoutLogDetail(String dayKey, String json);
  Future<int> getWorkoutStreak();
  Future<void> setWorkoutStreak(int streak);
  Future<String?> getLastWorkoutDate();
  Future<void> setLastWorkoutDate(String date);

  // ── Nutrition (date-keyed) ────────────────────────────────────────
  Future<int> getEatenCal(String dayKey);
  Future<void> setEatenCal(String dayKey, int cal);
  Future<int> getTargetCal(String dayKey);
  Future<void> setTargetCal(String dayKey, int cal);
  Future<int> getWaterMl(String dayKey);
  Future<void> setWaterMl(String dayKey, int ml);
  Future<int> getWaterGlasses(String dayKey);
  Future<void> setWaterGlasses(String dayKey, int glasses);
  Future<List<String>> getMealsDone(String dayKey);
  Future<void> setMealsDone(String dayKey, List<String> meals);
  Future<List<String>> getManualFoods(String dayKey);
  Future<void> setManualFoods(String dayKey, List<String> foods);

  // ── Health (date-keyed) ───────────────────────────────────────────
  Future<int> getManualSteps(String dayKey);
  Future<void> setManualSteps(String dayKey, int steps);
  Future<int> getManualHeartRate(String dayKey);
  Future<void> setManualHeartRate(String dayKey, int bpm);

  // ── Avatar ────────────────────────────────────────────────────────
  Future<String?> getAvatarMode();
  Future<void> setAvatarMode(String mode);
  Future<int?> getAvatarPresetIndex();
  Future<void> setAvatarPresetIndex(int index);
  Future<String?> getAvatarCustomPath();
  Future<void> setAvatarCustomPath(String path);
  Future<void> removeAvatarCustomPath();

  // ── Persisted lists ───────────────────────────────────────────────
  Future<List<String>> getShoppingListChecked();
  Future<void> setShoppingListChecked(List<String> items);
  Future<String?> getCalendarOverrides();
  Future<void> setCalendarOverrides(String json);

  // ── Gamification ─────────────────────────────────────────────────
  Future<int> getGamificationXp();
  Future<void> setGamificationXp(int xp);
  Future<List<String>> getGamificationUnlocked();
  Future<void> setGamificationUnlocked(List<String> ids);
  Future<int> getGamificationTotalWorkouts();
  Future<void> setGamificationTotalWorkouts(int count);
  Future<int> getGamificationTotalPr();
  Future<void> setGamificationTotalPr(int count);
}
