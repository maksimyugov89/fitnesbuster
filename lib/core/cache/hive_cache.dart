import 'package:hive/hive.dart';
import 'package:fitnesbuster/data/models/chat_message.dart';
import 'package:fitnesbuster/data/models/weekly_debrief.dart';

/// Single entry point for all Hive cache operations.
/// Uses plain string storage — no code generation required.
class HiveCache {
  static const _boxName = 'fitnesbuster_cache';

  // ── Box lifecycle ─────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  // ── Key helpers ───────────────────────────────────────────────────────────

  static String _workoutKey(String uid) => 'ai_workout_$uid';
  static String _mealKey(String uid) => 'ai_meal_$uid';
  static String _tsKey(String uid) => 'ai_ts_$uid';
  static String _testWeekKey(String uid) => 'test_week_$uid';
  static String _needsSyncKey(String uid) => 'needs_sync_$uid';

  // ── AI Plans ──────────────────────────────────────────────────────────────

  static Map<String, String?> getAiPlans(String uid) => {
    'workoutPlan': _box.get(_workoutKey(uid)),
    'mealPlan': _box.get(_mealKey(uid)),
  };

  static Future<void> saveAiPlans(
    String uid, {
    String? workoutPlan,
    String? mealPlan,
  }) async {
    if (workoutPlan != null) await _box.put(_workoutKey(uid), workoutPlan);
    if (mealPlan != null) await _box.put(_mealKey(uid), mealPlan);
    await _box.put(_tsKey(uid), DateTime.now().toIso8601String());
  }

  static Future<void> updateWorkoutPlan(String uid, String workoutPlan) async {
    await _box.put(_workoutKey(uid), workoutPlan);
    await _box.put(_tsKey(uid), DateTime.now().toIso8601String());
  }

  // ── Cache metadata ────────────────────────────────────────────────────────

  static DateTime? getCacheTime(String uid) {
    final raw = _box.get(_tsKey(uid));
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// True if the cached plans are younger than [maxAge].
  static bool isFresh(String uid, {Duration maxAge = const Duration(hours: 24)}) {
    final ts = getCacheTime(uid);
    if (ts == null) return false;
    return DateTime.now().difference(ts) < maxAge;
  }

  static bool hasAiPlans(String uid) =>
      _box.containsKey(_workoutKey(uid)) || _box.containsKey(_mealKey(uid));

  // ── Test-week flag ────────────────────────────────────────────────────────

  static bool? getTestWeekCompleted(String uid) {
    final v = _box.get(_testWeekKey(uid));
    return v != null ? v == 'true' : null;
  }

  static Future<void> setTestWeekCompleted(String uid) async {
    await _box.put(_testWeekKey(uid), 'true');
  }

  // ── Chat history ──────────────────────────────────────────────────────────

  static String _chatKey(String uid) => 'chat_history_$uid';
  static const int _maxHistoryMessages = 50;

  static List<ChatMessage> getChatHistory(String uid) {
    final raw = _box.get(_chatKey(uid));
    if (raw == null) return [];
    try {
      return ChatMessage.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChatHistory(
      String uid, List<ChatMessage> messages) async {
    final limited = messages.length > _maxHistoryMessages
        ? messages.sublist(messages.length - _maxHistoryMessages)
        : messages;
    await _box.put(_chatKey(uid), ChatMessage.encodeList(limited));
  }

  static Future<void> clearChatHistory(String uid) async {
    await _box.delete(_chatKey(uid));
  }

  // ── Cache invalidation ────────────────────────────────────────────────────

  static Future<void> clearUserCache(String uid) async {
    await _box.delete(_workoutKey(uid));
    await _box.delete(_mealKey(uid));
    await _box.delete(_tsKey(uid));
    await _box.delete(_testWeekKey(uid));
    await _box.delete(_chatKey(uid));
    await _box.delete(_needsSyncKey(uid));
  }

  // ── Weekly debrief ────────────────────────────────────────────────────────

  static String _debriefKey(String uid, String weekStart) =>
      'debrief_${uid}_$weekStart';

  static WeeklyDebrief? getDebrief(String uid, String weekStart) {
    final raw = _box.get(_debriefKey(uid, weekStart));
    if (raw == null) {
      return null;
    }
    try {
      return WeeklyDebrief.decode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveDebrief(
      String uid, String weekStart, WeeklyDebrief debrief) async {
    await _box.put(_debriefKey(uid, weekStart), WeeklyDebrief.encode(debrief));
  }

  // ── Firestore sync flag ──────────────────────────────────────────────────

  /// Marks that the cached plan needs to be pushed to Firestore later.
  static Future<void> setNeedsSync(String uid) async {
    await _box.put(_needsSyncKey(uid), 'true');
  }

  /// True if the cached plan has not been synced to Firestore yet.
  static bool isSyncNeeded(String uid) {
    return _box.get(_needsSyncKey(uid)) == 'true';
  }

  /// Clears the pending-sync flag after successful Firestore upload.
  static Future<void> clearSyncNeeded(String uid) async {
    await _box.delete(_needsSyncKey(uid));
  }
}
