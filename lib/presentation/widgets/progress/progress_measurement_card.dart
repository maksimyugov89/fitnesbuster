import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

class ProgressMeasurementCard extends StatelessWidget {
  final String displayLabel;
  final double? value;
  final double? prevValue;
  final String unit;
  final bool isInverseGood;

  const ProgressMeasurementCard({
    super.key,
    required this.displayLabel,
    required this.value,
    required this.prevValue,
    required this.unit,
    this.isInverseGood = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final diff = (value != null && prevValue != null) ? value! - prevValue! : null;
    final diffStr = diff != null ? '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}' : '';
    final isPositiveDiff = diff != null && (isInverseGood ? diff < 0 : diff < 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(displayLabel, style: TextStyle(fontSize: 11, color: colors.textMuted)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value != null ? '$value $unit' : '\u2014 $unit',
              style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
          )),
          if (diffStr.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (isPositiveDiff ? colors.success : colors.error).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(diffStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPositiveDiff ? colors.success : colors.error)),
            ),
          ],
        ]),
      ]),
    );
  }
}
