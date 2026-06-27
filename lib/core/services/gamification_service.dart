import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

// ── Achievement model ──────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String name;
  final String desc;
  final String emoji;
  final int xpReward;
  final String category;

  const Achievement({
    required this.id,
    required this.name,
    required this.desc,
    required this.emoji,
    required this.xpReward,
    required this.category,
  });
}

// ── UserLevel model ───────────────────────────────────────────────────────────

class UserLevel {
  final int level;
  final int totalXp;
  final String name;
  final String emoji;
  final int xpForCurrent;
  final int xpForNext;
  final double progress;

  const UserLevel({
    required this.level,
    required this.totalXp,
    required this.name,
    required this.emoji,
    required this.xpForCurrent,
    required this.xpForNext,
    required this.progress,
  });

  bool get isMaxLevel => xpForNext == 0;
  int get xpInCurrentLevel => totalXp - xpForCurrent;
  int get xpNeededForNext => xpForNext - xpForCurrent;
}

// ── GamificationService ───────────────────────────────────────────────────────

class GamificationService implements IGamificationService {
  final ISettingsRepository _settings;

  GamificationService({required ISettingsRepository settings})
      : _settings = settings;

  // ── Level table ─────────────────────────────────────────────────────────────

  static final _levels = [
    (xp: 0,     name: AppLocalizations.tl('levelNewbie'),    emoji: '🌱'),
    (xp: 500,   name: AppLocalizations.tl('levelEnthusiast'),  emoji: '💪'),
    (xp: 1500,  name: AppLocalizations.tl('levelAthlete'),      emoji: '🔥'),
    (xp: 3000,  name: AppLocalizations.tl('levelWarrior'),       emoji: '🏋️'),
    (xp: 5000,  name: AppLocalizations.tl('levelChampion'),    emoji: '⚡'),
    (xp: 8000,  name: AppLocalizations.tl('levelLegend'),    emoji: '🚀'),
    (xp: 12000, name: AppLocalizations.tl('levelElite'),      emoji: '👑'),
    (xp: 18000, name: AppLocalizations.tl('levelMaster'),     emoji: '🧬'),
    (xp: 25000, name: AppLocalizations.tl('levelTitan'),      emoji: '🌟'),
  ];

  // ── Achievement catalogue (static const — pure data) ────────────────────────

