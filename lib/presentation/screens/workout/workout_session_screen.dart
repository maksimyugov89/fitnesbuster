import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String sessionId;
  const WorkoutSessionScreen({super.key, required this.sessionId});
  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  int _currentExercise = 0;
  bool _isResting = false;
  int _restSeconds = 60;
  int _elapsedSeconds = 0;
  Timer? _workoutTimer;
  Timer? _restTimer;
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;

  // Exercises loaded from WorkoutPlan / WorkoutBloc
  final List<_MockExercise> _exercises = [];

  final List<List<bool>> _completedSets = [];

  @override
  void initState() {
    super.initState();
    for (var ex in _exercises) {
      _completedSets.add(List.filled(ex.sets, false));
    }
    // Если нет упражнений, не запускаем таймер
    if (_exercises.isNotEmpty) {
      _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
      _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
      _startWorkoutTimer();
      _slideCtrl.forward();
    } else {
      _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
      _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _workoutTimer?.cancel(); _restTimer?.cancel();
    _pulseCtrl.dispose(); _slideCtrl.dispose();
    super.dispose();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _completeSet(int exIdx, int setIdx) {
    HapticFeedback.mediumImpact();
    setState(() {
      _completedSets[exIdx][setIdx] = true;
      final allSetsForEx = _completedSets[exIdx].every((s) => s);
      if (setIdx < _exercises[exIdx].sets - 1 || !allSetsForEx) {
        _startRest();
      }
    });
  }

  void _startRest() {
    setState(() { _isResting = true; _restSeconds = 60; });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_restSeconds > 0) {
            _restSeconds--;
          } else {
            _isResting = false;
            _restTimer?.cancel();
            HapticFeedback.heavyImpact();
          }
        });
      }
    });
  }

  void _nextExercise() {
    if (_currentExercise < _exercises.length - 1) {
      _slideCtrl.reverse().then((_) {
        setState(() => _currentExercise++);
        _slideCtrl.forward();
      });
    }
  }

  void _prevExercise() {
    if (_currentExercise > 0) {
      _slideCtrl.reverse().then((_) {
        setState(() => _currentExercise--);
        _slideCtrl.forward();
      });
    }
  }

  String get _elapsedFormatted {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    return h > 0
      ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
      : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _completedCount => _completedSets.fold(0, (sum, sets) => sum + sets.where((s) => s).length);
  int get _totalSets => _exercises.fold(0, (sum, ex) => sum + ex.sets);
  double get _overallProgress => _totalSets > 0 ? _completedCount / _totalSets : 0;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    if (_exercises.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
            ),
          ),
        ),
        body: Center(child: Text('Нет активной тренировки. Выберите программу в разделе "Тренировки".', style: TextStyle(color: colors.textMuted, fontSize: 14), textAlign: TextAlign.center)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(children: [
              _buildHeader(context),
              _buildProgress(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    const SizedBox(height: 16),
                    _buildExerciseCard(),
                    const SizedBox(height: 20),
                    _buildSetsList(),
                    const SizedBox(height: 20),
                    _buildExerciseNav(),
                    const SizedBox(height: 20),
                    _buildTip(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ]),
          ),
          if (_isResting) _buildRestOverlay(),
          ],
        ),
      );
    }

  Widget _buildHeader(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20, right: 20, bottom: 16,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => _showExitDialog(context),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.close_rounded, color: colors.textPrimary, size: 22),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Тренировка', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            Text('Нет активной тренировки', style: TextStyle(fontSize: 12, color: colors.textMuted)),
          ]),
        ),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.1 + 0.05 * _pulseCtrl.value),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.5 + 0.5 * _pulseCtrl.value), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(_elapsedFormatted, style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: colors.error)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildProgress() {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$_completedCount / $_totalSets подходов', style: TextStyle(fontSize: 12, color: colors.textMuted)),
          Text('${(_overallProgress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _overallProgress,
            backgroundColor: colors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  Widget _buildExerciseCard() {
    final colors = AppTheme.of(context);
    if (_exercises.isEmpty || _currentExercise >= _exercises.length) {
      return const SizedBox.shrink();
    }
    final ex = _exercises[_currentExercise];
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: _slideCtrl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.surfaceLight, colors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${_currentExercise + 1} / ${_exercises.length}', style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                child: Text(ex.muscle, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 14),
            Text(ex.name, style: TextStyle(fontFamily: 'Syne', fontSize: 26, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 16),
            Row(children: [
              _ExStat(label: 'Подходы', value: '${ex.sets}', icon: Icons.repeat_rounded),
              const SizedBox(width: 24),
              _ExStat(label: 'Повторения', value: ex.reps, icon: Icons.fitness_center_rounded),
              const SizedBox(width: 24),
              _ExStat(label: 'Вес', value: ex.weight, icon: Icons.scale_rounded),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildSetsList() {
    final colors = AppTheme.of(context);
    if (_exercises.isEmpty || _currentExercise >= _exercises.length || _currentExercise >= _completedSets.length) {
      return const SizedBox.shrink();
    }
    final ex = _exercises[_currentExercise];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Подходы', style: AppTextStyles.titleM),
        const SizedBox(height: 12),
        ...List.generate(ex.sets, (i) {
          final done = _completedSets[_currentExercise][i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: done ? colors.success.withValues(alpha: 0.1) : colors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: done ? colors.success.withValues(alpha: 0.3) : colors.textPrimary.withValues(alpha: 0.06),
                  width: done ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: done ? colors.success : colors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: done
                    ? Icon(Icons.check_rounded, color: colors.textOnPrimary, size: 18)
                    : Text('${i + 1}', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: colors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Подход ${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  Text('${ex.reps} повт.  •  ${ex.weight}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                ])),
                if (!done)
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _completeSet(_currentExercise, i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: colors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Готово', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textOnPrimary)),
                        ),
                      ),
                    ),
                  )
                else
                  Icon(Icons.check_circle_rounded, color: colors.success, size: 24),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExerciseNav() {
    final colors = AppTheme.of(context);
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: _prevExercise,
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
            child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.arrow_back_rounded, size: 18, color: colors.textSecondary),
              SizedBox(width: 6),
              Text('Назад', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w600)),
            ])),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: _nextExercise,
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Далее', style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w600)),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 18, color: colors.textPrimary),
            ])),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTip() {
    final colors = AppTheme.of(context);
    if (_exercises.isEmpty || _currentExercise >= _exercises.length) {
      return const SizedBox.shrink();
    }
    final ex = _exercises[_currentExercise];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPurple.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.lightbulb_outline_rounded, color: colors.accentPurple, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Совет тренера', style: TextStyle(fontSize: 11, color: colors.accentPurple, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(ex.videoTip, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildRestOverlay() {
    final colors = AppTheme.of(context);
    return Positioned.fill(
      child: Container(
        color: colors.background.withValues(alpha: 0.85),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('ОТДЫХ', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 4)),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (_, v, __) => Text(
                '$_restSeconds',
                style: TextStyle(fontFamily: 'Syne', fontSize: 96, fontWeight: FontWeight.w800, color: colors.primary),
              ),
            ),
            Text('секунд', style: TextStyle(fontSize: 16, color: colors.textSecondary)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () { _restTimer?.cancel(); setState(() => _isResting = false); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(14)),
                child: Text('Пропустить отдых', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final colors = AppTheme.of(context);
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Завершить тренировку?', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: colors.textPrimary)),
      content: Text('Прогресс будет сохранён', style: TextStyle(color: colors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Продолжить', style: TextStyle(color: colors.primary))),
        TextButton(onPressed: () { Navigator.pop(context); context.pop(); }, child: Text('Завершить', style: TextStyle(color: colors.error))),
      ],
    ));
  }
}

class _MockExercise {
  final String name, reps, weight, muscle, videoTip;
  final int sets;
  const _MockExercise({required this.name, required this.sets, required this.reps, required this.weight, required this.muscle, required this.videoTip});
}

class _ExStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ExStat({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 12, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
    ]);
  }
}