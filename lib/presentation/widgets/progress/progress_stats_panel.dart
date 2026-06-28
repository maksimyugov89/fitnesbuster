import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/progress/weight_chart.dart';

class ProgressStatsPanel extends StatelessWidget {
  final String periodTitle;
  final int doneCount;
  final int totalDays;
  final double totalKcal;
  final int totalWaterMl;
  final int totalEatenCal;

  const ProgressStatsPanel({
    super.key,
    required this.periodTitle,
    required this.doneCount,
    required this.totalDays,
    required this.totalKcal,
    required this.totalWaterMl,
    required this.totalEatenCal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final pct = totalDays > 0 ? (doneCount / totalDays * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(periodTitle, style: AppTextStyles.titleM),
          const Spacer(),
          if (doneCount > 0 || totalDays > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
            ),
        ]),
        const SizedBox(height: 4),
        Text(context.l10n.workoutsDoneCountLabel(doneCount), style: TextStyle(fontSize: 11, color: colors.textMuted)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: ProgressPeriodStatCell(icon: '\u{1F4AA}', label: context.l10n.taskWorkout, value: '$doneCount/$totalDays', color: colors.primary)),
          Expanded(child: ProgressPeriodStatCell(icon: '\u{1F525}', label: context.l10n.kcalShort, value: totalKcal > 0 ? '${totalKcal.toInt()}' : '0', color: colors.accent)),
          Expanded(child: ProgressPeriodStatCell(icon: '\u{1F4A7}', label: context.l10n.waterLabel, value: totalWaterMl > 0 ? '${(totalWaterMl / 1000).toStringAsFixed(1)}${AppLocalizations.tl('literUnit')}' : '0${AppLocalizations.tl('literUnit')}', color: colors.info)),
          Expanded(child: ProgressPeriodStatCell(icon: '\u{1F37D}\u{FE0F}', label: context.l10n.eatenLabel, value: totalEatenCal > 0 ? '$totalEatenCal ${AppLocalizations.tl('kcalShort')}' : '0', color: colors.accentOrange)),
        ]),
      ]),
    );
  }
}