  static final List<Achievement> allAchievements = [
    Achievement(id: 'first_workout', name: AppLocalizations.tl('achFirstStep'),    desc: AppLocalizations.tl('achFirstStepDesc'),  emoji: '🎯', xpReward: 150, category: 'workout'),
    Achievement(id: 'workout_10',    name: AppLocalizations.tl('achOnRise'),    desc: AppLocalizations.tl('achOnRiseDesc'),     emoji: '🏃', xpReward: 100, category: 'workout'),
    Achievement(id: 'workout_50',    name: AppLocalizations.tl('achFifty'),        desc: AppLocalizations.tl('achFiftyDesc'),     emoji: '💪', xpReward: 250, category: 'workout'),
    Achievement(id: 'workout_100',   name: AppLocalizations.tl('achCenturion'),        desc: AppLocalizations.tl('achCenturionDesc'),    emoji: '🏆', xpReward: 500, category: 'workout'),
    Achievement(id: 'workout_200',   name: AppLocalizations.tl('achMachine'),        desc: AppLocalizations.tl('achMachineDesc'),    emoji: '🤖', xpReward: 1000, category: 'workout'),
    Achievement(id: 'streak_3',   name: AppLocalizations.tl('achStreak3'),    desc: AppLocalizations.tl('achStreak3Desc'),  emoji: '🔥', xpReward: 50,   category: 'streak'),
    Achievement(id: 'streak_7',   name: AppLocalizations.tl('achStreak7'), desc: AppLocalizations.tl('achStreak7Desc'),             emoji: '🔥', xpReward: 200,  category: 'streak'),
    Achievement(id: 'streak_14',  name: AppLocalizations.tl('achStreak14'),     desc: AppLocalizations.tl('achStreak14Desc'),            emoji: '🚀', xpReward: 300,  category: 'streak'),
    Achievement(id: 'streak_30',  name: AppLocalizations.tl('achStreak30'),   desc: AppLocalizations.tl('achStreak30Desc'),            emoji: '⚡', xpReward: 500,  category: 'streak'),
    Achievement(id: 'streak_100', name: AppLocalizations.tl('achStreak100'),  desc: AppLocalizations.tl('achStreak100Desc'),           emoji: '👑', xpReward: 1000, category: 'streak'),
    Achievement(id: 'first_pr', name: AppLocalizations.tl('achFirstPr'),   desc: AppLocalizations.tl('achFirstPrDesc'),    emoji: '🏅', xpReward: 100, category: 'pr'),
    Achievement(id: 'pr_5',     name: AppLocalizations.tl('achPrStreak'),   desc: AppLocalizations.tl('achPrStreakDesc'),       emoji: '🥈', xpReward: 150, category: 'pr'),
    Achievement(id: 'pr_10',    name: AppLocalizations.tl('achRecordman'),       desc: AppLocalizations.tl('achRecordmanDesc'),      emoji: '🥇', xpReward: 250, category: 'pr'),
    Achievement(id: 'pr_25',    name: AppLocalizations.tl('achProgressMachine'), desc: AppLocalizations.tl('achProgressMachineDesc'),      emoji: '🏆', xpReward: 500, category: 'pr'),
    Achievement(id: 'first_meal',     name: AppLocalizations.tl('achFirstMeal'),       desc: AppLocalizations.tl('achFirstMealDesc'),       emoji: '🥗', xpReward: 50,  category: 'nutrition'),
    Achievement(id: 'full_day_meals', name: AppLocalizations.tl('achCleanDay'), desc: AppLocalizations.tl('achCleanDayDesc'),      emoji: '🍽️', xpReward: 100, category: 'nutrition'),
    Achievement(id: 'week_nutrition', name: AppLocalizations.tl('achCleanWeek'),      desc: AppLocalizations.tl('achCleanWeekDesc'), emoji: '🥦', xpReward: 300, category: 'nutrition'),
    Achievement(id: 'water_goal',  name: AppLocalizations.tl('achWaterBalance'),  desc: AppLocalizations.tl('achWaterBalanceDesc'),        emoji: '💧', xpReward: 50,  category: 'water'),
    Achievement(id: 'water_3l',    name: AppLocalizations.tl('achOcean'),          desc: AppLocalizations.tl('achOceanDesc'),           emoji: '🌊', xpReward: 100, category: 'water'),
    Achievement(id: 'water_7days', name: AppLocalizations.tl('achHydrate7'),desc: AppLocalizations.tl('achHydrate7Desc'),emoji: '💦', xpReward: 200, category: 'water'),
    Achievement(id: 'steps_10k',   name: AppLocalizations.tl('ach10kSteps'), desc: AppLocalizations.tl('ach10kStepsDesc'),      emoji: '👟', xpReward: 75,  category: 'health'),
    Achievement(id: 'steps_10k_7', name: AppLocalizations.tl('achMarathoner'),    desc: AppLocalizations.tl('achMarathonerDesc'),      emoji: '🏃', xpReward: 300, category: 'health'),
    Achievement(id: 'profile_complete', name: AppLocalizations.tl('achProfileFilled'), desc: AppLocalizations.tl('achProfileFilledDesc'),       emoji: '📋', xpReward: 100, category: 'app'),
    Achievement(id: 'test_week_done',   name: AppLocalizations.tl('achTestDone'),     desc: AppLocalizations.tl('achTestDoneDesc'),          emoji: '🎓', xpReward: 200, category: 'app'),
    Achievement(id: 'ai_plan_created',  name: AppLocalizations.tl('achAiPlan'),  desc: AppLocalizations.tl('achAiPlanDesc'),      emoji: '🤖', xpReward: 100, category: 'app'),
    Achievement(id: 'first_debrief',    name: AppLocalizations.tl('achWeekAnalysis'),    desc: AppLocalizations.tl('achWeekAnalysisDesc'),emoji: '📊', xpReward: 100, category: 'app'),
    Achievement(id: 'level_3', name: AppLocalizations.tl('achLevelAthlete'),   desc: AppLocalizations.tl('achLevelAthleteDesc'), emoji: '🔥', xpReward: 100, category: 'level'),
    Achievement(id: 'level_5', name: AppLocalizations.tl('achLevelChampion'), desc: AppLocalizations.tl('achLevelChampionDesc'), emoji: '⚡', xpReward: 200, category: 'level'),
    Achievement(id: 'level_7', name: AppLocalizations.tl('achLevelElite'),   desc: AppLocalizations.tl('achLevelEliteDesc'), emoji: '👑', xpReward: 500, category: 'level'),
    Achievement(id: 'early_bird', name: AppLocalizations.tl('achEarlyBird'), desc: AppLocalizations.tl('achEarlyBirdDesc'),  emoji: '🌅', xpReward: 100, category: 'special'),
    Achievement(id: 'night_owl',  name: AppLocalizations.tl('achNightOwl'),  desc: AppLocalizations.tl('achNightOwlDesc'),          emoji: '🦉', xpReward: 100, category: 'special'),
  ];

  // ── XP methods ───────────────────────────────────────────────────────────────

