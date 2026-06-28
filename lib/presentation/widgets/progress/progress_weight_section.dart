import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_cards.dart';

class ProgressWeightSection extends StatelessWidget {
  final double? weight;
  final double? height;
  final double caloriesBurned;
  final int steps;
  final List<double> weightData;
  final List<String> weightLabels;

  const ProgressWeightSection({
    super.key,
    required this.weight,
    required this.height,
    required this.caloriesBurned,
    required this.steps,
    required this.weightData,
    required this.weightLabels,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final l10n = context.l10n;
    final weightText = weight != null ? '${weight!.toStringAsFixed(1)} ${l10n.dashboardKg}' : '\u2014 ${l10n.dashboardKg}';
    final currentWeight = weight ?? (weightData.isNotEmpty ? weightData.last : 0.0);

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [colors.primary, colors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(children: [
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.currentWeightTitle, style: TextStyle(fontSize: 12, color: colors.primaryDark)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(weightText, style: TextStyle(fontFamily: 'Syne', fontSize: 36, fontWeight: FontWeight.w800, color: colors.textOnPrimary)),
            ),
            if (height != null) Text('${l10n.onbHeightTitle}: ${(height! * 100).toInt()} ${l10n.cmUnit}', style: TextStyle(fontSize: 12, color: colors.primaryDark)),
          ])),
          const SizedBox(width: 12),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l10n.burnedLabel, style: TextStyle(fontSize: 11, color: colors.primaryDark)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                caloriesBurned > 0 ? '${caloriesBurned.toInt()} ${l10n.kcalShort}' : '\u2014 ${l10n.kcalShort}',
                style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: colors.textOnPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Text('${l10n.stepsLabel}: ${steps > 0 ? steps : '\u2014'}', style: TextStyle(fontSize: 11, color: colors.primaryDark)),
          ])),
        ]),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.weightChartTitle, style: AppTextStyles.titleM),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: currentWeight > 0
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => CustomPaint(
                      size: const Size(double.infinity, 160),
                      painter: LineChartPainter(data: weightData, progress: v, colors: colors),
                    ),
                  )
                : Center(child: Text(l10n.noWeightData, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.textMuted))),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: weightLabels.map((l) => Text(l, style: TextStyle(fontSize: 9, color: colors.textMuted))).toList()),
        ]),
      ),
    ]);
  }
}
