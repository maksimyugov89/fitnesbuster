import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';

class IntensitySelectionScreen extends StatefulWidget {
  const IntensitySelectionScreen({super.key});
  @override
  State<IntensitySelectionScreen> createState() => _IntensitySelectionScreenState();
}

class _IntensitySelectionScreenState extends State<IntensitySelectionScreen>
    with SingleTickerProviderStateMixin {
  IntensityLevel? _selected;
  late AnimationController _ctrl;

  final List<_IntOption> _options = const [
    _IntOption(
      level: IntensityLevel.hardcore,
      label: 'ХАРДКОР',
      weeks: '8-12 недель',
      daysPerWeek: '6 дн/нед',
      description: 'Максимальная интенсивность. Только для преданных делу.',
      emoji: '💀',
      colorVariant: 0,
      tags: ['Тяжёлые веса', 'Фулбади', 'HIIT'],
    ),
    _IntOption(
      level: IntensityLevel.intensive,
      label: 'ИНТЕНСИВ',
      weeks: '12-16 недель',
      daysPerWeek: '5 дн/нед',
      description: 'Серьёзный режим с прогрессивной нагрузкой.',
      emoji: '🚀',
      colorVariant: 1,
      tags: ['Тяжёлые веса', 'Круговая', 'Умеренное кардио'],
    ),
    _IntOption(
      level: IntensityLevel.balanced,
      label: 'СБАЛАНС',
      weeks: '16-20 недель',
      daysPerWeek: '4 дн/нед',
      description: 'Оптимальный баланс весов и кардио.',
      emoji: '⚖️',
      colorVariant: 2,
      tags: ['Гибкость', 'Сплит', 'Постоянство'],
      recommended: true,
    ),
    _IntOption(
      level: IntensityLevel.gradual,
      label: 'ПЛАВНЫЙ',
      weeks: '20-26 недель',
      daysPerWeek: '3 дн/нед',
      description: 'Плавный старт без лишней нагрузки.',
      emoji: '🌱',
      colorVariant: 3,
      tags: ['Для новичков', 'Без перетрена', 'Стабильно'],
    ),
    _IntOption(
      level: IntensityLevel.relaxed,
      label: 'ЛЁГКИЙ',
      weeks: '26-52 недель',
      daysPerWeek: '2-3 дн/нед',
      description: 'Лёгкий режим. Тренировка как бонус.',
      emoji: '🧘',
      colorVariant: 4,
      tags: ['По выходным', 'Легко', 'Чилл'],
    ),
  ];

  Color _colorForVariant(int variant, dynamic colors) {
    switch (variant) {
      case 0: return colors.error;
      case 1: return colors.accentOrange;
      case 2: return colors.primary;
      case 3: return const Color(0xFF10B981);
      case 4: return colors.info;
      default: return colors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Выберите режим\nинтенсивности', style: AppTextStyles.displayM),
                    const SizedBox(height: 8),
                    const Text(
                      'Насколько усердно\nвы готовы тренироваться',
                      style: AppTextStyles.bodyL,
                    ),
                    const SizedBox(height: 28),
                    ..._options.asMap().entries.map((e) => _card(e.value, e.key, colors)),
                  ],
                ),
              ),
            ),
            _bottomButton(colors),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(4, (i) => Container(
              width: i == 1 ? 20 : 8, height: 8,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: i <= 1 ? colors.primary : colors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _card(_IntOption opt, int idx, dynamic colors) {
    final isSel = _selected == opt.level;
    final delay = idx * 0.08;
    final optColor = _colorForVariant(opt.colorVariant, colors);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = Curves.easeOut.transform(
          ((_ctrl.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Transform.translate(offset: Offset(0, 30 * (1 - t)), child: Opacity(opacity: t, child: child));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); setState(() => _selected = opt.level); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSel ? optColor.withValues(alpha: 0.12) : colors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel ? optColor : colors.textPrimary.withValues(alpha: 0.06),
                width: isSel ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(opt.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800,
                                    color: isSel ? optColor : colors.textPrimary,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              if (opt.recommended) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('РЕКОМ.', style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  )),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${opt.weeks}  •  ${opt.daysPerWeek}',
                            style: TextStyle(fontSize: 12, color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel ? optColor : colors.surfaceLight,
                        border: Border.all(color: isSel ? Colors.transparent : colors.textMuted, width: 2),
                      ),
                      child: isSel ? Icon(Icons.check_rounded, color: colors.textPrimary, size: 14) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(opt.description, style: TextStyle(
                  fontSize: 13, color: colors.textSecondary, height: 1.4,
                )),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: opt.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? optColor.withValues(alpha: 0.15) : colors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: isSel ? optColor : colors.textMuted,
                    )),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomButton(dynamic colors) {
    final ok = _selected != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: ok ? () {
            context.read<OnboardingBloc>().add(OnboardingSetIntensity(_selected!));
            context.push('/onboarding/location');
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ok ? colors.primary : colors.surfaceLight,
            foregroundColor: ok ? colors.textPrimary : colors.textMuted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Продолжить', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntOption {
  final IntensityLevel level;
  final String label, weeks, daysPerWeek, description, emoji;
  final int colorVariant;
  final List<String> tags;
  final bool recommended;
  const _IntOption({
    required this.level, required this.label, required this.weeks,
    required this.daysPerWeek, required this.description, required this.emoji,
    required this.colorVariant, required this.tags, this.recommended = false,
  });
}
