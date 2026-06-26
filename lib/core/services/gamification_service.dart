import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';

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

  static const _levels = [
    (xp: 0,     name: 'Новичок',    emoji: '🌱'),
    (xp: 500,   name: 'Энтузиаст',  emoji: '💪'),
    (xp: 1500,  name: 'Атлет',      emoji: '🔥'),
    (xp: 3000,  name: 'Воин',       emoji: '🏋️'),
    (xp: 5000,  name: 'Чемпион',    emoji: '⚡'),
    (xp: 8000,  name: 'Легенда',    emoji: '🚀'),
    (xp: 12000, name: 'Elite',      emoji: '👑'),
    (xp: 18000, name: 'Master',     emoji: '🧬'),
    (xp: 25000, name: 'Titan',      emoji: '🌟'),
  ];

  // ── Achievement catalogue (static const — pure data) ────────────────────────

  static const List<Achievement> allAchievements = [
    Achievement(id: 'first_workout', name: 'Первый шаг',    desc: 'Завершил первую тренировку',  emoji: '🎯', xpReward: 150, category: 'workout'),
    Achievement(id: 'workout_10',    name: 'На разгоне',    desc: '10 тренировок завершено',     emoji: '🏃', xpReward: 100, category: 'workout'),
    Achievement(id: 'workout_50',    name: 'Полста',        desc: '50 тренировок завершено',     emoji: '💪', xpReward: 250, category: 'workout'),
    Achievement(id: 'workout_100',   name: 'Сотник',        desc: '100 тренировок завершено',    emoji: '🏆', xpReward: 500, category: 'workout'),
    Achievement(id: 'workout_200',   name: 'Машина',        desc: '200 тренировок завершено',    emoji: '🤖', xpReward: 1000, category: 'workout'),
    Achievement(id: 'streak_3',   name: '3 дня подряд',    desc: '3-дневная серия тренировок',  emoji: '🔥', xpReward: 50,   category: 'streak'),
    Achievement(id: 'streak_7',   name: 'Неделя без пауз', desc: '7-дневная серия',             emoji: '🔥', xpReward: 200,  category: 'streak'),
    Achievement(id: 'streak_14',  name: 'Две недели!',     desc: '14-дневная серия',            emoji: '🚀', xpReward: 300,  category: 'streak'),
    Achievement(id: 'streak_30',  name: 'Железная воля',   desc: '30-дневная серия',            emoji: '⚡', xpReward: 500,  category: 'streak'),
    Achievement(id: 'streak_100', name: 'Легенда стрика',  desc: '100-дневная серия',           emoji: '👑', xpReward: 1000, category: 'streak'),
    Achievement(id: 'first_pr', name: 'Личный рекорд!',   desc: 'Установил первый PR',    emoji: '🏅', xpReward: 100, category: 'pr'),
    Achievement(id: 'pr_5',     name: 'Серия рекордов',   desc: '5 PR установлено',       emoji: '🥈', xpReward: 150, category: 'pr'),
    Achievement(id: 'pr_10',    name: 'Рекордсмен',       desc: '10 PR установлено',      emoji: '🥇', xpReward: 250, category: 'pr'),
    Achievement(id: 'pr_25',    name: 'Машина прогресса', desc: '25 PR установлено',      emoji: '🏆', xpReward: 500, category: 'pr'),
    Achievement(id: 'first_meal',     name: 'Первый приём',       desc: 'Отметил первый приём пищи',       emoji: '🥗', xpReward: 50,  category: 'nutrition'),
    Achievement(id: 'full_day_meals', name: 'День без нарушений', desc: 'Все приёмы пищи выполнены',      emoji: '🍽️', xpReward: 100, category: 'nutrition'),
    Achievement(id: 'week_nutrition', name: 'Чистая неделя',      desc: '7 дней — все приёмы выполнены', emoji: '🥦', xpReward: 300, category: 'nutrition'),
    Achievement(id: 'water_goal',  name: 'Водный баланс',  desc: 'Достиг нормы воды за день',        emoji: '💧', xpReward: 50,  category: 'water'),
    Achievement(id: 'water_3l',    name: 'Океан',          desc: 'Выпил 3000+ мл за день',           emoji: '🌊', xpReward: 100, category: 'water'),
    Achievement(id: 'water_7days', name: '7 дней гидрации',desc: '7 дней подряд выполнена норма воды',emoji: '💦', xpReward: 200, category: 'water'),
    Achievement(id: 'steps_10k',   name: '10 000 шагов', desc: 'Прошёл 10 000 шагов за день',      emoji: '👟', xpReward: 75,  category: 'health'),
    Achievement(id: 'steps_10k_7', name: 'Марафонец',    desc: '7 дней подряд 10 000+ шагов',      emoji: '🏃', xpReward: 300, category: 'health'),
    Achievement(id: 'profile_complete', name: 'Профиль заполнен', desc: 'Заполнил все данные профиля',       emoji: '📋', xpReward: 100, category: 'app'),
    Achievement(id: 'test_week_done',   name: 'Тест пройден',     desc: 'Завершил тестовую неделю',          emoji: '🎓', xpReward: 200, category: 'app'),
    Achievement(id: 'ai_plan_created',  name: 'AI-план активен',  desc: 'Получил персональный AI-план',      emoji: '🤖', xpReward: 100, category: 'app'),
    Achievement(id: 'first_debrief',    name: 'Анализ недели',    desc: 'Получил первый еженедельный анализ',emoji: '📊', xpReward: 100, category: 'app'),
    Achievement(id: 'level_3', name: 'Уровень Атлет',   desc: 'Достиг 3-го уровня', emoji: '🔥', xpReward: 100, category: 'level'),
    Achievement(id: 'level_5', name: 'Уровень Чемпион', desc: 'Достиг 5-го уровня', emoji: '⚡', xpReward: 200, category: 'level'),
    Achievement(id: 'level_7', name: 'Уровень Elite',   desc: 'Достиг 7-го уровня', emoji: '👑', xpReward: 500, category: 'level'),
    Achievement(id: 'early_bird', name: 'Ранняя птица', desc: 'Тренировка завершена до 8 утра',  emoji: '🌅', xpReward: 100, category: 'special'),
    Achievement(id: 'night_owl',  name: 'Ночная сова',  desc: 'Тренировка после 22:00',          emoji: '🦉', xpReward: 100, category: 'special'),
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
