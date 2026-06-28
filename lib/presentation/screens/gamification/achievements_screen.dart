import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  Set<String> _unlocked = {};
  int _totalXp = 0;
  String _selectedCategory = 'all';

  static const _categories = [
    ('all',       'Все'),
    ('workout',   'Тренировки'),
    ('streak',    'Серии'),
    ('pr',        'Рекорды'),
    ('nutrition', 'Питание'),
    ('water',     'Вода'),
    ('health',    'Здоровье'),
    ('app',       'Приложение'),
    ('level',     'Уровни'),
    ('special',   'Особые'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlocked = await sl<IGamificationService>().getUnlockedIds();
    final xp = await sl<IGamificationService>().getTotalXp();
    if (mounted) setState(() { _unlocked = unlocked; _totalXp = xp; });
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
            child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
          ),
        ),
      ),
      body: Column(children: [
        // ── Header stats ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary.withValues(alpha: 0.15), colors.elevated],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Text(lvl.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Ур. ${lvl.level} · ${lvl.name}',
                  style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalXp XP · $unlockedCount / $totalCount значков',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: lvl.progress,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    minHeight: 5,
                  ),
                ),
              ])),
            ]),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? colors.primary : colors.textPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? colors.textOnPrimary : colors.textSecondary,
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
      ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(a.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            a.name,
            style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            a.desc,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${a.xpReward} XP',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.accentOrange),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
          ]),
          const SizedBox(height: 8),
        ]),
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
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 28)),
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
              style: TextStyle(fontSize: 9, color: colors.accentOrange.withValues(alpha: earned ? 1.0 : 0.5)),
            ),
          ]),
        ),
      ),
    );
  }
}
