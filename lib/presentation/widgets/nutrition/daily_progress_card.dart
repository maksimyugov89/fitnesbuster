import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class DailyProgressCard extends StatelessWidget {
  final int totalEaten;
  final int targetCal;
  final int manualCalories;
  final bool hasAddedFoods;

  const DailyProgressCard({
    super.key,
    required this.totalEaten,
    required this.targetCal,
    required this.manualCalories,
    required this.hasAddedFoods,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final progress = targetCal > 0 ? (totalEaten / targetCal).clamp(0.0, 1.0) : 0.0;
    final remaining = (targetCal - totalEaten).clamp(0, targetCal);
    final isOverLimit = totalEaten > targetCal && targetCal > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            isOverLimit ? context.l10n.mealExceeded(totalEaten) : context.l10n.mealEaten(totalEaten),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: isOverLimit ? colors.error : colors.textPrimary),
          ),
          const Spacer(),
          Text(
            targetCal > 0 ? context.l10n.calTarget(targetCal) : context.l10n.loading,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colors.elevated,
            valueColor: AlwaysStoppedAnimation(isOverLimit ? colors.error : colors.primary),
          ),
        ),
        if (targetCal > 0) ...[
          const SizedBox(height: 6),
          Row(children: [
            _CompactMacro(label: context.l10n.remainingLabel, value: '$remaining ${AppLocalizations.tl('kcalShort')}', color: colors.textMuted),
            const Spacer(),
            if (hasAddedFoods)
              _CompactMacro(label: context.l10n.extraFoodLabel, value: '+$manualCalories ${AppLocalizations.tl('kcalShort')}', color: colors.accentOrange),
          ]),
        ],
      ]),
    );
  }
}

class _CompactMacro extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactMacro({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: [
      TextSpan(text: '$label: ', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
      TextSpan(text: value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    ]));
  }
}
