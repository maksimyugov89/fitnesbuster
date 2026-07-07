import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/bloc/training/test_week_bloc.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';

/// Full screen flow for the test week.
/// Shows day by day exercise recording, then plan + feasibility.
class TestWeekScreen extends StatefulWidget {
  const TestWeekScreen({super.key});

  @override
  State<TestWeekScreen> createState() => _TestWeekScreenState();
}

class _TestWeekScreenState extends State<TestWeekScreen> {
  @override
  void initState() {
    super.initState();
    // Start with day 0
    context.read<TestWeekBloc>().add(const TestWeekStartDay(dayIndex: 0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Тестовая неделя', style: AppTextStyles.titleL),
      ),
      body: BlocBuilder<TestWeekBloc, TestWeekState>(
        builder: (context, state) {
          return switch (state) {
            TestWeekStateDayInProgress s => _TestDayView(dayState: s),
            TestWeekStateDayCompleted s => _DayCompletedView(state: s),
            TestWeekStateCalculating _ => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Анализируем твои показатели...',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            TestWeekStateCompleted s => _PlanResultsView(state: s),
            TestWeekStatePlanAccepted _ => _PlanAcceptedView(),
            TestWeekStateNeedsAdjustment s => _AdjustmentNeededView(state: s),
            _ => Center(
              child: Text(
                'Готовим тестовую неделю...',
                style: TextStyle(color: colors.textMuted),
              ),
            ),
          };
        },
      ),
    );
  }
}

// ─── Test Day View: user records exercise data ─────────────────────────────
class _TestDayView extends StatefulWidget {
  final TestWeekStateDayInProgress dayState;
  const _TestDayView({required this.dayState});

  @override
  State<_TestDayView> createState() => _TestDayViewState();
}

class _TestDayViewState extends State<_TestDayView> {
  late Map<int, double> _weights;
  late Map<int, int> _sets;
  late Map<int, int> _reps;
  late Map<int, TextEditingController> _notesCtrls;
  int _rpe = 5;

