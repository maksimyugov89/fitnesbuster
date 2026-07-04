import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

enum WorkoutLocation { gym, outdoor, home }

enum RunningPreference { withRunning, noRunning }

class WorkoutLocationScreen extends StatefulWidget {
  const WorkoutLocationScreen({super.key});
  @override
  State<WorkoutLocationScreen> createState() => _WorkoutLocationScreenState();
}

class _WorkoutLocationScreenState extends State<WorkoutLocationScreen>
    with SingleTickerProviderStateMixin {
  WorkoutLocation? _selectedLocation;
  RunningPreference? _selectedRunning;
  late AnimationController _ctrl;

  final List<_LocationOption> _locations = const [
    _LocationOption(
      value: WorkoutLocation.gym,
      title: 'Фитнес\nклуб',
      subtitle: 'Полный доступ к тренажёрам\nстанки, веса, кардио',
      emoji: '🏋️',
      tags: ['Всё включено', 'Тренажёры', 'Веса', 'Кардио'],
      gradientIndex: 0,
      features: ['Максимум оборудования', 'Без погоды', 'Профессионально'],
    ),
    _LocationOption(
      value: WorkoutLocation.outdoor,
      title: 'Уличный\nворкаут',
      subtitle: 'Брусья, бег, свежий воздух\nполная свобода',
      emoji: '🌳',
      tags: ['Брусья', 'Бег', 'Воздух', 'Калистеника'],
      gradientIndex: 1,
      features: ['Свежий воздух', 'Функционально', 'Бесплатно'],
    ),
    _LocationOption(
      value: WorkoutLocation.home,
      title: 'Дом',
      subtitle: 'Тренировки с комфортом\nковрик, гантели, HIIT',
      emoji: '🏠',
      tags: ['Без зала', 'Коврик', 'Гантели', 'HIIT'],
      gradientIndex: 2,
      features: ['Без дороги', 'В любое время', 'Приватность'],
    ),
  ];

  LinearGradient _locationGradient(int index, dynamic colors) {
    switch (index) {
      case 0:
        return LinearGradient(
          colors: [colors.accentPurple, const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1:
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return LinearGradient(
          colors: [colors.accentOrange, const Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [colors.primary, colors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedLocation != null && _selectedRunning != null;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Где будете\nтренироваться?',
                      style: AppTextStyles.displayM,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Выберите место\nдля тренировок',
                      style: AppTextStyles.bodyL,
                    ),
                    const SizedBox(height: 28),
                    ..._locations.asMap().entries.map(
                      (e) => _buildLocationCard(e.value, e.key, colors),
                    ),
                    const SizedBox(height: 28),
                    _buildRunningSection(colors),
                    const SizedBox(height: 16),
                    _buildEquipmentNote(colors),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
              4,
              (i) => Container(
                width: i == 2 ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: i <= 2 ? colors.primary : colors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(_LocationOption opt, int idx, dynamic colors) {
    final isSel = _selectedLocation == opt.value;
    final delay = idx * 0.08;
    final gradient = _locationGradient(idx, colors);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = Curves.easeOut.transform(
          ((_ctrl.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedLocation = opt.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isSel ? gradient : null,
              color: isSel ? null : colors.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSel
                    ? colors.textPrimary.withValues(alpha: 0.2)
                    : colors.textPrimary.withValues(alpha: 0.06),
                width: isSel ? 1.5 : 1,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(opt.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.title,
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isSel
                                  ? colors.textPrimary
                                  : colors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opt.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSel
                                  ? colors.textPrimary.withValues(alpha: 0.75)
                                  : colors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel ? colors.textPrimary : colors.surfaceLight,
                        border: Border.all(
                          color: isSel ? Colors.transparent : colors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isSel
                          ? Icon(
                              Icons.check_rounded,
                              color: colors.background,
                              size: 16,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: opt.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? colors.textPrimary.withValues(alpha: 0.15)
                                : colors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSel
                                  ? colors.textPrimary
                                  : colors.textMuted,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: opt.features
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.only(right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: isSel
                                    ? colors.textPrimary.withValues(alpha: 0.8)
                                    : colors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSel
                                        ? colors.textPrimary.withValues(
                                            alpha: 0.8,
                                          )
                                        : colors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRunningSection(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Предпочтения по бегу', style: AppTextStyles.titleM),
        const SizedBox(height: 6),
        const Text(
          'Будете бегать или только\nсиловые тренировки',
          style: AppTextStyles.bodyM,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RunningCard(
                value: RunningPreference.withRunning,
                selected: _selectedRunning,
                title: 'С бегом',
                subtitle: 'Уличный + дорожка\nвключены',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                    () => _selectedRunning = RunningPreference.withRunning,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RunningCard(
                value: RunningPreference.noRunning,
                selected: _selectedRunning,
                title: 'Без бега',
                subtitle: 'Только силовые\nбез бега',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                    () => _selectedRunning = RunningPreference.noRunning,
                  );
                },
              ),
            ),
          ],
        ),
        if (_selectedRunning == RunningPreference.noRunning) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Only strength will be added: bars, mats, kettlebells and functional exercises',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.info,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEquipmentNote(dynamic colors) {
    if (_selectedLocation == null) return const SizedBox.shrink();

    String note = '';
    IconData icon = Icons.info_outline_rounded;
    Color noteColor = colors.info;

    switch (_selectedLocation!) {
      case WorkoutLocation.gym:
        note =
            'Выберите оборудование в зале. Если нужного тренажёра нет — замените аналогом.';
        noteColor = colors.accentPurple;
        break;
      case WorkoutLocation.outdoor:
        note =
            'Только брусья и открытая площадка. Защита опциональна — просто выходите.';
        noteColor = colors.success;
        break;
      case WorkoutLocation.home:
        note =
            'Выберите оборудование. Если есть веса или HIIT — используйте свой набор.';
        noteColor = colors.accentOrange;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: noteColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: noteColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: noteColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: TextStyle(fontSize: 12, color: noteColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (!_canContinue)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _selectedLocation == null ? 'Выберите место' : 'Укажите бег',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canContinue
                  ? () {
                      context.read<OnboardingBloc>().add(
                        OnboardingSetLocation(
                          location: _selectedLocation!.name,
                          running: _selectedRunning!.name,
                        ),
                      );
                      context.push('/onboarding/profile');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canContinue
                    ? colors.primary
                    : colors.surfaceLight,
                foregroundColor: _canContinue
                    ? colors.textPrimary
                    : colors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Продолжить',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Running Card
class _RunningCard extends StatelessWidget {
  final RunningPreference value;
  final RunningPreference? selected;
  final String title, subtitle;
  final VoidCallback onTap;

  const _RunningCard({
    required this.value,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isSel = selected == value;
    final cardColor = value == RunningPreference.withRunning
        ? colors.success
        : colors.accentOrange;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel ? cardColor.withValues(alpha: 0.12) : colors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSel
                ? cardColor
                : colors.textPrimary.withValues(alpha: 0.06),
            width: isSel ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  value == RunningPreference.withRunning
                      ? AppImages.running
                      : AppImages.strengthTraining,
                  width: 32,
                  height: 32,
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSel ? cardColor : colors.surfaceLight,
                    border: Border.all(
                      color: isSel ? Colors.transparent : colors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSel
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: colors.textPrimary,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSel ? cardColor : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSel
                    ? cardColor.withValues(alpha: 0.8)
                    : colors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data model
class _LocationOption {
  final WorkoutLocation value;
  final String title, subtitle, emoji;
  final List<String> tags, features;
  final int gradientIndex;

  const _LocationOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.tags,
    required this.features,
    required this.gradientIndex,
  });
}
