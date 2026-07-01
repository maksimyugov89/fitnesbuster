import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});
  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen>
    with SingleTickerProviderStateMixin {
  FitnessGoal? _selectedGoal;
  late AnimationController _controller;
  final List<_GoalOption> _goals = const [
    _GoalOption(
      goal: FitnessGoal.loseWeight,
      title: 'Похудеть',
      emoji: '🔥',
      description: 'Сжечь жир, сухое тело',
      gradientIndex: 0,
    ),
    _GoalOption(
      goal: FitnessGoal.gainWeight,
      title: 'Набрать\nмассу',
      emoji: '💪',
      description: 'Сила и мышечная масса',
      gradientIndex: 1,
    ),
    _GoalOption(
      goal: FitnessGoal.maintain,
      title: 'Держать\nформу',
      emoji: '⚖️',
      description: 'Быть в форме и здоровым',
      gradientIndex: 2,
    ),
    _GoalOption(
      goal: FitnessGoal.beachBody,
      title: 'Пляжный\nсезон',
      emoji: '🏖️',
      description: 'Подготовка к лету',
      gradientIndex: 3,
    ),
    _GoalOption(
      goal: FitnessGoal.sportPerformance,
      title: 'Спортивная\nформа',
      emoji: '🏆',
      description: 'Максимальная производительность',
      gradientIndex: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _goalGradient(int index, dynamic colors) {
    switch (index) {
      case 0:
        return LinearGradient(
          colors: [colors.accentOrange, colors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1:
        return LinearGradient(
          colors: [colors.accentPurple, const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return LinearGradient(
          colors: [const Color(0xFF0EA5E9), colors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 4:
        return LinearGradient(
          colors: [colors.primary, colors.accent],
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выберите\nсвою цель',
                      style: AppTextStyles.displayM,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Выберите основное направление —\nпод него строится программа',
                      style: AppTextStyles.bodyL,
                    ),
                    const SizedBox(height: 32),
                    ..._goals.asMap().entries.map(
                      (e) => _buildGoalCard(e.value, e.key, colors),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomButton(colors),
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
          _buildStepIndicator(colors),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(dynamic colors) {
    return Row(
      children: List.generate(
        4,
        (i) => Container(
          width: i == 0 ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: i == 0 ? colors.primary : colors.surfaceLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(_GoalOption option, int index, dynamic colors) {
    final isSelected = _selectedGoal == option.goal;
    final delay = index * 0.1;
    final gradient = _goalGradient(index, colors);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(
          ((_controller.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedGoal = option.goal);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isSelected ? gradient : null,
              color: isSelected ? null : colors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? colors.textPrimary.withValues(alpha: 0.2)
                    : colors.textPrimary.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Text(option.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? colors.textPrimary
                              : colors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: isSelected
                              ? colors.textPrimary.withValues(alpha: 0.8)
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? colors.textPrimary
                        : colors.surfaceLight,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : colors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: colors.background,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(dynamic colors) {
    final enabled = _selectedGoal != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: enabled
                    ? () {
                        context.read<OnboardingBloc>().add(
                          OnboardingSetGoal(_selectedGoal!),
                        );
                        context.push('/onboarding/intensity');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled
                      ? colors.primary
                      : colors.surfaceLight,
                  foregroundColor: enabled
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
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  final FitnessGoal goal;
  final String title;
  final String emoji;
  final String description;
  final int gradientIndex;

  const _GoalOption({
    required this.goal,
    required this.title,
    required this.emoji,
    required this.description,
    required this.gradientIndex,
  });
}
