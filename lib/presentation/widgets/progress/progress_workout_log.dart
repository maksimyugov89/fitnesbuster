import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_cards.dart';

class ProgressWorkoutLog extends StatelessWidget {
  final int currentStreak;
  final bool hasAnyActivity;
  final int todayKcal;
  final int todayWater;
  final int steps;
  final List<bool> weekWorkouts;
  final int weekday;
  final List<String> dayLabels;
  final int completionPct;
  final int doneCount;

  const ProgressWorkoutLog({
    super.key,
    required this.currentStreak,
    required this.hasAnyActivity,
    required this.todayKcal,
    required this.todayWater,
    required this.steps,
    required this.weekWorkouts,
    required this.weekday,
    required this.dayLabels,
    required this.completionPct,
    required this.doneCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Column(
      children: [
        if (currentStreak > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Text('\u{1F525}', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.l10n.dashboardStreak}: $currentStreak ${context.l10n.dashboardDays}',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      context.l10n.noBreakStreak,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (hasAnyActivity) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.today, style: AppTextStyles.titleM),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ActivityStat(
                        icon: AppImages.steps,
                        color: colors.accentOrange,
                        label: context.l10n.stepsLabel,
                        value: steps > 0 ? '$steps' : '\u2014',
                      ),
                    ),
                    Expanded(
                      child: ActivityStat(
                        icon: AppImages.calorieCounter,
                        color: colors.error,
                        label: context.l10n.burnedLabel,
                        value: todayKcal > 0
                            ? '$todayKcal ${context.l10n.kcalShort}'
                            : '\u2014',
                      ),
                    ),
                    Expanded(
                      child: ActivityStat(
                        icon: AppImages.water,
                        color: colors.info,
                        label: context.l10n.waterLabel,
                        value: todayWater > 0
                            ? '$todayWater \u043C\u043B'
                            : '\u2014',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(context.l10n.thisWeekLabel, style: AppTextStyles.titleM),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$completionPct%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.daysCompletedOf(doneCount, weekday),
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final isToday = i == weekday - 1;
                  final done = weekWorkouts.length > i
                      ? weekWorkouts[i]
                      : false;
                  final isFuture = i > weekday - 1;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: done
                              ? colors.primary
                              : isFuture
                              ? colors.elevated.withValues(alpha: 0.4)
                              : colors.elevated,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(color: colors.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          done
                              ? Icons.check_rounded
                              : isFuture
                              ? Icons.remove_rounded
                              : Icons.close_rounded,
                          color: done
                              ? colors.textOnPrimary
                              : isFuture
                              ? colors.textMuted.withValues(alpha: 0.3)
                              : colors.textMuted,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontSize: 9,
                          color: isToday ? colors.primary : colors.textMuted,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
