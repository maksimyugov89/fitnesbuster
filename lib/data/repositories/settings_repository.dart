import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

class SettingsRepository implements ISettingsRepository {
  // ── Key factories ─────────────────────────────────────────────────
  static String _wDone(String k) => 'workout_done_$k';
  static String _wKcal(String k) => 'workout_kcal_$k';
  static String _wSets(String k) => 'workout_sets_$k';
  static String _wTime(String k) => 'workout_time_$k';
  static String _wRating(String k) => 'workout_rating_$k';
  static String _wRpe(String k) => 'workout_rpe_$k';
  static String _doms(String k) => 'doms_level_$k';
  static String _wLog(String k) => 'workout_log_detail_$k';
  static String _eaten(String k) => 'eaten_cal_$k';
  static String _target(String k) => 'target_cal_$k';
  static String _water(String k) => 'water_ml_$k';
  static String _glasses(String k) => 'water_glasses_$k';
  static String _meals(String k) => 'meals_done_$k';
  static String _foods(String k) => 'manual_foods_$k';
  static String _steps(String k) => 'manual_steps_$k';
  static String _bpm(String k) => 'manual_heartrate_$k';

  static const _streak = 'workout_streak';
  static const _lastDate = 'last_workout_date';
  static const _avatarMode = 'avatar_mode';
  static const _avatarPreset = 'avatar_preset_index';
  static const _avatarCustom = 'avatar_custom_path';
  static const _shopChecked = 'shopping_list_checked';
  static const _calOverrides = 'workout_calendar_overrides';
  static const _gamXp = 'gamification_xp';
  static const _gamUnlocked = 'gamification_unlocked';
  static const _gamWorkouts = 'gamification_total_workouts';
  static const _gamPr = 'gamification_total_pr';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  // ── Safe helpers ──────────────────────────────────────────────────

  Future<T> _getOr<T>(T? Function(SharedPreferences) fn, T fallback) async {
    try {
      return fn(await _p) ?? fallback;
    } catch (e, st) {
      appLogger.w('[SettingsRepository] read failed', error: e, stackTrace: st);
      return fallback;
    }
  }

  Future<String?> _getStr(String? Function(SharedPreferences) fn) async {
    try {
      return fn(await _p);
    } catch (e, st) {
      appLogger.w('[SettingsRepository] read failed', error: e, stackTrace: st);
      return null;
    }
  }

