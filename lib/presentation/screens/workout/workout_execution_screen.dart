import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/services/workout_session.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';
import 'package:fitnesbuster/domain/entities/exercise_info.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/presentation/screens/workout/pr_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/import_workout_sheet.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final WorkoutDay workout;
  const WorkoutExecutionScreen({super.key, required this.workout});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen>
    with TickerProviderStateMixin {
  static const int _prepSec = 15;

  // ── Phase state ────────────────────────────────────────────────────────────
  WorkoutPhase _phase = WorkoutPhase.prep;
  int _exIdx = 0;
  int _setIdx = 0;
  int _timeLeft = _prepSec;
  int _totalTime = _prepSec;
  int _completedSets = 0;
  DateTime _phaseStart = DateTime.now();
  Timer? _timer;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Weight input ───────────────────────────────────────────────────────────
  final TextEditingController _weightCtrl = TextEditingController();
  double? _currentWeightKg;

  // ── Challenge result ───────────────────────────────────────────────────────
  Future<List<String>>? _endSessionFuture;

  // ── Post-workout RPE ───────────────────────────────────────────────────────
  int? _selectedRpe;

  // ── TTS ────────────────────────────────────────────────────────────────────
  late final FlutterTts _tts;
  bool _ttsReady = false;

  // ── Exercise model (free-exercise-db matcher) ───────────────────────────────
  ExerciseInfo? _currentExModel;
  final Map<int, ExerciseInfo?> _exModelCache = {};

  // ── Helpers ────────────────────────────────────────────────────────────────
  WorkoutExercise get _ex => widget.workout.exercises[_exIdx];
  int get _totalEx => widget.workout.exercises.length;

  int get _estimatedSetSec {
    if (_ex.isTimedReps) return _ex.durationSeconds;
    final match = RegExp(r'\d+').firstMatch(_ex.reps);
    final reps = int.tryParse(match?.group(0) ?? '') ?? 10;
    return (reps * 3).clamp(20, 90);
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initTts().then((_) => _tryReconnectOrStart());
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts.setLanguage(AppLocalizations.tl('ttsLanguageCode'));
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    _ttsReady = true;
  }

  Future<void> _loadExModel(int exIdx) async {
    if (_exModelCache.containsKey(exIdx)) {
      if (mounted) setState(() => _currentExModel = _exModelCache[exIdx]);
      return;
    }
    final matcher = sl<IExerciseService>();
    await matcher.init();
    final ex = widget.workout.exercises[exIdx];
    final model = matcher.findByRuName(ex.name);
    _exModelCache[exIdx] = model;
    if (mounted) setState(() => _currentExModel = model);
  }

  /// Reconnect to an in-progress session (user navigated away and came back)
  /// or start a fresh session.
  void _tryReconnectOrStart() {
    final session = sl<WorkoutSession>();
    // Match by workout focus name as identity check
    if (session.isActive && session.workout?.focus == widget.workout.focus) {
      // Restore state from the singleton
      _exIdx = session.exIdx;
      _setIdx = session.setIdx;
      _phase = session.phase;
      _phaseStart = session.phaseStart;
      _completedSets = session.completedSets;
      _totalTime = session.phaseDuration;
      _timeLeft = session.computedTimeLeft;

      if (_phase != WorkoutPhase.done) {
        _startCountdown();
        _speak('${AppLocalizations.tl('continueLabel')}! ${_ex.name}');
      }
      if (mounted) setState(() {});
    } else {
      sl<WorkoutSession>().startSession(widget.workout, prepSeconds: _prepSec);
      _enterPhase(WorkoutPhase.prep);
    }
  }

  // ── TTS helpers ────────────────────────────────────────────────────────────

  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e, st) {
      appLogger.d('WorkoutExecution: TTS failed', error: e, stackTrace: st);
    }
  }

  void _speakCountdown(int t) {
    const keys = {
      5: 'ttsCountdown5',
      4: 'ttsCountdown4',
      3: 'ttsCountdown3',
      2: 'ttsCountdown2',
      1: 'ttsCountdown1',
    };
    final k = keys[t];
    if (k != null) _speak(AppLocalizations.tl(k));
  }

  // ── Phase management ───────────────────────────────────────────────────────

  void _enterPhase(WorkoutPhase phase) {
    _timer?.cancel();
    if (!mounted) return;

    _phaseStart = DateTime.now();

    setState(() {
      _phase = phase;
    });

    switch (phase) {
      case WorkoutPhase.prep:
        _timeLeft = _prepSec;
        _totalTime = _prepSec;
        _loadExModel(_exIdx);
        _startCountdown();
        Future.delayed(const Duration(milliseconds: 300), () {
          _speak(
            AppLocalizations.tlp('ttsGetReadyExercise', {
              'name': _ex.name,
              'sets': _ex.sets.toString(),
              'reps': _ex.reps,
            }),
          );
        });

      case WorkoutPhase.exercise:
        _timeLeft = _estimatedSetSec;
        _totalTime = _estimatedSetSec;
        _startCountdown();
        _speak(
          '${AppLocalizations.tl("ttsGo")} ${AppLocalizations.tlp("ttsSetNumber", {"n": "${_setIdx + 1}"})}',
        );

      case WorkoutPhase.rest:
        _timeLeft = _ex.restSeconds;
        _totalTime = _ex.restSeconds;
        _startCountdown();
        final isLastSet = _setIdx >= _ex.sets - 1;
        if (isLastSet) {
          final nextName = _exIdx < _totalEx - 1
              ? widget.workout.exercises[_exIdx + 1].name
              : '';
          _speak(
            AppLocalizations.tlp('ttsRestNextExercise', {'name': nextName}),
          );
        } else {
          _speak(
            AppLocalizations.tlp('ttsRestNextSet', {'n': '${_setIdx + 1}'}),
          );
        }

      case WorkoutPhase.done:
        _endSessionFuture = sl<WorkoutSession>().endSession(completed: true);
        WakelockPlus.disable();
        _speak(AppLocalizations.tl('ttsWorkoutDone'));
        HapticFeedback.vibrate();
    }

    // Sync to singleton on every non-done phase
    if (phase != WorkoutPhase.done) {
      sl<WorkoutSession>().syncState(
        exIdx: _exIdx,
        setIdx: _setIdx,
        phase: phase,
        phaseDuration: _totalTime,
        phaseStart: _phaseStart,
        completedSets: _completedSets,
      );
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        _onTick(_timeLeft);
        if (_timeLeft <= 0) {
          _timer?.cancel();
          _onCountdownEnd();
        }
      });
    });
  }

  void _onTick(int t) {
    if (t <= 5 && t > 0) {
      HapticFeedback.heavyImpact();
      _speakCountdown(t);
    } else if (t > 5 && t % 5 == 0) {
      HapticFeedback.lightImpact();
    }
  }

  void _onCountdownEnd() {
    HapticFeedback.vibrate();
    switch (_phase) {
      case WorkoutPhase.prep:
        _enterPhase(WorkoutPhase.exercise);
      case WorkoutPhase.exercise:
        _completeSet();
      case WorkoutPhase.rest:
        _speak(AppLocalizations.tl('ttsStartNextSet'));
        _enterPhase(WorkoutPhase.exercise);
      case WorkoutPhase.done:
        break;
    }
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();
    // Log the completed set with optional weight
    sl<WorkoutSession>().logSet(
      exerciseName: _ex.name,
      setNumber: _setIdx + 1,
      plannedReps: _ex.reps,
      weightKg: _currentWeightKg,
    );
    _completedSets++;
    if (_setIdx < _ex.sets - 1) {
      setState(() => _setIdx++);
      _enterPhase(WorkoutPhase.rest);
    } else {
      _nextExercise();
    }
  }

  void _nextExercise() {
    if (_exIdx < _totalEx - 1) {
      setState(() {
        _exIdx++;
        _setIdx = 0;
      });
      _enterPhase(WorkoutPhase.prep);
    } else {
      _enterPhase(WorkoutPhase.done);
    }
  }

  void _skip() {
    _timer?.cancel();
    _speak('');
    _onCountdownEnd();
  }

  @override
  void dispose() {
    // Sync final state so session stays accurate while screen is gone
    if (_phase != WorkoutPhase.done) {
      sl<WorkoutSession>().syncState(
        exIdx: _exIdx,
        setIdx: _setIdx,
        phase: _phase,
        phaseDuration: _totalTime,
        phaseStart: _phaseStart,
        completedSets: _completedSets,
      );
    }
    WakelockPlus.disable();
    _timer?.cancel();
    _pulseCtrl.dispose();
    _weightCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    if (_phase == WorkoutPhase.done) return _buildDoneScreen(colors);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(colors),
            _buildOverallProgress(colors),
            Expanded(child: _buildPhaseBody(colors)),
            _buildBottomBar(colors),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(ThemePalette colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Semantics(
            label: context.l10n.exitWorkoutTitle,
            button: true,
            child: GestureDetector(
              onTap: () => _showQuitDialog(colors),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: colors.textMuted,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workout.focus,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  context.l10n.exerciseXofY(
                    (_exIdx + 1).toString(),
                    _totalEx.toString(),
                  ),
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _phaseColor(colors).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _phaseName(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _phaseColor(colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overall progress bar ───────────────────────────────────────────────────

  Widget _buildOverallProgress(ThemePalette colors) {
    final totalSets = widget.workout.totalSets;
    final value = totalSets > 0 ? _completedSets / totalSets : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.elevated,
              valueColor: AlwaysStoppedAnimation(_phaseColor(colors)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.setsOf(
              _completedSets.toString(),
              totalSets.toString(),
            ),
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Phase body ─────────────────────────────────────────────────────────────

  Widget _buildPhaseBody(ThemePalette colors) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: switch (_phase) {
        WorkoutPhase.prep => _buildPrepBody(colors),
        WorkoutPhase.exercise => _buildExerciseBody(colors),
        WorkoutPhase.rest => _buildRestBody(colors),
        WorkoutPhase.done => const SizedBox(),
      },
    );
  }

  Widget _buildPrepBody(ThemePalette colors) {
    final color = colors.accentOrange;
    return SingleChildScrollView(
      key: const ValueKey('prep'),
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PhaseLabel(AppLocalizations.tl('phasePrep'), color),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _ex.name,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.setsTimesReps(_ex.sets.toString(), _ex.reps),
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.restBetweenSets(_ex.restSeconds.toString()),
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 40),
          ScaleTransition(
            scale: _timeLeft <= 5
                ? _pulseAnim
                : const AlwaysStoppedAnimation(1.0),
            child: _CircleTimer(
              timeLeft: _timeLeft,
              total: _totalTime,
              color: color,
              size: 130,
            ),
          ),
          const SizedBox(height: 12),
          if (_currentExModel?.gifUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _currentExModel!.gifUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => Container(
                    height: 160,
                    color: color.withValues(alpha: 0.08),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            context.l10n.secondsToStart,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
          if (_timeLeft <= 5) ...[
            const SizedBox(height: 12),
            Text(
              context.l10n.getReadyAlert,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseBody(ThemePalette colors) {
    final isLastSet = _setIdx == _ex.sets - 1;
    final color = colors.primary;
    final isRep = !_ex.isTimedReps;
    final estSec = _estimatedSetSec;

    return SingleChildScrollView(
      key: const ValueKey('exercise'),
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PhaseLabel(AppLocalizations.tl('phaseExercise'), color),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _ex.name,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${context.l10n.setsLabel} ${_setIdx + 1} / ${_ex.sets}${isLastSet ? '  🏁' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Weight input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 16,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  '${context.l10n.weightLabel}:',
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  height: 36,
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '—',
                      hintStyle: TextStyle(color: colors.textMuted),
                      filled: true,
                      fillColor: colors.surfaceCard,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.surfaceLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.surfaceLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.primary),
                      ),
                    ),
                    onChanged: (v) {
                      _currentWeightKg = double.tryParse(
                        v.replaceAll(',', '.'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.kgUnit,
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _timeLeft <= 5
                ? _pulseAnim
                : const AlwaysStoppedAnimation(1.0),
            child: _CircleTimer(
              timeLeft: _timeLeft,
              total: _totalTime,
              color: color,
              size: 150,
              centerLabel: isRep ? _ex.reps : null,
              centerSub: isRep
                  ? context.l10n.repsShort
                  : AppLocalizations.tl('seconds'),
            ),
          ),
          const SizedBox(height: 8),
          if (isRep)
            Text(
              context.l10n.estimatedTimeSec(estSec.toString()),
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          if (_timeLeft <= 5 && _timeLeft > 0) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.finishNow,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.error,
              ),
            ),
          ],
          if (_currentExModel?.gifUrl != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _currentExModel!.gifUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => Container(
                    height: 180,
                    color: color.withValues(alpha: 0.08),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestBody(ThemePalette colors) {
    final isLastSet = _setIdx >= _ex.sets;
    final color = colors.accentPurple;
    final nextExName = isLastSet && _exIdx < _totalEx - 1
        ? widget.workout.exercises[_exIdx + 1].name
        : null;

    return SingleChildScrollView(
      key: const ValueKey('rest'),
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PhaseLabel(AppLocalizations.tl('phaseRest'), color),
          const SizedBox(height: 16),
          if (isLastSet && nextExName != null) ...[
            Text(
              context.l10n.nextLabel,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                nextExName,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            Text(
              '${context.l10n.setsLabel} $_setIdx / ${_ex.sets}',
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _ex.name,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 40),
          ScaleTransition(
            scale: _timeLeft <= 5
                ? _pulseAnim
                : const AlwaysStoppedAnimation(1.0),
            child: _CircleTimer(
              timeLeft: _timeLeft,
              total: _totalTime,
              color: color,
              size: 190,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.secondsRest,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
          if (_timeLeft <= 5 && _timeLeft > 0) ...[
            const SizedBox(height: 12),
            Text(
              context.l10n.getReadyNextSet,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(ThemePalette colors) {
    final showDoneBtn = _phase == WorkoutPhase.exercise && !_ex.isTimedReps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: showDoneBtn
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: context.l10n.readyLabel,
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _timer?.cancel();
                        _completeSet();
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        context.l10n.readyLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: context.l10n.skip,
                  button: true,
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: Text(
                      context.l10n.skip,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(
                  label: context.l10n.skipRestBtn,
                  button: true,
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      context.l10n.skipRestBtn,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Post-workout RPE ─────────────────────────────────────────────────────

  void _selectRpe(int rpe) {
    HapticFeedback.selectionClick();
    setState(() => _selectedRpe = rpe);
    sl<ISettingsRepository>().setWorkoutRpe(dateKey(DateTime.now()), rpe);
  }

  // ── Post-workout summary for AI correction ─────────────────────────────────

  String _buildPostWorkoutSummary() {
    final buf = StringBuffer();
    buf.writeln(
      AppLocalizations.tlp('postWorkoutTitle', {'focus': widget.workout.focus}),
    );
    buf.writeln(
      AppLocalizations.tlp('postWorkoutDate', {
        'date': DateTime.now().toLocal().toString().substring(0, 10),
      }),
    );
    buf.writeln(
      AppLocalizations.tlp('postWorkoutSetsDone', {
        'done': '$_completedSets',
        'total': '${widget.workout.totalSets}',
      }),
    );
    buf.writeln();
    buf.writeln(AppLocalizations.tl('postWorkoutExercisesLabel'));
    for (final ex in widget.workout.exercises) {
      buf.writeln('- ${ex.name}: ${ex.sets}×${ex.reps}');
    }
    if (widget.workout.cardioMinutes > 0) {
      buf.writeln(
        AppLocalizations.tlp('postWorkoutCardio', {
          'min': '${widget.workout.cardioMinutes}',
        }),
      );
    }
    if (_selectedRpe != null) {
      buf.writeln('RPE: $_selectedRpe/10');
    }
    return buf.toString();
  }

  void _openPostWorkoutCorrection() {
    showPlanCorrectionSheet(
      context,
      initialContent: _buildPostWorkoutSummary(),
      correctionType: 'post_workout',
    );
  }

  // ── Done screen ────────────────────────────────────────────────────────────

  Widget _buildDoneScreen(ThemePalette colors) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const AppIcon(asset: AppImages.achievements, size: 70),
                ),
                const SizedBox(height: 32),
                Text(
                  context.l10n.workoutDoneTitle,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.workout.focus,
                  style: TextStyle(fontSize: 16, color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.exercisesAndSets(
                    _totalEx.toString(),
                    widget.workout.totalSets.toString(),
                  ),
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
                ),
                if (widget.workout.cardioMinutes > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '+ ${context.l10n.cardioMinutes(widget.workout.cardioMinutes)}',
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                ],
                const SizedBox(height: 32),
                if (widget.workout.exercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PrLogCard(
                      exerciseNames: widget.workout.exercises
                          .map((e) => e.name)
                          .toList(),
                      colors: colors,
                    ),
                  ),
                const SizedBox(height: 16),
                if (_endSessionFuture != null)
                  FutureBuilder<List<String>>(
                    future: _endSessionFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.updatingChallenges,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final completed = snap.data ?? [];
                      if (completed.isEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.l10n.challengeCompleted,
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...completed.map(
                              (name) => Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                _RpeRatingRow(selected: _selectedRpe, onSelected: _selectRpe),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Semantics(
                    label: context.l10n.correctPlanBtn,
                    button: true,
                    child: GestureDetector(
                      onTap: _openPostWorkoutCorrection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.accentPurple.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              asset: AppImages.aiAssistant,
                              glowColor: colors.accentPurple,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.correctPlanBtn,
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.accentPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: context.l10n.done,
                  button: true,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      context.l10n.done,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Quit dialog ────────────────────────────────────────────────────────────

  void _showQuitDialog(ThemePalette colors) {
    _timer?.cancel();
    _tts.stop();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.exitWorkoutTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'Syne',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.exitWorkoutMsg,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            if (_completedSets > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.l10n.completedSetsOf(
                    _completedSets.toString(),
                    widget.workout.totalSets.toString(),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Semantics(
            label: context.l10n.keepGoingBtn,
            button: true,
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Resume with fresh countdown for current phase
                _startCountdown();
              },
              child: Text(
                context.l10n.keepGoingBtn,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Semantics(
            label: context.l10n.exitBtn,
            button: true,
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Save partial workout (calories + sets done so far)
                sl<WorkoutSession>().endSession(completed: false);
                WakelockPlus.disable();
                Navigator.pop(context);
              },
              child: Text(
                context.l10n.exitBtn,
                style: TextStyle(color: colors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase helpers ──────────────────────────────────────────────────────────

  Color _phaseColor(ThemePalette c) => switch (_phase) {
    WorkoutPhase.prep => c.accentOrange,
    WorkoutPhase.exercise => c.primary,
    WorkoutPhase.rest => c.accentPurple,
    WorkoutPhase.done => c.success,
  };

  String _phaseName() => switch (_phase) {
    WorkoutPhase.prep => AppLocalizations.tl('phasePrep'),
    WorkoutPhase.exercise => AppLocalizations.tl('phaseExercise'),
    WorkoutPhase.rest => AppLocalizations.tl('phaseRest'),
    WorkoutPhase.done => AppLocalizations.tl('phaseDone'),
  };
}

// ─── Post-workout RPE rating ─────────────────────────────────────────────────

class _RpeRatingRow extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelected;
  const _RpeRatingRow({required this.selected, required this.onSelected});

  static const _values = [4, 6, 8, 9, 10];

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final l10n = context.l10n;
    final labels = [
      l10n.rpeEasy,
      l10n.rpeModerate,
      l10n.rpeHard,
      l10n.rpeVeryHard,
      l10n.rpeMax,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            l10n.rpeQuestionTitle,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_values.length, (i) {
              final isSel = selected == _values[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(_values[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 52,
                    margin: EdgeInsets.only(right: i < _values.length - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isSel
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel
                            ? colors.primary
                            : colors.textPrimary.withValues(alpha: 0.06),
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSel ? colors.primary : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Phase label ─────────────────────────────────────────────────────────────

class _PhaseLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _PhaseLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(AppImages.workoutTimer, width: 20, height: 20),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 2.5,
        ),
      ),
    ],
  );
}

// ─── Circular countdown ───────────────────────────────────────────────────────

class _CircleTimer extends StatelessWidget {
  final int timeLeft, total;
  final Color color;
  final double size;
  final String? centerLabel, centerSub;

  const _CircleTimer({
    required this.timeLeft,
    required this.total,
    required this.color,
    required this.size,
    this.centerLabel,
    this.centerSub,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final progress = total > 0 ? (timeLeft / total).clamp(0.0, 1.0) : 0.0;
    final isDanger = timeLeft <= 5 && timeLeft > 0;
    final activeColor = isDanger ? colors.error : color;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 14,
              color: colors.elevated,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 14,
              color: activeColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          if (isDanger)
            Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.error.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          SizedBox(
            width: size * 0.72,
            height: size * 0.72,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (centerLabel != null) ...[
                      Text(
                        centerLabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: size * 0.22,
                          fontWeight: FontWeight.w800,
                          color: isDanger ? colors.error : colors.textPrimary,
                        ),
                      ),
                      Text(
                        centerSub ?? '',
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$timeLeft ${AppLocalizations.tl('seconds')}',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: size * 0.12,
                          color: isDanger ? colors.error : colors.textMuted,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '$timeLeft',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: size * 0.36,
                          fontWeight: FontWeight.w800,
                          color: isDanger ? colors.error : colors.textPrimary,
                        ),
                      ),
                      Text(
                        centerSub ?? AppLocalizations.tl('seconds'),
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    ],
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
