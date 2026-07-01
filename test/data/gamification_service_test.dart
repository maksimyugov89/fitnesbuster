import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';

import 'gamification_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ISettingsRepository>()])
void main() {
  late MockISettingsRepository settings;
  late GamificationService service;

  setUp(() {
    settings = MockISettingsRepository();
    service = GamificationService(settings: settings);
  });

  // ── computeLevel (static utility) ────────────────────────────────────────

  group('computeLevel', () {
    test('0 xp = level 1', () {
      final lvl = GamificationService.computeLevel(0);
      expect(lvl.level, 1);
      expect(lvl.name, isNotEmpty);
      expect(lvl.emoji, '🌱');
      expect(lvl.xpForCurrent, 0);
      expect(lvl.xpForNext, 500);
      expect(lvl.progress, 0);
      expect(lvl.isMaxLevel, false);
    });

    test('500 xp = level 2', () {
      final lvl = GamificationService.computeLevel(500);
      expect(lvl.level, 2);
      expect(lvl.name, isNotEmpty);
      expect(lvl.xpForCurrent, 500);
      expect(lvl.progress, 0);
    });

    test('800 xp = level 2 at 30% progress', () {
      final lvl = GamificationService.computeLevel(800);
      expect(lvl.level, 2);
      expect(lvl.progress, closeTo(0.3, 0.01));
    });

    test('1500 xp = level 3', () {
      final lvl = GamificationService.computeLevel(1500);
      expect(lvl.level, 3);
      expect(lvl.name, isNotEmpty);
    });

    test('3000 xp = level 4', () {
      final lvl = GamificationService.computeLevel(3000);
      expect(lvl.level, 4);
    });

    test('5000 xp = level 5', () {
      final lvl = GamificationService.computeLevel(5000);
      expect(lvl.level, 5);
    });

    test('8000 xp = level 6', () {
      final lvl = GamificationService.computeLevel(8000);
      expect(lvl.level, 6);
    });

    test('12000 xp = level 7', () {
      final lvl = GamificationService.computeLevel(12000);
      expect(lvl.level, 7);
      expect(lvl.name, isNotEmpty);
    });

    test('18000 xp = level 8', () {
      final lvl = GamificationService.computeLevel(18000);
      expect(lvl.level, 8);
    });

    test('25000 xp = level 9 Titan (max)', () {
      final lvl = GamificationService.computeLevel(25000);
      expect(lvl.level, 9);
      expect(lvl.name, isNotEmpty);
      expect(lvl.xpForNext, 0);
      expect(lvl.isMaxLevel, true);
      expect(lvl.progress, 1.0);
    });

    test('50000 xp = still level 9 Titan (beyond max)', () {
      final lvl = GamificationService.computeLevel(50000);
      expect(lvl.level, 9);
      expect(lvl.isMaxLevel, true);
      expect(lvl.progress, 1.0);
    });
  });

  // ── getTotalXp / addXp ───────────────────────────────────────────────────

  group('xp management', () {
    test('getTotalXp delegates to settings', () async {
      when(settings.getGamificationXp()).thenAnswer((_) async => 500);
      expect(await service.getTotalXp(), 500);
    });

    test('addXp increases and returns new total', () async {
      when(settings.getGamificationXp()).thenAnswer((_) async => 500);
      when(settings.setGamificationXp(700)).thenAnswer((_) async {});

      final total = await service.addXp(200);
      expect(total, 700);
      verify(settings.setGamificationXp(700)).called(1);
    });

    test('addXp with zero returns current without writing', () async {
      when(settings.getGamificationXp()).thenAnswer((_) async => 500);

      final total = await service.addXp(0);
      expect(total, 500);
      verifyNever(settings.setGamificationXp(any));
    });

    test('addXp with negative returns current without writing', () async {
      when(settings.getGamificationXp()).thenAnswer((_) async => 500);

      final total = await service.addXp(-100);
      expect(total, 500);
      verifyNever(settings.setGamificationXp(any));
    });
  });

  // ── getUnlockedIds / unlock ──────────────────────────────────────────────

  group('achievements', () {
    test('getUnlockedIds delegates to settings', () async {
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      expect(await service.getUnlockedIds(), <String>{});
    });

    test('unlock new achievement adds xp reward', () async {
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(
        settings.setGamificationUnlocked(['first_workout']),
      ).thenAnswer((_) async {});
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(150)).thenAnswer((_) async {});

      final earned = await service.unlock('first_workout');
      expect(earned, 150);
      verify(settings.setGamificationUnlocked(['first_workout'])).called(1);
      verify(settings.setGamificationXp(150)).called(1);
    });

    test('unlock already unlocked returns 0', () async {
      when(
        settings.getGamificationUnlocked(),
      ).thenAnswer((_) async => ['first_workout']);

      final earned = await service.unlock('first_workout');
      expect(earned, 0);
      verifyNever(settings.setGamificationUnlocked(any));
    });

    test('unlock unknown achievement id returns 0', () async {
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);

      final earned = await service.unlock('nonexistent');
      expect(earned, 0);
      verifyNever(settings.setGamificationXp(any));
    });
  });

  // ── incrementWorkouts / getTotalWorkouts ─────────────────────────────────

  group('workout counter', () {
    test('getTotalWorkouts delegates to settings', () async {
      when(settings.getGamificationTotalWorkouts()).thenAnswer((_) async => 10);
      expect(await service.getTotalWorkouts(), 10);
    });

    test('incrementWorkouts returns new count', () async {
      when(settings.getGamificationTotalWorkouts()).thenAnswer((_) async => 0);
      when(settings.setGamificationTotalWorkouts(1)).thenAnswer((_) async {});

      final count = await service.incrementWorkouts();
      expect(count, 1);
    });

    test('incrementWorkouts stacks', () async {
      when(settings.getGamificationTotalWorkouts()).thenAnswer((_) async => 9);
      when(settings.setGamificationTotalWorkouts(10)).thenAnswer((_) async {});

      final count = await service.incrementWorkouts();
      expect(count, 10);
    });
  });

  // ── incrementPr / getTotalPr ─────────────────────────────────────────────

  group('pr counter', () {
    test('getTotalPr delegates to settings', () async {
      when(settings.getGamificationTotalPr()).thenAnswer((_) async => 5);
      expect(await service.getTotalPr(), 5);
    });

    test('incrementPr returns new count', () async {
      when(settings.getGamificationTotalPr()).thenAnswer((_) async => 0);
      when(settings.setGamificationTotalPr(1)).thenAnswer((_) async {});

      final count = await service.incrementPr();
      expect(count, 1);
    });
  });

  // ── onWorkoutCompleted (integration trigger) ─────────────────────────────

  group('onWorkoutCompleted', () {
    setUp(() {
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(any)).thenAnswer((_) async {});
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(settings.setGamificationUnlocked(any)).thenAnswer((_) async {});
      when(settings.getGamificationTotalWorkouts()).thenAnswer((_) async => 0);
      when(settings.setGamificationTotalWorkouts(any)).thenAnswer((_) async {});
    });

    test('first workout unlocks first_workout achievement', () async {
      final earned = await service.onWorkoutCompleted(
        streak: 1,
        workoutHour: 12,
      );
      // 100 base + 150 first_workout = 250
      expect(earned, 250);
    });

    test('streak 7 unlocks streak_7 achievement', () async {
      when(settings.getGamificationTotalWorkouts()).thenAnswer((_) async => 10);
      when(settings.setGamificationTotalWorkouts(11)).thenAnswer((_) async {});

      final earned = await service.onWorkoutCompleted(
        streak: 7,
        workoutHour: 12,
      );
      expect(earned, greaterThanOrEqualTo(300));
    });

    test('early morning unlocks early_bird', () async {
      when(settings.getGamificationTotalWorkouts()).thenAnswer((_) async => 10);
      when(settings.setGamificationTotalWorkouts(11)).thenAnswer((_) async {});

      final earned = await service.onWorkoutCompleted(
        streak: 1,
        workoutHour: 6,
      );
      expect(earned, greaterThanOrEqualTo(200));
    });

    test('night workout unlocks night_owl', () async {
      when(settings.getGamificationTotalWorkouts()).thenAnswer((_) async => 10);
      when(settings.setGamificationTotalWorkouts(11)).thenAnswer((_) async {});

      final earned = await service.onWorkoutCompleted(
        streak: 1,
        workoutHour: 23,
      );
      expect(earned, greaterThanOrEqualTo(200));
    });
  });

  // ── onPrSet ──────────────────────────────────────────────────────────────

  group('onPrSet', () {
    setUp(() {
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(any)).thenAnswer((_) async {});
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(settings.setGamificationUnlocked(any)).thenAnswer((_) async {});
      when(settings.getGamificationTotalPr()).thenAnswer((_) async => 0);
      when(settings.setGamificationTotalPr(any)).thenAnswer((_) async {});
    });

    test('first PR unlocks first_pr', () async {
      final earned = await service.onPrSet();
      // 75 base + 100 first_pr = 175
      expect(earned, 175);
    });
  });

  // ── onWaterGoalReached ───────────────────────────────────────────────────

  group('onWaterGoalReached', () {
    setUp(() {
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(any)).thenAnswer((_) async {});
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(settings.setGamificationUnlocked(any)).thenAnswer((_) async {});
    });

    test('normal water goal', () async {
      final earned = await service.onWaterGoalReached(over3L: false);
      // 20 base + 50 water_goal = 70
      expect(earned, 70);
    });

    test('over 3L also unlocks water_3l', () async {
      final earned = await service.onWaterGoalReached(over3L: true);
      // 20 base + 50 water_goal + 100 water_3l = 170
      expect(earned, 170);
    });
  });

  // ── onAllMealsCompleted ──────────────────────────────────────────────────

  group('onAllMealsCompleted', () {
    setUp(() {
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(any)).thenAnswer((_) async {});
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(settings.setGamificationUnlocked(any)).thenAnswer((_) async {});
    });

    test('unlocks full_day_meals', () async {
      final earned = await service.onAllMealsCompleted();
      // 30 base + 100 full_day_meals = 130
      expect(earned, 130);
    });
  });

  // ── Passive triggers ─────────────────────────────────────────────────────

  group('passive triggers', () {
    test('onAiPlanCreated unlocks ai_plan_created', () async {
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(settings.setGamificationUnlocked(any)).thenAnswer((_) async {});
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(100)).thenAnswer((_) async {});

      await service.onAiPlanCreated();
      verify(settings.setGamificationUnlocked(['ai_plan_created'])).called(1);
      verify(settings.setGamificationXp(100)).called(1);
    });

    test('onTestWeekCompleted unlocks test_week_done', () async {
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(settings.setGamificationUnlocked(any)).thenAnswer((_) async {});
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(200)).thenAnswer((_) async {});

      await service.onTestWeekCompleted();
      verify(settings.setGamificationUnlocked(['test_week_done'])).called(1);
      verify(settings.setGamificationXp(200)).called(1);
    });

    test('onDebriefReceived unlocks first_debrief', () async {
      when(settings.getGamificationUnlocked()).thenAnswer((_) async => []);
      when(settings.setGamificationUnlocked(any)).thenAnswer((_) async {});
      when(settings.getGamificationXp()).thenAnswer((_) async => 0);
      when(settings.setGamificationXp(100)).thenAnswer((_) async {});

      await service.onDebriefReceived();
      verify(settings.setGamificationUnlocked(['first_debrief'])).called(1);
    });
  });
}
