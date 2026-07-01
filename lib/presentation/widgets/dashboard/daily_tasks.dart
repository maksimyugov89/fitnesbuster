import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class DailyTask {
  final String text;
  final bool done;
  final int xp;
  const DailyTask({required this.text, required this.done, required this.xp});
}

class DashboardDailyTasks extends StatelessWidget {
  final List<DailyTask> tasks;
  const DashboardDailyTasks({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = AppTheme.of(context);
    final done = tasks.where((t) => t.done).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.dailyGoals, style: AppTextStyles.titleM),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: done == tasks.length
                      ? p.primary.withValues(alpha: 0.15)
                      : p.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$done/${tasks.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: done == tasks.length ? p.primary : p.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tasks.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: t.done
                          ? p.primary.withValues(alpha: 0.15)
                          : p.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: t.done
                            ? p.primary
                            : p.textMuted.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: t.done
                        ? Icon(Icons.check_rounded, size: 13, color: p.primary)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: t.done ? p.textMuted : p.textPrimary,
                        decoration: t.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${t.xp} XP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: p.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
