import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class NutritionWaterCard extends StatelessWidget {
  final int intakeMl;
  final int targetMl;
  final ThemePalette colors;
  final ValueChanged<int> onAdd;

  const NutritionWaterCard({super.key,
    required this.intakeMl,
    required this.targetMl,
    required this.colors,
    required this.onAdd,
  });

  static const _quickAmounts = [100, 200, 500];

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final pct = targetMl > 0 ? (intakeMl / targetMl).clamp(0.0, 1.0) : 0.0;
    final remaining = (targetMl - intakeMl).clamp(0, targetMl);
    final done = intakeMl >= targetMl;
    final intakeLiters = (intakeMl / 1000).toStringAsFixed(1);
    final targetLiters = (targetMl / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? c.info.withValues(alpha: 0.12) : c.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? c.info.withValues(alpha: 0.5) : c.info.withValues(alpha: 0.2),
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(done ? '✅' : '💧', key: ValueKey(done), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.waterLabel, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  done ? context.l10n.done : context.l10n.waterDrunkOf(intakeLiters, targetLiters),
                  key: ValueKey('$intakeMl/$targetMl'),
                  style: TextStyle(fontSize: 12, color: done ? c.info : c.textMuted),
                ),
              ),
            ]),
          ),
          if (intakeMl > 0)
            GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); onAdd(-200); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: c.elevated, borderRadius: BorderRadius.circular(8)),
                child: Text('−200', style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic,
              height: 14,
              child: LinearProgressIndicator(
                value: pct, minHeight: 14, backgroundColor: c.elevated,
                valueColor: AlwaysStoppedAnimation(done ? c.info : c.info.withValues(alpha: 0.8)),
              ),
            ),
          ),
          if (!done)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(context.l10n.waterRemaining(remaining), style: TextStyle(fontSize: 9, color: c.textMuted, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          ..._quickAmounts.map((ml) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); onAdd(ml); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: c.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('+$ml', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: c.info)),
                    Text(context.l10n.mlUnit, style: TextStyle(fontSize: 9, color: c.info.withValues(alpha: 0.7))),
                  ]),
                ),
              ),
            ),
          )),
        ]),
      ]),
    );
  }
}
