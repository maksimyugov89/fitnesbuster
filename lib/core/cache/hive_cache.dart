import 'package:hive/hive.dart';
import 'package:fitnesbuster/data/models/chat_message.dart';
import 'package:fitnesbuster/domain/entities/chat_message.dart';
import 'package:fitnesbuster/data/models/weekly_debrief.dart';
import 'package:fitnesbuster/core/cache/hive_encryption.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

/// Single entry point for all Hive cache operations.
/// Uses plain string storage — no code generation required.
class HiveCache {
  static const _boxName = 'fitnesbuster_cache';
  static const _encryptedBoxNames = [
    _boxName,
    'offline_queue',
    'offline_queue_dead_letter',
  ];

  // ── Box lifecycle ─────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      try {
        await Hive.openBox<String>(
          _boxName,
          encryptionCipher: HiveEncryption.cipher,
        );
      } on HiveError catch (e) {
        // If the encryption key changed between installations (e.g. debug →
        // release signing key caused FlutterSecureStorage to generate a new
        // key while the old Hive file still exists), Hive won't be able to
        // decrypt the box. Delete the corrupted file and retry.
        appLogger.w(
          '[HiveCache] Failed to open encrypted box, resetting',
          error: e,
        );
        await _resetEncryptedStorage(e);
      } on FormatException catch (e) {
        await _resetEncryptedStorage(e);
      }
    }
  }

  static Future<void> _resetEncryptedStorage(Object error) async {
    appLogger.w(
      '[HiveCache] Encrypted storage is unreadable; resetting disposable '
      'cache and queue boxes',
      error: error,
    );
    for (final boxName in _encryptedBoxNames) {
      if (Hive.isBoxOpen(boxName)) await Hive.box<String>(boxName).close();
      await Hive.deleteBoxFromDisk(boxName);
    }
    await HiveEncryption.reset();
    await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveEncryption.cipher,
    );
    appLogger.i('[HiveCache] Encrypted boxes recreated with a fresh key');
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
  static bool isFresh(
    String uid, {
    Duration maxAge = const Duration(hours: 24),
  }) {
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
      return ChatMessageModel.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChatHistory(
    String uid,
    List<ChatMessage> messages,
  ) async {
    final limited = messages.length > _maxHistoryMessages
        ? messages.sublist(messages.length - _maxHistoryMessages)
        : messages;
    await _box.put(_chatKey(uid), ChatMessageModel.encodeList(limited));
  }

  static Future<void> clearChatHistory(String uid) async {
    await _box.delete(_chatKey(uid));
  }

  // ── Cache invalidation ────────────────────────────────────────────────────

  /// Clears every cached entry for [uid], including per-week debrief keys
  /// (`debrief_{uid}_{weekStart}`), by sweeping all box keys containing it.
  static Future<void> clearUserCache(String uid) async {
    final keysToDelete = _box.keys.where((k) => k is String && k.contains(uid));
    await _box.deleteAll(keysToDelete);
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
    String uid,
    String weekStart,
    WeeklyDebrief debrief,
  ) async {
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