  Future<int?> _getIntOrNull(int? Function(SharedPreferences) fn) async {
    try {
      return fn(await _p);
    } catch (e, st) {
      appLogger.w('[SettingsRepository] read failed', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> _set(void Function(SharedPreferences) fn) async {
    try {
      fn(await _p);
    } catch (e, st) {
      appLogger.w(
        '[SettingsRepository] write failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── Workout stats ─────────────────────────────────────────────────
  @override
  Future<bool> getWorkoutDone(String k) async =>
      _getOr((p) => p.getBool(_wDone(k)), false);
  @override
  Future<void> setWorkoutDone(String k, bool v) async =>
      _set((p) => p.setBool(_wDone(k), v));
  @override
  Future<int> getWorkoutKcal(String k) async =>
      _getOr((p) => p.getInt(_wKcal(k)), 0);
  @override
  Future<void> setWorkoutKcal(String k, int v) async =>
      _set((p) => p.setInt(_wKcal(k), v));
  @override
  Future<int> getWorkoutSets(String k) async =>
      _getOr((p) => p.getInt(_wSets(k)), 0);
  @override
  Future<void> setWorkoutSets(String k, int v) async =>
      _set((p) => p.setInt(_wSets(k), v));
  @override
  Future<int> getWorkoutTime(String k) async =>
      _getOr((p) => p.getInt(_wTime(k)), 0);
  @override
  Future<void> setWorkoutTime(String k, int v) async =>
      _set((p) => p.setInt(_wTime(k), v));
  @override
  Future<int> getWorkoutRating(String k) async =>
      _getOr((p) => p.getInt(_wRating(k)), 0);
  @override
  Future<void> setWorkoutRating(String k, int v) async =>
      _set((p) => p.setInt(_wRating(k), v));
  @override
  Future<int?> getWorkoutRpe(String k) async =>
      _getIntOrNull((p) => p.getInt(_wRpe(k)));
  @override
  Future<void> setWorkoutRpe(String k, int v) async =>
      _set((p) => p.setInt(_wRpe(k), v));
  @override
  Future<int?> getDomsLevel(String k) async =>
      _getIntOrNull((p) => p.getInt(_doms(k)));
  @override
  Future<void> setDomsLevel(String k, int v) async =>
      _set((p) => p.setInt(_doms(k), v));
  @override
  Future<String?> getWorkoutLogDetail(String k) async =>
      _getStr((p) => p.getString(_wLog(k)));
  @override
  Future<void> setWorkoutLogDetail(String k, String v) async =>
      _set((p) => p.setString(_wLog(k), v));
  @override
  Future<int> getWorkoutStreak() async => _getOr((p) => p.getInt(_streak), 0);
  @override
  Future<void> setWorkoutStreak(int v) async =>
      _set((p) => p.setInt(_streak, v));
  @override
  Future<String?> getLastWorkoutDate() async =>
      _getStr((p) => p.getString(_lastDate));
  @override
  Future<void> setLastWorkoutDate(String v) async =>
      _set((p) => p.setString(_lastDate, v));

  // ── Nutrition ─────────────────────────────────────────────────────
  @override
  Future<int> getEatenCal(String k) async =>
      _getOr((p) => p.getInt(_eaten(k)), 0);
  @override
  Future<void> setEatenCal(String k, int v) async =>
      _set((p) => p.setInt(_eaten(k), v));
  @override
  Future<int> getTargetCal(String k) async =>
      _getOr((p) => p.getInt(_target(k)), 0);
  @override
  Future<void> setTargetCal(String k, int v) async =>
      _set((p) => p.setInt(_target(k), v));
  @override
  Future<int> getWaterMl(String k) async =>
      _getOr((p) => p.getInt(_water(k)), 0);
  @override
  Future<void> setWaterMl(String k, int v) async =>
      _set((p) => p.setInt(_water(k), v));
  @override
  Future<int> getWaterGlasses(String k) async =>
      _getOr((p) => p.getInt(_glasses(k)), 0);
  @override
  Future<void> setWaterGlasses(String k, int v) async =>
      _set((p) => p.setInt(_glasses(k), v));
  @override
  Future<List<String>> getMealsDone(String k) async =>
      _getOr((p) => p.getStringList(_meals(k)), <String>[]);
  @override
  Future<void> setMealsDone(String k, List<String> v) async =>
      _set((p) => p.setStringList(_meals(k), v));
  @override
  Future<List<String>> getManualFoods(String k) async =>
      _getOr((p) => p.getStringList(_foods(k)), <String>[]);
  @override
  Future<void> setManualFoods(String k, List<String> v) async =>
      _set((p) => p.setStringList(_foods(k), v));

  // ── Health ────────────────────────────────────────────────────────
  @override
  Future<int> getManualSteps(String k) async =>
      _getOr((p) => p.getInt(_steps(k)), 0);
  @override
  Future<void> setManualSteps(String k, int v) async =>
      _set((p) => p.setInt(_steps(k), v));
  @override
  Future<int> getManualHeartRate(String k) async =>
      _getOr((p) => p.getInt(_bpm(k)), 0);
  @override
  Future<void> setManualHeartRate(String k, int v) async =>
      _set((p) => p.setInt(_bpm(k), v));

  // ── Avatar ────────────────────────────────────────────────────────
  @override
  Future<String?> getAvatarMode() async =>
      _getStr((p) => p.getString(_avatarMode));
  @override
  Future<void> setAvatarMode(String v) async =>
      _set((p) => p.setString(_avatarMode, v));
  @override
  Future<int?> getAvatarPresetIndex() async =>
      _getIntOrNull((p) => p.getInt(_avatarPreset));
  @override
  Future<void> setAvatarPresetIndex(int v) async =>
      _set((p) => p.setInt(_avatarPreset, v));
  @override
  Future<String?> getAvatarCustomPath() async =>
      _getStr((p) => p.getString(_avatarCustom));
  @override
  Future<void> setAvatarCustomPath(String v) async =>
      _set((p) => p.setString(_avatarCustom, v));
  @override
  Future<void> removeAvatarCustomPath() async =>
      _set((p) => p.remove(_avatarCustom));

  // ── Persisted lists ───────────────────────────────────────────────
  @override
  Future<List<String>> getShoppingListChecked() async =>
      _getOr((p) => p.getStringList(_shopChecked), <String>[]);
  @override
  Future<void> setShoppingListChecked(List<String> v) async =>
      _set((p) => p.setStringList(_shopChecked, v));
  @override
  Future<String?> getCalendarOverrides() async =>
      _getStr((p) => p.getString(_calOverrides));
  @override
  Future<void> setCalendarOverrides(String v) async =>
      _set((p) => p.setString(_calOverrides, v));

  // ── Gamification ─────────────────────────────────────────────────
  @override
  Future<int> getGamificationXp() async => _getOr((p) => p.getInt(_gamXp), 0);
  @override
  Future<void> setGamificationXp(int v) async =>
      _set((p) => p.setInt(_gamXp, v));
  @override
  Future<List<String>> getGamificationUnlocked() async =>
      _getOr((p) => p.getStringList(_gamUnlocked), <String>[]);
  @override
  Future<void> setGamificationUnlocked(List<String> v) async =>
      _set((p) => p.setStringList(_gamUnlocked, v));
  @override
  Future<int> getGamificationTotalWorkouts() async =>
      _getOr((p) => p.getInt(_gamWorkouts), 0);
  @override
  Future<void> setGamificationTotalWorkouts(int v) async =>
      _set((p) => p.setInt(_gamWorkouts, v));
  @override
  Future<int> getGamificationTotalPr() async =>
      _getOr((p) => p.getInt(_gamPr), 0);
  @override
  Future<void> setGamificationTotalPr(int v) async =>
      _set((p) => p.setInt(_gamPr, v));
}
