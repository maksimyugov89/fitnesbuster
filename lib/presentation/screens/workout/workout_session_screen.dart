import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class WorkoutSessionScreen extends StatefulWidget {
  /// Day number (1=Пн … 7=Вс) or 'today' for current weekday.
  final String sessionId;
  const WorkoutSessionScreen({super.key, required this.sessionId});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  // ── Data state ─────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _loadError;
  WorkoutDay? _day;

  // ── Session state ──────────────────────────────────────────────────────────
  int _currentExercise = 0;
  bool _isResting = false;
  int _restSeconds = 60;
  int _elapsedSeconds = 0;
  Timer? _workoutTimer;
  Timer? _restTimer;
  List<List<bool>> _completedSets = [];

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _loadWorkout();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _loadWorkout() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception(AppLocalizations.tl('notAuthorized'));

      final plans = await sl<UserRepository>().getAiPlans(uid);
      final planJson = plans['workoutPlan'];
      if (planJson == null || planJson.isEmpty) {
        throw Exception(AppLocalizations.tl('noSavedWorkoutPlan'));
      }

      final decoded = jsonDecode(planJson) as Map<String, dynamic>;
      final planList = (decoded['plan'] as List<dynamic>?) ?? [];
      if (planList.isEmpty) throw Exception(AppLocalizations.tl('planIsEmpty'));

      WorkoutDay? found;
      final targetDay = _resolveDay(widget.sessionId, planList.length);
      for (final item in planList) {
        final d = WorkoutDay.fromJson(item as Map<String, dynamic>);
        if (d.day == targetDay) { found = d; break; }
      }
      // Fallback: first day with exercises
      found ??= planList
          .map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
          .firstWhere((d) => d.exercises.isNotEmpty,
              orElse: () => WorkoutDay.fromJson(planList.first as Map<String, dynamic>));

      final sets = found.exercises.map((e) => List.filled(e.sets, false)).toList();
      if (mounted) {
        setState(() {
          _day = found;
          _completedSets = sets;
          _loading = false;
        });
        _slideCtrl.forward();
        _startWorkoutTimer();
      }
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  int _resolveDay(String sessionId, int planLength) {
    if (sessionId == 'today') return DateTime.now().weekday;
    final n = int.tryParse(sessionId);
    if (n != null) return n;
    // Weekday names
    const names = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    final idx = names.indexOf(sessionId.toLowerCase());
    if (idx >= 0) return idx + 1;
    return DateTime.now().weekday;
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  // ── Set completion ─────────────────────────────────────────────────────────

  void _completeSet(int exIdx, int setIdx) {
    HapticFeedback.mediumImpact();
    setState(() {
      _completedSets[exIdx][setIdx] = true;
      final allDone = _completedSets[exIdx].every((s) => s);
      if (!allDone || setIdx < (_day!.exercises[exIdx].sets - 1)) {
        _startRest(_day!.exercises[exIdx].restSeconds);
      }
    });
  }

  void _startRest(int seconds) {
    setState(() { _isResting = true; _restSeconds = seconds; });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_restSeconds > 0) {
          _restSeconds--;
        } else {
          _isResting = false;
          _restTimer?.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _nextExercise() {
    final exercises = _day?.exercises ?? [];
    if (_currentExercise < exercises.length - 1) {
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _elapsedFormatted {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _completedCount => _completedSets.fold(0, (s, sets) => s + sets.where((v) => v).length);
  int get _totalSets => _day?.totalSets ?? 0;
  double get _overallProgress => _totalSets > 0 ? _completedCount / _totalSets : 0;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    if (_loading) return _buildLoading(colors);
    if (_loadError != null) return _buildError(colors);

    final exercises = _day!.exercises;
    if (exercises.isEmpty) return _buildEmpty(colors);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            _buildHeader(context, colors),
            _buildProgressBar(colors),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  const SizedBox(height: 16),
                  _buildExerciseCard(colors, exercises),
                  const SizedBox(height: 20),
                  _buildSetsList(colors, exercises),
                  const SizedBox(height: 20),
                  _buildExerciseNav(colors, exercises),
                  const SizedBox(height: 20),
                  if (exercises[_currentExercise].techniqueCue.isNotEmpty)
                    _buildTip(colors, exercises[_currentExercise].techniqueCue),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ]),
        ),
        if (_isResting) _buildRestOverlay(colors),
      ]),
    );
  }

  // ── Sub-views ──────────────────────────────────────────────────────────────

  Widget _buildLoading(ThemePalette colors) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: colors.primary),
      const SizedBox(height: 16),
      Text('Загружаем тренировку...', style: TextStyle(color: colors.textMuted, fontSize: 14)),
    ])),
  );

  Widget _buildError(ThemePalette colors) => Scaffold(
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
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline_rounded, size: 56, color: colors.error.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(_loadError!, style: TextStyle(color: colors.textMuted, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () { setState(() { _loading = true; _loadError = null; }); _loadWorkout(); },
            style: FilledButton.styleFrom(backgroundColor: colors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Повторить'),
          ),
        ]),
      ),
    ),
  );

  Widget _buildEmpty(ThemePalette colors) => Scaffold(
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
    body: Center(
      child: Text(
        'На этот день запланирован отдых\nили нет упражнений.',
        style: TextStyle(color: colors.textMuted, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _buildHeader(BuildContext context, ThemePalette colors) => Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20, right: 20, bottom: 16,
    ),
    child: Row(children: [
      GestureDetector(
        onTap: () => _showExitDialog(context, colors),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.close_rounded, color: colors.textPrimary, size: 22),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_day!.focus,
            style: TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary),
            overflow: TextOverflow.ellipsis),
        Text('${_day!.exercises.length} упражнений',
            style: TextStyle(fontSize: 12, color: colors.textMuted)),
      ])),
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.1 + 0.05 * _pulseCtrl.value),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.error.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.5 + 0.5 * _pulseCtrl.value), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(_elapsedFormatted, style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: colors.error)),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildProgressBar(ThemePalette colors) => Padding(
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

  Widget _buildExerciseCard(ThemePalette colors, List<WorkoutExercise> exercises) {
    final ex = exercises[_currentExercise];
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _slideCtrl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.surfaceLight, colors.surface],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('${_currentExercise + 1} / ${exercises.length}',
                    style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w700)),
              ),
              if (ex.musclePrimary.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(ex.musclePrimary, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
            const SizedBox(height: 14),
            Text(ex.name, style: TextStyle(fontFamily: 'Syne', fontSize: 24, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 16),
            Row(children: [
              _ExStat(colors: colors, label: 'Подходы', value: '${ex.sets}', icon: Icons.repeat_rounded),
              const SizedBox(width: 24),
              _ExStat(colors: colors, label: 'Повторения', value: ex.reps, icon: Icons.fitness_center_rounded),
              if (ex.weightGuideline.isNotEmpty) ...[
                const SizedBox(width: 24),
                _ExStat(colors: colors, label: 'Вес', value: ex.weightGuideline, icon: Icons.scale_rounded),
              ],
            ]),
            if (ex.rpe > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colors.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('RPE ${ex.rpe}/10', style: TextStyle(fontSize: 11, color: colors.accentOrange, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildSetsList(ThemePalette colors, List<WorkoutExercise> exercises) {
    if (_currentExercise >= _completedSets.length) return const SizedBox.shrink();
    final ex = exercises[_currentExercise];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Подходы', style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
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
                      : Text('${i + 1}', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: colors.textSecondary))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Подход ${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  Text('${ex.reps} повт.${ex.weightGuideline.isNotEmpty ? "  •  ${ex.weightGuideline}" : ""}',
                      style: TextStyle(fontSize: 12, color: colors.textMuted)),
                ])),
                if (!done)
                  GestureDetector(
                    onTap: () => _completeSet(_currentExercise, i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(gradient: colors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                      child: Text('Готово', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textOnPrimary)),
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

  Widget _buildExerciseNav(ThemePalette colors, List<WorkoutExercise> exercises) => Row(children: [
    Expanded(
      child: GestureDetector(
        onTap: _currentExercise > 0 ? _prevExercise : null,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _currentExercise > 0 ? colors.surfaceCard : colors.surfaceCard.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
          ),
          child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.arrow_back_rounded, size: 18, color: _currentExercise > 0 ? colors.textSecondary : colors.textMuted),
            const SizedBox(width: 6),
            Text('Назад', style: TextStyle(fontSize: 13, color: _currentExercise > 0 ? colors.textSecondary : colors.textMuted, fontWeight: FontWeight.w600)),
          ])),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: GestureDetector(
        onTap: _currentExercise < exercises.length - 1 ? _nextExercise : null,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _currentExercise < exercises.length - 1 ? colors.surfaceLight : colors.surfaceLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Далее', style: TextStyle(fontSize: 13, color: _currentExercise < exercises.length - 1 ? colors.textPrimary : colors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 18, color: _currentExercise < exercises.length - 1 ? colors.textPrimary : colors.textMuted),
          ])),
        ),
      ),
    ),
  ]);

  Widget _buildTip(ThemePalette colors, String tip) => Container(
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
        Text('Совет', style: TextStyle(fontSize: 11, color: colors.accentPurple, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(tip, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4)),
      ])),
    ]),
  );

  Widget _buildRestOverlay(ThemePalette colors) => Positioned.fill(
    child: Container(
      color: colors.background.withValues(alpha: 0.88),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('ОТДЫХ', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 4)),
          const SizedBox(height: 16),
          Text('$_restSeconds', style: TextStyle(fontFamily: 'Syne', fontSize: 96, fontWeight: FontWeight.w800, color: colors.primary)),
          Text('секунд', style: TextStyle(fontSize: 16, color: colors.textSecondary)),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () { _restTimer?.cancel(); setState(() => _isResting = false); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(14)),
              child: Text('Пропустить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ),
          ),
        ]),
      ),
    ),
  );

  void _showExitDialog(BuildContext context, ThemePalette colors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Завершить тренировку?', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, color: colors.textPrimary)),
        content: Text('Прогресс текущей сессии не будет сохранён.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Продолжить', style: TextStyle(color: colors.primary))),
          TextButton(onPressed: () { Navigator.pop(context); context.pop(); }, child: Text('Выйти', style: TextStyle(color: colors.error))),
        ],
      ),
    );
  }
}

// ─── Shared stat chip ─────────────────────────────────────────────────────────

class _ExStat extends StatelessWidget {
  final ThemePalette colors;
  final String label, value;
  final IconData icon;
  const _ExStat({required this.colors, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(icon, size: 12, color: colors.textMuted),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
    ]),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
  ]);
}
