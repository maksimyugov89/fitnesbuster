import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';

class SettingsRepository implements ISettingsRepository {
  // ── Key factories ─────────────────────────────────────────────────
  static String _wDone(String k)    => 'workout_done_$k';
  static String _wKcal(String k)    => 'workout_kcal_$k';
  static String _wSets(String k)    => 'workout_sets_$k';
  static String _wTime(String k)    => 'workout_time_$k';
  static String _wRating(String k)  => 'workout_rating_$k';
  static String _wLog(String k)     => 'workout_log_detail_$k';
  static String _eaten(String k)    => 'eaten_cal_$k';
  static String _target(String k)   => 'target_cal_$k';
  static String _water(String k)    => 'water_ml_$k';
  static String _glasses(String k)  => 'water_glasses_$k';
  static String _meals(String k)    => 'meals_done_$k';
  static String _foods(String k)    => 'manual_foods_$k';
  static String _steps(String k)    => 'manual_steps_$k';
  static String _bpm(String k)      => 'manual_heartrate_$k';

  static const _streak       = 'workout_streak';
  static const _lastDate     = 'last_workout_date';
  static const _avatarMode   = 'avatar_mode';
  static const _avatarPreset = 'avatar_preset_index';
  static const _avatarCustom = 'avatar_custom_path';
  static const _shopChecked  = 'shopping_list_checked';
  static const _calOverrides = 'workout_calendar_overrides';
  static const _gamXp        = 'gamification_xp';
  static const _gamUnlocked  = 'gamification_unlocked';
  static const _gamWorkouts  = 'gamification_total_workouts';
  static const _gamPr        = 'gamification_total_pr';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  // ── Workout stats ─────────────────────────────────────────────────
  @override Future<bool>    getWorkoutDone(String k)       async => (await _p).getBool(_wDone(k))   ?? false;
  @override Future<void>    setWorkoutDone(String k, bool v)      async => (await _p).setBool(_wDone(k), v);
  @override Future<int>     getWorkoutKcal(String k)       async => (await _p).getInt(_wKcal(k))    ?? 0;
  @override Future<void>    setWorkoutKcal(String k, int v)       async => (await _p).setInt(_wKcal(k), v);
  @override Future<int>     getWorkoutSets(String k)       async => (await _p).getInt(_wSets(k))    ?? 0;
  @override Future<void>    setWorkoutSets(String k, int v)       async => (await _p).setInt(_wSets(k), v);
  @override Future<int>     getWorkoutTime(String k)       async => (await _p).getInt(_wTime(k))    ?? 0;
  @override Future<void>    setWorkoutTime(String k, int v)       async => (await _p).setInt(_wTime(k), v);
  @override Future<int>     getWorkoutRating(String k)     async => (await _p).getInt(_wRating(k))  ?? 0;
  @override Future<void>    setWorkoutRating(String k, int v)     async => (await _p).setInt(_wRating(k), v);
  @override Future<String?> getWorkoutLogDetail(String k)  async => (await _p).getString(_wLog(k));
  @override Future<void>    setWorkoutLogDetail(String k, String v) async => (await _p).setString(_wLog(k), v);
  @override Future<int>     getWorkoutStreak()             async => (await _p).getInt(_streak)      ?? 0;
  @override Future<void>    setWorkoutStreak(int v)                async => (await _p).setInt(_streak, v);
  @override Future<String?> getLastWorkoutDate()           async => (await _p).getString(_lastDate);
  @override Future<void>    setLastWorkoutDate(String v)           async => (await _p).setString(_lastDate, v);