  @override
  void initState() {
    super.initState();
    _weights = {};
    _sets = {};
    _reps = {};
    _notesCtrls = {};
    for (int i = 0; i < widget.dayState.dayExercises.length; i++) {
      final ex = widget.dayState.dayExercises[i];
      _weights[i] = ex.baseWeight;
      _sets[i] = 4;
      _reps[i] = 10;
      _notesCtrls[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _notesCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _allRecorded => _sets.values.every((s) => s >= 4);

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final dayLabels = [
      'День 1: Грудь + Трицепс',
      'День 2: Спина + Бицепс',
      'День 3: Плечи + Ноги',
      'День 4: Пресс + Кардио',
    ];
    final dayLabel = widget.dayState.dayIndex < dayLabels.length
        ? dayLabels[widget.dayState.dayIndex]
        : 'День ${widget.dayState.dayIndex + 1}';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Day header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.surfaceLight, colors.surface],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ДЕНЬ ${widget.dayState.dayIndex + 1}/4',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dayLabel,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Выполни упражнения и запиши комфортный вес, с которым сделаешь минимум 4 подхода',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Exercise cards
        ...List.generate(widget.dayState.dayExercises.length, (i) {
          final ex = widget.dayState.dayExercises[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ExerciseCard(
              name: ex.name,
              weightController: _notesCtrls[i]!,
              weight: _weights[i] ?? ex.baseWeight,
              sets: _sets[i] ?? 4,
              reps: _reps[i] ?? 10,
              onWeightChanged: (v) => setState(() => _weights[i] = v),
              onSetsChanged: (v) => setState(() => _sets[i] = v),
              onRepsChanged: (v) => setState(() => _reps[i] = v),
              onRecord: () {
                context.read<TestWeekBloc>().add(
                  TestWeekRecordExercise(
                    exerciseName: ex.name,
                    muscle: ex.muscle,
                    comfortableWeightKg: _weights[i] ?? ex.baseWeight,
                    comfortableSets: _sets[i] ?? 4,
                    comfortableReps: _reps[i] ?? 10,
                    notes: _notesCtrls[i]?.text,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${ex.name} — записано!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: colors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        }),

        // RPE rating
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Общая сложность тренировки (RPE 1-10)',
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(10, (i) {
                  final val = i + 1;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rpe = val),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: val <= _rpe
                              ? colors.primary.withValues(alpha: 0.3)
                              : colors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$val',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: val <= _rpe
                                ? colors.primary
                                : colors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _allRecorded
                ? () => context.read<TestWeekBloc>().add(
                    const TestWeekFinishDay(),
                  )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _allRecorded
                  ? colors.primary
                  : colors.surfaceLight,
              foregroundColor: _allRecorded
                  ? colors.textOnPrimary
                  : colors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _allRecorded
                  ? 'Завершить день тренировки'
                  : 'Запиши все упражнения',
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Exercise recording card ───────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final String name;
  final TextEditingController weightController;
  final double weight;
  final int sets;
  final int reps;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onSetsChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onRecord;

  const _ExerciseCard({
    required this.name,
    required this.weightController,
    required this.weight,
    required this.sets,
    required this.reps,
    required this.onWeightChanged,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: _Counter(
                  label: 'Подходы',
                  value: sets,
                  min: 3,
                  max: 8,
                  onChanged: onSetsChanged,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: _Counter(
                  label: 'Повторения',
                  value: reps,
                  min: 6,
                  max: 20,
                  onChanged: onRepsChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вес (кг)',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${weight.toInt()} кг',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              onWeightChanged((weight - 2.5).clamp(0, 200)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 12,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              onWeightChanged((weight + 2.5).clamp(0, 200)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 12,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onRecord,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Записать показатель',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
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

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: colors.textMuted),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            GestureDetector(
              onTap: () => onChanged((value - 1).clamp(min, max)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 12,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$value',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onChanged((value + 1).clamp(min, max)),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 12,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Day completed view ──────────────────────────────────────────────────────
class _DayCompletedView extends StatelessWidget {
  final TestWeekStateDayCompleted state;
  const _DayCompletedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final total = state.totalDays;
    final done = state.dayIndex + 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: colors.success, size: 64),
            const SizedBox(height: 20),
            Text(
              'День $done/$total завершён!',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Записано ${state.exercisesCompleted.length} упражнений',
              style: TextStyle(fontSize: 16, color: colors.textSecondary),
            ),
            const SizedBox(height: 32),
            // Progress indicator
            SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: done / total,
                  backgroundColor: colors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (state.nextDayIndex < total)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.read<TestWeekBloc>().add(
                    TestWeekStartDay(dayIndex: state.nextDayIndex),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Начать день ${state.nextDayIndex + 1}',
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan results view ────────────────────────────────────────────────────────
class _PlanResultsView extends StatelessWidget {
  final TestWeekStateCompleted state;
  const _PlanResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final f = state.feasibility;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Feasibility check
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: f.isFeasible
                ? colors.success.withValues(alpha: 0.08)
                : colors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: f.isFeasible
                  ? colors.success.withValues(alpha: 0.3)
                  : colors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                f.isFeasible
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: f.isFeasible ? colors.success : colors.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.isFeasible
                          ? 'Цель достижима'
                          : 'Требуется корректировка',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: f.isFeasible ? colors.success : colors.warning,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f.reason,
                      style: TextStyle(
                        fontSize: 13,
                        color: f.isFeasible
                            ? colors.textSecondary
                            : colors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    if (!f.isFeasible && f.suggestedActions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...f.suggestedActions.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  a,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Adapted plan preview
        const Text('Твоя программа', style: AppTextStyles.titleL),
        const SizedBox(height: 4),
        Text(
          'Уровень: ${state.adjustment.adaptedIntensityLabel} · ${state.adjustment.userLevel == UserLevel.beginner ? 'Начинающий' : 'Средний'}',
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        const SizedBox(height: 12),
        ...state.adaptedPlan
            .take(4)
            .map(
              (week) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: week.weekNumber == 1
                      ? colors.primary.withValues(alpha: 0.06)
                      : colors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: week.weekNumber == 1
                        ? colors.primary.withValues(alpha: 0.2)
                        : colors.textPrimary.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      week.focus,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: week.weekNumber == 1
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${week.plannedSessions} тренировок · ~${week.estimatedCalorieBurn.toInt()} ккал',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
        if (state.adaptedPlan.length > 4)
          Text(
            '...и ещё ${state.adaptedPlan.length - 4} недель',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),

        const SizedBox(height: 24),

        if (f.isFeasible)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () =>
                  context.read<TestWeekBloc>().add(const TestWeekAcceptPlan()),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Начать программу!',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textOnPrimary,
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.read<TestWeekBloc>().add(
                      TestWeekAdjustGoal(
                        reason: f.reason,
                        suggestions: f.suggestedActions,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.warning,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Скорректировать',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 60),
      ],
    );
  }
}

// ─── Plan accepted ────────────────────────────────────────────────────────────
class _PlanAcceptedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration_rounded, color: colors.primary, size: 80),
            const SizedBox(height: 20),
            Text(
              'Программа запущена!',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Твой персональный план адаптирован под твои показатели. Первая неделя — адаптация. Следи за прогрессом!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'На главную',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Adjustment needed view ──────────────────────────────────────────────────
class _AdjustmentNeededView extends StatelessWidget {
  final TestWeekStateNeedsAdjustment state;
  const _AdjustmentNeededView({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune_rounded, color: colors.warning, size: 64),
            const SizedBox(height: 20),
            Text(
              'Скорректируем цель',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ...state.suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Выбрано: $s',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: colors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.textPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
