import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class ActivityRingsCard extends StatelessWidget {
  final Animation<double> animation;
  final int steps;
  final int targetSteps;
  final double caloriesBurned;
  final double targetCalories;
  final double waterMl;
  final double targetWater;
  final bool hasSyncedData;
  final VoidCallback onStepsTap;

  const ActivityRingsCard({
    super.key,
    required this.animation,
    required this.steps,
    required this.targetSteps,
    required this.caloriesBurned,
    required this.targetCalories,
    required this.waterMl,
    required this.targetWater,
    required this.hasSyncedData,
    required this.onStepsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Row(children: [
          Text(AppLocalizations.tl('dashboardActivatedToday'), style: AppTextStyles.titleM),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: p.surfaceLight, borderRadius: BorderRadius.circular(8)),
            child: Text(l10n.today, style: TextStyle(fontSize: 11, color: p.textMuted, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context2, __) => CustomPaint(
                size: const Size(160, 160),
                painter: _ActivityRingsPainter(
                  progress: animation.value,
                  steps: steps / targetSteps,
                  calories: caloriesBurned / targetCalories,
                  water: waterMl / targetWater,
                  stepsColor:    AppTheme.of(context2).accentOrange,
                  caloriesColor: AppTheme.of(context2).primary,
                  waterColor:    AppTheme.of(context2).accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: onStepsTap,
                child: _RingLegend(
                  color: p.accentOrange,
                  label: l10n.stepsLabel,
                  value: hasSyncedData ? '$steps' : '—',
                  total: '/$targetSteps',
                  unit: '',
                  editable: steps == 0,
                ),
              ),
              const SizedBox(height: 14),
              _RingLegend(color: p.primary, label: l10n.caloriesLabel, value: hasSyncedData ? '${caloriesBurned.toInt()}' : '—', total: '/${targetCalories.toInt()}', unit: ' ${l10n.kcalShort}'),
              const SizedBox(height: 14),
              _RingLegend(color: p.accent, label: l10n.waterLabel, value: hasSyncedData ? '${waterMl.toInt()}' : '—', total: '/${targetWater.toInt()}', unit: ' ${AppLocalizations.tl('ml')}'),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  final double progress, steps, calories, water;
  final Color stepsColor, caloriesColor, waterColor;
  const _ActivityRingsPainter({
    required this.progress,
    required this.steps,
    required this.calories,
    required this.water,
    required this.stepsColor,
    required this.caloriesColor,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rings = [
      (radius: size.width * 0.42, color: stepsColor,    value: steps),
      (radius: size.width * 0.31, color: caloriesColor, value: calories),
      (radius: size.width * 0.20, color: waterColor,    value: water),
    ];

    for (final ring in rings) {
      canvas.drawCircle(center, ring.radius, Paint()
        ..color = ring.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ring.radius),
        -1.5707963,
        2 * 3.14159265 * (ring.value * progress).clamp(0, 1),
        false,
        Paint()
          ..color = ring.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ActivityRingsPainter old) => old.progress != progress;
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label, value, total, unit;
  final bool editable;
  const _RingLegend({required this.color, required this.label, required this.value, required this.total, required this.unit, this.editable = false});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: TextStyle(fontSize: 11, color: p.textMuted)),
          if (editable) ...[
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded, size: 10, color: p.textMuted),
          ],
        ]),
        RichText(text: TextSpan(children: [
          TextSpan(text: '$value$unit', style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          TextSpan(text: total, style: TextStyle(fontSize: 11, color: p.textMuted, fontFamily: 'Inter')),
        ])),
      ]),
    ]);
  }
}
