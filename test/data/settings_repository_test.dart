import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';

import 'settings_repository_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ISettingsRepository>()])
void main() {
  late MockISettingsRepository repo;

  const tKey = '2024-06-20';
  const tDate = '2024-06-20';

  setUp(() => repo = MockISettingsRepository());

  // ── Workout stats ───────────────────────────────────────────────────────

  group('workout done', () {
    test('get defaults to false', () async {
      when(repo.getWorkoutDone(tKey)).thenAnswer((_) async => false);
      expect(await repo.getWorkoutDone(tKey), false);
    });

    test('set then get returns true', () async {
      when(repo.getWorkoutDone(tKey)).thenAnswer((_) async => true);
      await repo.setWorkoutDone(tKey, true);
      expect(await repo.getWorkoutDone(tKey), true);
      verify(repo.setWorkoutDone(tKey, true)).called(1);
    });
  });

  group('workout kcal', () {
    test('get defaults to 0', () async {
      when(repo.getWorkoutKcal(tKey)).thenAnswer((_) async => 0);
      expect(await repo.getWorkoutKcal(tKey), 0);
    });

    test('set 350 then get returns 350', () async {
      when(repo.getWorkoutKcal(tKey)).thenAnswer((_) async => 350);
      await repo.setWorkoutKcal(tKey, 350);
      expect(await repo.getWorkoutKcal(tKey), 350);
    });
  });

  group('workout sets', () {
    test('set/get roundtrip', () async {
      when(repo.getWorkoutSets(tKey)).thenAnswer((_) async => 12);
      await repo.setWorkoutSets(tKey, 12);
      expect(await repo.getWorkoutSets(tKey), 12);
    });
  });

  group('workout time', () {
    test('set/get roundtrip', () async {
      when(repo.getWorkoutTime(tKey)).thenAnswer((_) async => 780);
      await repo.setWorkoutTime(tKey, 780);
      expect(await repo.getWorkoutTime(tKey), 780);
    });
  });

  group('workout rating', () {
    test('set/get roundtrip', () async {
      when(repo.getWorkoutRating(tKey)).thenAnswer((_) async => 5);
      await repo.setWorkoutRating(tKey, 5);
      expect(await repo.getWorkoutRating(tKey), 5);
    });
  });

  group('workout log detail', () {
    test('get returns null when not set', () async {
      when(repo.getWorkoutLogDetail(tKey)).thenAnswer((_) async => null);
      expect(await repo.getWorkoutLogDetail(tKey), isNull);
    });

    test('set/get roundtrip', () async {
      const json = '{"exercises":[]}';
      when(repo.getWorkoutLogDetail(tKey)).thenAnswer((_) async => json);
      await repo.setWorkoutLogDetail(tKey, json);
      expect(await repo.getWorkoutLogDetail(tKey), json);
    });
  });

  group('streak', () {
    test('get defaults to 0', () async {
      when(repo.getWorkoutStreak()).thenAnswer((_) async => 0);
      expect(await repo.getWorkoutStreak(), 0);
    });

    test('set 7 then get returns 7', () async {
      when(repo.getWorkoutStreak()).thenAnswer((_) async => 7);
      await repo.setWorkoutStreak(7);
      expect(await repo.getWorkoutStreak(), 7);
    });
  });

  group('last workout date', () {
    test('get returns null when not set', () async {
      when(repo.getLastWorkoutDate()).thenAnswer((_) async => null);
      expect(await repo.getLastWorkoutDate(), isNull);
    });

    test('set/get roundtrip', () async {
      when(repo.getLastWorkoutDate()).thenAnswer((_) async => tDate);
      await repo.setLastWorkoutDate(tDate);
      expect(await repo.getLastWorkoutDate(), tDate);
    });
  });

  // ── Nutrition ────────────────────────────────────────────────────────────

  group('eaten cal', () {
    test('set/get roundtrip', () async {
      when(repo.getEatenCal(tKey)).thenAnswer((_) async => 2200);
      await repo.setEatenCal(tKey, 2200);
      expect(await repo.getEatenCal(tKey), 2200);
    });
  });

  group('target cal', () {
    test('set/get roundtrip', () async {
      when(repo.getTargetCal(tKey)).thenAnswer((_) async => 2500);
      await repo.setTargetCal(tKey, 2500);
      expect(await repo.getTargetCal(tKey), 2500);
    });
  });

  group('water ml', () {
    test('set/get roundtrip', () async {
      when(repo.getWaterMl(tKey)).thenAnswer((_) async => 2000);
      await repo.setWaterMl(tKey, 2000);
      expect(await repo.getWaterMl(tKey), 2000);
    });
  });

  group('water glasses', () {
    test('set/get roundtrip', () async {
      when(repo.getWaterGlasses(tKey)).thenAnswer((_) async => 8);
      await repo.setWaterGlasses(tKey, 8);
      expect(await repo.getWaterGlasses(tKey), 8);
    });
  });

  group('meals done', () {
    test('get defaults to empty list', () async {
      when(repo.getMealsDone(tKey)).thenAnswer((_) async => []);
      expect(await repo.getMealsDone(tKey), isEmpty);
    });

    test('set/get roundtrip', () async {
      final meals = ['breakfast', 'lunch'];
      when(repo.getMealsDone(tKey)).thenAnswer((_) async => meals);
      await repo.setMealsDone(tKey, meals);
      expect(await repo.getMealsDone(tKey), meals);
    });
  });

  group('manual foods', () {
    test('set/get roundtrip', () async {
      final foods = ['egg|2|160', 'oats|1|300'];
      when(repo.getManualFoods(tKey)).thenAnswer((_) async => foods);
      await repo.setManualFoods(tKey, foods);
      expect(await repo.getManualFoods(tKey), foods);
    });
  });

  // ── Health ───────────────────────────────────────────────────────────────

  group('manual steps', () {
    test('set/get roundtrip', () async {
      when(repo.getManualSteps(tKey)).thenAnswer((_) async => 8000);
      await repo.setManualSteps(tKey, 8000);
      expect(await repo.getManualSteps(tKey), 8000);
    });
  });

  group('manual heart rate', () {
    test('set/get roundtrip', () async {
      when(repo.getManualHeartRate(tKey)).thenAnswer((_) async => 72);
      await repo.setManualHeartRate(tKey, 72);
      expect(await repo.getManualHeartRate(tKey), 72);
    });
  });

  // ── Avatar ───────────────────────────────────────────────────────────────

  group('avatar mode', () {
    test('get returns null when not set', () async {
      when(repo.getAvatarMode()).thenAnswer((_) async => null);
      expect(await repo.getAvatarMode(), isNull);
    });

    test('set/get roundtrip', () async {
      when(repo.getAvatarMode()).thenAnswer((_) async => 'custom');
      await repo.setAvatarMode('custom');
      expect(await repo.getAvatarMode(), 'custom');
    });
  });

  group('avatar preset index', () {
    test('set/get roundtrip', () async {
      when(repo.getAvatarPresetIndex()).thenAnswer((_) async => 3);
      await repo.setAvatarPresetIndex(3);
      expect(await repo.getAvatarPresetIndex(), 3);
    });
  });

  group('avatar custom path', () {
    test('set/get roundtrip', () async {
      const path = '/data/avatar.png';
      when(repo.getAvatarCustomPath()).thenAnswer((_) async => path);
      await repo.setAvatarCustomPath(path);
      expect(await repo.getAvatarCustomPath(), path);
    });
  });

  // ── Persisted lists ──────────────────────────────────────────────────────

  group('shopping list', () {
    test('get defaults to empty list', () async {
      when(repo.getShoppingListChecked()).thenAnswer((_) async => []);
      expect(await repo.getShoppingListChecked(), isEmpty);
    });

    test('set/get roundtrip', () async {
      final items = ['курица', 'рис'];
      when(repo.getShoppingListChecked()).thenAnswer((_) async => items);
      await repo.setShoppingListChecked(items);
      expect(await repo.getShoppingListChecked(), items);
    });
  });

  group('calendar overrides', () {
    test('get returns null when not set', () async {
      when(repo.getCalendarOverrides()).thenAnswer((_) async => null);
      expect(await repo.getCalendarOverrides(), isNull);
    });

    test('set/get roundtrip', () async {
      const json = '{"2024-06-20":"legs"}';
      when(repo.getCalendarOverrides()).thenAnswer((_) async => json);
      await repo.setCalendarOverrides(json);
      expect(await repo.getCalendarOverrides(), json);
    });
  });

  // ── Gamification ─────────────────────────────────────────────────────────

  group('gamification xp', () {
    test('get defaults to 0', () async {
      when(repo.getGamificationXp()).thenAnswer((_) async => 0);
      expect(await repo.getGamificationXp(), 0);
    });

    test('set/get roundtrip', () async {
      when(repo.getGamificationXp()).thenAnswer((_) async => 1500);
      await repo.setGamificationXp(1500);
      expect(await repo.getGamificationXp(), 1500);
    });
  });

  group('gamification unlocked', () {
    test('get defaults to empty list', () async {
      when(repo.getGamificationUnlocked()).thenAnswer((_) async => []);
      expect(await repo.getGamificationUnlocked(), isEmpty);
    });

    test('set/get roundtrip', () async {
      final ids = ['first_workout', 'streak_3'];
      when(repo.getGamificationUnlocked()).thenAnswer((_) async => ids);
      await repo.setGamificationUnlocked(ids);
      expect(await repo.getGamificationUnlocked(), ids);
    });
  });

  group('gamification total workouts', () {
    test('set/get roundtrip', () async {
      when(repo.getGamificationTotalWorkouts()).thenAnswer((_) async => 42);
      await repo.setGamificationTotalWorkouts(42);
      expect(await repo.getGamificationTotalWorkouts(), 42);
    });
  });

  group('gamification total pr', () {
    test('set/get roundtrip', () async {
      when(repo.getGamificationTotalPr()).thenAnswer((_) async => 15);
      await repo.setGamificationTotalPr(15);
      expect(await repo.getGamificationTotalPr(), 15);
    });
  });
}
