import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/presentation/widgets/segmented_tab_bar.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  Set<String> _unlocked = {};
  int _totalXp = 0;
  String _selectedCategory = 'all';

  static const _categories = [
    ('all', 'Все'),
    ('workout', 'Тренировки'),
    ('streak', 'Серии'),
    ('pr', 'Рекорды'),
    ('nutrition', 'Питание'),
    ('water', 'Вода'),
    ('health', 'Здоровье'),
    ('app', 'Приложение'),
    ('level', 'Уровни'),
    ('special', 'Особые'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final unlocked = await sl<IGamificationService>().getUnlockedIds();
    final xp = await sl<IGamificationService>().getTotalXp();
    if (mounted) {
      setState(() {
        _unlocked = unlocked;
        _totalXp = xp;
      });
    }
  }

  List<Achievement> get _filtered {
    final all = GamificationService.allAchievements;
    if (_selectedCategory == 'all') return all;
    return all.where((a) => a.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final lvl = GamificationService.computeLevel(_totalXp);
    final unlockedCount = _unlocked.length;
    final totalCount = GamificationService.allAchievements.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Достижения', style: AppTextStyles.titleL),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SegmentedTabBar(
            controller: _tabs,
            labels: const ['Достижения', 'Уровни'],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildAchievementsTab(colors, lvl, unlockedCount, totalCount),
          _LevelsTab(colors: colors, totalXp: _totalXp),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(
    ThemePalette colors,
    UserLevel lvl,
    int unlockedCount,
    int totalCount,
  ) {
    return Column(
        children: [
          // ── Header stats ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.15),
                    colors.elevated,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    lvl.icon,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ур. ${lvl.level} · ${lvl.name}',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_totalXp XP · $unlockedCount / $totalCount значков',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: lvl.progress,
                            backgroundColor: colors.primary.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Category filter ───────────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (id, label) = _categories[i];
                final selected = _selectedCategory == id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? colors.primary
                            : colors.textPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? colors.textOnPrimary
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Achievements grid ─────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final a = _filtered[i];
                final earned = _unlocked.contains(a.id);
                return _AchievementTile(
                  achievement: a,
                  earned: earned,
                  colors: colors,
                  onTap: () => _showDetail(a, earned),
                );
              },
            ),
          ),
        ],
      );
  }

  void _showDetail(Achievement a, bool earned) {
    final colors = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: earned ? 1.0 : 0.45,
              child: Image.asset(
                a.icon,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              a.name,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.desc,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${a.xpReward} XP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.accentOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: earned
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.elevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    earned ? '✓ Получено' : '🔒 Не получено',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: earned ? colors.primary : colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool earned;
  final ThemePalette colors;
  final VoidCallback onTap;

  const _AchievementTile({
    required this.achievement,
    required this.earned,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: earned ? 1.0 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            color: earned
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: earned
                  ? colors.primary.withValues(alpha: 0.3)
                  : colors.textPrimary.withValues(alpha: 0.06),
              width: earned ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                achievement.icon,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  achievement.name,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: earned ? colors.textPrimary : colors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+${achievement.xpReward} XP',
                style: TextStyle(
                  fontSize: 9,
                  color: colors.accentOrange.withValues(
                    alpha: earned ? 1.0 : 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelsTab extends StatelessWidget {
  final ThemePalette colors;
  final int totalXp;

  const _LevelsTab({required this.colors, required this.totalXp});

  @override
  Widget build(BuildContext context) {
    final lvl = GamificationService.computeLevel(totalXp);
    final roadmap = GamificationService.levelRoadmap();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        // ── Current level card ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary.withValues(alpha: 0.18), colors.elevated],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Image.asset(
                lvl.icon,
                width: 88,
                height: 88,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Text(
                'Уровень ${lvl.level} · ${lvl.name}',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalXp XP всего',
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: lvl.progress,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lvl.isMaxLevel
                    ? 'Достигнут максимальный уровень'
                    : '${lvl.xpInCurrentLevel} / ${lvl.xpNeededForNext} XP · осталось ${lvl.xpForNext - totalXp} XP до след. уровня',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Все уровни',
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // ── Roadmap ──────────────────────────────────────────────────────────
        ...roadmap.map((entry) {
          final isCurrent = entry.level == lvl.level;
          final isUnlocked = entry.level <= lvl.level;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? colors.primary.withValues(alpha: 0.1)
                    : colors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? colors.primary.withValues(alpha: 0.4)
                      : colors.textPrimary.withValues(alpha: 0.06),
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Opacity(
                    opacity: isUnlocked ? 1.0 : 0.35,
                    child: Image.asset(
                      entry.icon,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ур. ${entry.level} · ${entry.name}',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isUnlocked
                                ? colors.textPrimary
                                : colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'от ${entry.xpRequired} XP',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Сейчас',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textOnPrimary,
                        ),
                      ),
                    )
                  else if (isUnlocked)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.primary,
                      size: 22,
                    )
                  else
                    Icon(
                      Icons.lock_rounded,
                      color: colors.textMuted.withValues(alpha: 0.6),
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
