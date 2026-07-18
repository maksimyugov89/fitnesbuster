import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

class DashboardXpBar extends StatelessWidget {
  final dynamic level;
  const DashboardXpBar({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final lvl = level;
    final color = p.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Image.asset(lvl.icon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${context.l10n.levelLabel} '
                      '${lvl.level} · '
                      '${GamificationService.localizedLevelName(lvl.level)}',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      lvl.isMaxLevel
                          ? '${lvl.totalXp} XP'
                          : '${lvl.xpInCurrentLevel} / ${lvl.xpNeededForNext} XP',
                      style: TextStyle(fontSize: 10, color: p.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: lvl.progress,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: context.l10n.achievementsTitle,
            button: true,
            child: GestureDetector(
              onTap: () => context.push('/achievements'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  AppImages.achievements,
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
