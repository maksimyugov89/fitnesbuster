import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

/// Полноэкранный фон с медленно плавающими радиальными бликами.
/// Оборачивает всё приложение через builder в MaterialApp — менять
/// отдельные экраны не нужно.
class AnimatedThemeBackground extends StatefulWidget {
  final ThemePalette palette;
  final Widget child;

  const AnimatedThemeBackground({
    super.key,
    required this.palette,
    required this.child,
  });

  @override
  State<AnimatedThemeBackground> createState() =>
      _AnimatedThemeBackgroundState();
}

class _AnimatedThemeBackgroundState extends State<AnimatedThemeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Очень медленный цикл — 16 секунд
    _ctrl = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Фоновый слой изолируем RepaintBoundary — прокрутка контента
        // не вызывает перерисовку фона
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => SizedBox.expand(
              child: CustomPaint(
                painter: _BlobPainter(t: _ctrl.value, palette: widget.palette),
              ),
            ),
          ),
        ),
        // Контент приложения поверх
        widget.child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _BlobPainter extends CustomPainter {
  final double t;
  final ThemePalette palette;

  const _BlobPainter({required this.t, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Заливаем базовым цветом темы
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = palette.background,
    );

    const twoPi = math.pi * 2;

    // 2. Блик A — primary, правый верх
    _blob(
      canvas,
      Offset(
        w * (0.80 + 0.15 * math.sin(t * twoPi * 0.62)),
        h * (0.18 + 0.13 * math.cos(t * twoPi * 0.47)),
      ),
      radius: w * 0.75,
      color: palette.primary,
      alpha: 0.18,
    );

    // 3. Блик B — accent, левый низ
    _blob(
      canvas,
      Offset(
        w * (0.18 + 0.14 * math.cos(t * twoPi * 0.53)),
        h * (0.80 + 0.10 * math.sin(t * twoPi * 0.68)),
      ),
      radius: w * 0.68,
      color: palette.accent,
      alpha: 0.13,
    );

    // 4. Блик C — primary, центр-низ
    _blob(
      canvas,
      Offset(
        w * (0.50 + 0.11 * math.sin(t * twoPi * 0.38 + 2.0)),
        h * (0.90 + 0.06 * math.cos(t * twoPi * 0.42)),
      ),
      radius: w * 0.52,
      color: palette.primary,
      alpha: 0.08,
    );
  }

  void _blob(
    Canvas canvas,
    Offset center, {
    required double radius,
    required Color color,
    required double alpha,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.t != t ||
      old.palette.background != palette.background ||
      old.palette.primary != palette.primary ||
      old.palette.accent != palette.accent;
}
