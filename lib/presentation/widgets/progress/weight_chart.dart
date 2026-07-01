import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

class ProgressPeriodStatCell extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const ProgressPeriodStatCell({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: c.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class ProgressPeriodBarChart extends StatelessWidget {
  final List<({String label, int done, int total, double kcal})> bars;
  final ThemePalette colors;
  const ProgressPeriodBarChart({
    super.key,
    required this.bars,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final maxKcal = bars.fold<double>(1, (m, b) => b.kcal > m ? b.kcal : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: bars.map((b) {
        final fillRatio = maxKcal > 0 ? (b.kcal / maxKcal) : 0.0;
        final pct = b.total > 0 ? (b.done / b.total * 100).round() : 0;
        final barColor = b.done > 0 ? colors.primary : colors.elevated;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (b.done > 0)
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 7,
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  height: fillRatio > 0 ? (fillRatio * 84).clamp(4, 84) : 4,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                    gradient: b.done > 0
                        ? LinearGradient(
                            colors: [colors.primary, colors.primaryLight],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  b.label,
                  style: TextStyle(fontSize: 8, color: colors.textMuted),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ProgressLineChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final ThemePalette colors;
  ProgressLineChartPainter({
    required this.data,
    required this.progress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final stepX = size.width / (data.length - 1);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(1, double.infinity);

    final points = data.asMap().entries.map((e) {
      return Offset(
        stepX * e.key,
        size.height - ((e.value - minVal) / range) * size.height,
      );
    }).toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1], p1 = points[i];
      path.cubicTo(
        p0.dx + stepX / 2,
        p0.dy,
        p1.dx - stepX / 2,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(points.last, 3.5, Paint()..color = colors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