  @override
  Future<int> getTotalXp() => _settings.getGamificationXp();

  @override
  Future<int> addXp(int amount) async {
    if (amount <= 0) return getTotalXp();
    final next = (await _settings.getGamificationXp()) + amount;
    await _settings.setGamificationXp(next);
    return next;
  }

  // Pure utility — remains static so call sites need no DI.
  static UserLevel computeLevel(int totalXp) {
    int idx = 0;
    for (int i = _levels.length - 1; i >= 0; i--) {
      if (totalXp >= _levels[i].xp) { idx = i; break; }
    }
    final xpCurrent = _levels[idx].xp;
    final xpNext    = idx + 1 < _levels.length ? _levels[idx + 1].xp : 0;
    final progress  = xpNext > 0
        ? ((totalXp - xpCurrent) / (xpNext - xpCurrent)).clamp(0.0, 1.0)
        : 1.0;
    return UserLevel(
      level: idx + 1,
      totalXp: totalXp,
      name: _levels[idx].name,
      emoji: _levels[idx].emoji,
      xpForCurrent: xpCurrent,
      xpForNext: xpNext,
      progress: progress,
    );
  }

  // ── Achievements ─────────────────────────────────────────────────────────────

  @override
  Future<Set<String>> getUnlockedIds() async =>
      (await _settings.getGamificationUnlocked()).toSet();

  @override
  Future<int> unlock(String achievementId) async {
    final ids = await getUnlockedIds();
    if (ids.contains(achievementId)) return 0;
    ids.add(achievementId);
    await _settings.setGamificationUnlocked(ids.toList());
    final a = allAchievements.where((a) => a.id == achievementId).firstOrNull;
    if (a == null) return 0;
    await addXp(a.xpReward);
    return a.xpReward;
  }

  // ── Counters ─────────────────────────────────────────────────────────────────

  @override
  Future<int> incrementWorkouts() async {
    final n = (await _settings.getGamificationTotalWorkouts()) + 1;
    await _settings.setGamificationTotalWorkouts(n);
    return n;
  }

  @override
  Future<int> getTotalWorkouts() => _settings.getGamificationTotalWorkouts();

  @override
  Future<int> incrementPr() async {
    final n = (await _settings.getGamificationTotalPr()) + 1;
    await _settings.setGamificationTotalPr(n);
    return n;
  }

  @override
  Future<int> getTotalPr() => _settings.getGamificationTotalPr();

  // ── Reward triggers ───────────────────────────────────────────────────────────

  @override
  Future<int> onWorkoutCompleted({
    required int streak,
    required int workoutHour,
  }) async {
    int earned = 100;
    await addXp(100);

    final total = await incrementWorkouts();
    if (total == 1)   earned += await unlock('first_workout');
    if (total == 10)  earned += await unlock('workout_10');
    if (total == 50)  earned += await unlock('workout_50');
    if (total == 100) earned += await unlock('workout_100');
    if (total == 200) earned += await unlock('workout_200');

    if (streak >= 3)   earned += await unlock('streak_3');
    if (streak >= 7)   earned += await unlock('streak_7');
    if (streak >= 14)  earned += await unlock('streak_14');
    if (streak >= 30)  earned += await unlock('streak_30');
    if (streak >= 100) earned += await unlock('streak_100');

    if (workoutHour < 8)   earned += await unlock('early_bird');
    if (workoutHour >= 22) earned += await unlock('night_owl');

    final xp  = await getTotalXp();
    final lvl = computeLevel(xp).level;
    if (lvl >= 3) earned += await unlock('level_3');
    if (lvl >= 5) earned += await unlock('level_5');
    if (lvl >= 7) earned += await unlock('level_7');

    return earned;
  }

  @override
  Future<int> onPrSet() async {
    int earned = 75;
    await addXp(75);
    final total = await incrementPr();
    if (total == 1)  earned += await unlock('first_pr');
    if (total == 5)  earned += await unlock('pr_5');
    if (total == 10) earned += await unlock('pr_10');
    if (total == 25) earned += await unlock('pr_25');
    return earned;
  }

  @override
  Future<int> onWaterGoalReached({required bool over3L}) async {
    int earned = 20;
    await addXp(20);
    earned += await unlock('water_goal');
    if (over3L) earned += await unlock('water_3l');
    return earned;
  }

  @override
  Future<int> onAllMealsCompleted() async {
    int earned = 30;
    await addXp(30);
    earned += await unlock('full_day_meals');
    return earned;
  }

  @override
  Future<void> onAiPlanCreated() => unlock('ai_plan_created');

  @override
  Future<void> onTestWeekCompleted() => unlock('test_week_done');

  @override
  Future<void> onDebriefReceived() => unlock('first_debrief');
}