  // ── Nutrition ─────────────────────────────────────────────────────
  @override Future<int>          getEatenCal(String k)     async => (await _p).getInt(_eaten(k))   ?? 0;
  @override Future<void>         setEatenCal(String k, int v)     async => (await _p).setInt(_eaten(k), v);
  @override Future<int>          getTargetCal(String k)    async => (await _p).getInt(_target(k))  ?? 0;
  @override Future<void>         setTargetCal(String k, int v)    async => (await _p).setInt(_target(k), v);
  @override Future<int>          getWaterMl(String k)      async => (await _p).getInt(_water(k))   ?? 0;
  @override Future<void>         setWaterMl(String k, int v)      async => (await _p).setInt(_water(k), v);
  @override Future<int>          getWaterGlasses(String k) async => (await _p).getInt(_glasses(k)) ?? 0;
  @override Future<void>         setWaterGlasses(String k, int v) async => (await _p).setInt(_glasses(k), v);
  @override Future<List<String>> getMealsDone(String k)    async => (await _p).getStringList(_meals(k)) ?? [];
  @override Future<void>         setMealsDone(String k, List<String> v) async => (await _p).setStringList(_meals(k), v);
  @override Future<List<String>> getManualFoods(String k)  async => (await _p).getStringList(_foods(k)) ?? [];
  @override Future<void>         setManualFoods(String k, List<String> v) async => (await _p).setStringList(_foods(k), v);

  // ── Health ────────────────────────────────────────────────────────
  @override Future<int>  getManualSteps(String k)     async => (await _p).getInt(_steps(k)) ?? 0;
  @override Future<void> setManualSteps(String k, int v)     async => (await _p).setInt(_steps(k), v);
  @override Future<int>  getManualHeartRate(String k)  async => (await _p).getInt(_bpm(k))   ?? 0;
  @override Future<void> setManualHeartRate(String k, int v) async => (await _p).setInt(_bpm(k), v);

  // ── Avatar ────────────────────────────────────────────────────────
  @override Future<String?> getAvatarMode()            async => (await _p).getString(_avatarMode);
  @override Future<void>    setAvatarMode(String v)            async => (await _p).setString(_avatarMode, v);
  @override Future<int?>    getAvatarPresetIndex()     async => (await _p).getInt(_avatarPreset);
  @override Future<void>    setAvatarPresetIndex(int v)        async => (await _p).setInt(_avatarPreset, v);
  @override Future<String?> getAvatarCustomPath()      async => (await _p).getString(_avatarCustom);
  @override Future<void>    setAvatarCustomPath(String v)      async => (await _p).setString(_avatarCustom, v);
  @override Future<void>    removeAvatarCustomPath()   async => (await _p).remove(_avatarCustom);

  // ── Persisted lists ───────────────────────────────────────────────
  @override Future<List<String>> getShoppingListChecked()     async => (await _p).getStringList(_shopChecked) ?? [];
  @override Future<void>         setShoppingListChecked(List<String> v) async => (await _p).setStringList(_shopChecked, v);
  @override Future<String?>      getCalendarOverrides()       async => (await _p).getString(_calOverrides);
  @override Future<void>         setCalendarOverrides(String v)       async => (await _p).setString(_calOverrides, v);

  // ── Gamification ─────────────────────────────────────────────────
  @override Future<int>          getGamificationXp()          async => (await _p).getInt(_gamXp)       ?? 0;
  @override Future<void>         setGamificationXp(int v)             async => (await _p).setInt(_gamXp, v);
  @override Future<List<String>> getGamificationUnlocked()    async => (await _p).getStringList(_gamUnlocked) ?? [];
  @override Future<void>         setGamificationUnlocked(List<String> v) async => (await _p).setStringList(_gamUnlocked, v);
  @override Future<int>          getGamificationTotalWorkouts() async => (await _p).getInt(_gamWorkouts) ?? 0;
  @override Future<void>         setGamificationTotalWorkouts(int v)   async => (await _p).setInt(_gamWorkouts, v);
  @override Future<int>          getGamificationTotalPr()     async => (await _p).getInt(_gamPr)        ?? 0;
  @override Future<void>         setGamificationTotalPr(int v)         async => (await _p).setInt(_gamPr, v);
}
