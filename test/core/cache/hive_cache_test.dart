import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fitnesbuster/core/cache/hive_cache.dart';

void main() {
  setUpAll(() async {
    Hive.init('test/.hive_cache_test');
    await Hive.openBox<String>('fitnesbuster_cache');
  });

  tearDown(() async {
    final box = Hive.box<String>('fitnesbuster_cache');
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.box<String>('fitnesbuster_cache').close();
    Hive.deleteBoxFromDisk('fitnesbuster_cache');
  });

  const testUid = 'uid_a';

  // ── AI Plans ──────────────────────────────────────────────────────────────

  group('AI plans', () {
    test('getAiPlans returns null values for missing keys', () {
      final plans = HiveCache.getAiPlans(testUid);
      expect(plans.containsKey('workoutPlan'), isTrue);
      expect(plans.containsKey('mealPlan'), isTrue);
      expect(plans['workoutPlan'], isNull);
      expect(plans['mealPlan'], isNull);
    });

    test('saveAiPlans stores and retrieves both plans', () async {
      await HiveCache.saveAiPlans(
        testUid,
        workoutPlan: 'plank 3x30s',
        mealPlan: 'oatmeal 300g',
      );
      final plans = HiveCache.getAiPlans(testUid);
      expect(plans['workoutPlan'], 'plank 3x30s');
      expect(plans['mealPlan'], 'oatmeal 300g');
    });

    test('saveAiPlans stores partial plans', () async {
      await HiveCache.saveAiPlans(testUid, mealPlan: 'rice + chicken');
      final plans = HiveCache.getAiPlans(testUid);
      expect(plans['workoutPlan'], isNull);
      expect(plans['mealPlan'], 'rice + chicken');
    });

    test('updateWorkoutPlan overwrites and updates timestamp', () async {
      await HiveCache.saveAiPlans(testUid, workoutPlan: 'v1');
      final ts1 = HiveCache.getCacheTime(testUid);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await HiveCache.updateWorkoutPlan(testUid, 'v2');

      final plans = HiveCache.getAiPlans(testUid);
      expect(plans['workoutPlan'], 'v2');
      final ts2 = HiveCache.getCacheTime(testUid);
      expect(ts2!.isAfter(ts1!), isTrue);
    });
  });

  // ── Cache metadata ────────────────────────────────────────────────────────

  group('cache metadata', () {
    test('getCacheTime returns null when no plan saved', () {
      expect(HiveCache.getCacheTime(testUid), isNull);
    });

    test('getCacheTime returns DateTime after save', () async {
      await HiveCache.saveAiPlans(testUid, workoutPlan: 'test');
      final ts = HiveCache.getCacheTime(testUid);
      expect(ts, isA<DateTime>());
      expect(DateTime.now().difference(ts!).inSeconds, lessThan(5));
    });

    test('isFresh returns false when nothing is cached', () {
      expect(HiveCache.isFresh(testUid), isFalse);
    });

    test('isFresh returns true for recently saved plan', () async {
      await HiveCache.saveAiPlans(testUid, workoutPlan: 'fresh');
      expect(
        HiveCache.isFresh(testUid, maxAge: const Duration(hours: 1)),
        isTrue,
      );
    });

    test('isFresh returns false when maxAge is zero', () async {
      await HiveCache.saveAiPlans(testUid, workoutPlan: 'stale');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(HiveCache.isFresh(testUid, maxAge: Duration.zero), isFalse);
    });

    test('hasAiPlans returns false for empty cache', () {
      expect(HiveCache.hasAiPlans(testUid), isFalse);
    });

    test('hasAiPlans returns true after workout plan saved', () async {
      await HiveCache.saveAiPlans(testUid, workoutPlan: 'plan');
      expect(HiveCache.hasAiPlans(testUid), isTrue);
    });

    test('hasAiPlans returns true after meal plan only', () async {
      await HiveCache.saveAiPlans(testUid, mealPlan: 'menu');
      expect(HiveCache.hasAiPlans(testUid), isTrue);
    });
  });

  // ── Test-week flag ────────────────────────────────────────────────────────

  group('test-week flag', () {
    test('getTestWeekCompleted returns null for missing flag', () {
      expect(HiveCache.getTestWeekCompleted(testUid), isNull);
    });

    test('setTestWeekCompleted persists true', () async {
      await HiveCache.setTestWeekCompleted(testUid);
      expect(HiveCache.getTestWeekCompleted(testUid), isTrue);
    });
  });

  // ── User isolation ────────────────────────────────────────────────────────

  group('user isolation', () {
    test('keys are isolated per user', () async {
      await HiveCache.saveAiPlans('user_A', workoutPlan: 'A_plan');
      await HiveCache.saveAiPlans('user_B', workoutPlan: 'B_plan');

      expect(HiveCache.hasAiPlans('user_A'), isTrue);
      expect(HiveCache.hasAiPlans('user_B'), isTrue);
      expect(HiveCache.getAiPlans('user_A')['workoutPlan'], 'A_plan');
      expect(HiveCache.getAiPlans('user_B')['workoutPlan'], 'B_plan');
    });

    test('clearUserCache removes only target user entries', () async {
      await HiveCache.saveAiPlans('user_A', workoutPlan: 'keep');
      await HiveCache.setTestWeekCompleted('user_A');
      await HiveCache.saveAiPlans('user_B', workoutPlan: 'delete');

      await HiveCache.clearUserCache('user_B');

      expect(HiveCache.hasAiPlans('user_A'), isTrue);
      expect(HiveCache.hasAiPlans('user_B'), isFalse);
      expect(HiveCache.getTestWeekCompleted('user_A'), isTrue);
    });
  });

  // ── Chat history ──────────────────────────────────────────────────────────

  group('chat history', () {
    test('getChatHistory returns empty list for missing data', () {
      expect(HiveCache.getChatHistory(testUid), isEmpty);
    });

    test('getChatHistory handles malformed JSON gracefully', () async {
      final box = Hive.box<String>('fitnesbuster_cache');
      await box.put('chat_history_$testUid', 'not-valid-json');
      expect(HiveCache.getChatHistory(testUid), isEmpty);
    });

    test('clearChatHistory removes stored messages', () async {
      final box = Hive.box<String>('fitnesbuster_cache');
      await box.put('chat_history_$testUid', '[]');
      await HiveCache.clearChatHistory(testUid);
      expect(box.containsKey('chat_history_$testUid'), isFalse);
    });
  });

  // ── Firestore sync flag ──────────────────────────────────────────────────

  group('sync flag', () {
    test('isSyncNeeded returns false when flag is absent', () {
      expect(HiveCache.isSyncNeeded(testUid), isFalse);
    });

    test('setNeedsSync and isSyncNeeded roundtrip', () async {
      await HiveCache.setNeedsSync(testUid);
      expect(HiveCache.isSyncNeeded(testUid), isTrue);
    });

    test('clearSyncNeeded removes the flag', () async {
      await HiveCache.setNeedsSync(testUid);
      await HiveCache.clearSyncNeeded(testUid);
      expect(HiveCache.isSyncNeeded(testUid), isFalse);
    });
  });
}
