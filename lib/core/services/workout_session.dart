import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

enum WorkoutPhase { prep, exercise, rest, done }

/// Holds active workout state so the timer continues ticking (via wall-clock)
/// even when WorkoutExecutionScreen is off-screen. The screen syncs here on
/// every phase change and on dispose. Managed as a lazy singleton through DI.
class WorkoutSession extends ChangeNotifier {
  WorkoutSession();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _active = false;
  WorkoutDay? _workout;
  int _exIdx = 0;
  int _setIdx = 0;
  WorkoutPhase _phase = WorkoutPhase.prep;
  int _phaseDuration = 15;
  DateTime _phaseStart = DateTime.now();
  int _completedSets = 0;
  DateTime _sessionStart = DateTime.now();

  // Per-set log: [{exercise, set, reps, weight}]
  final List<Map<String, dynamic>> _setLog = [];

  // ── Read-only getters ──────────────────────────────────────────────────────

  bool get isActive => _active;
  WorkoutDay? get workout => _workout;
  int get exIdx => _exIdx;
  int get setIdx => _setIdx;
  WorkoutPhase get phase => _phase;
  int get phaseDuration => _phaseDuration;
  DateTime get phaseStart => _phaseStart;
  int get completedSets => _completedSets;

  /// Time remaining computed from wall-clock — works even when screen is gone.
  int get computedTimeLeft {
    final elapsed = DateTime.now().difference(_phaseStart).inSeconds;
    return (_phaseDuration - elapsed).clamp(0, _phaseDuration);
  }

  /// Safe exercise name for the mini-player.
  String get exerciseName {
    final w = _workout;
    if (w == null || _exIdx >= w.exercises.length) return '';
    return w.exercises[_exIdx].name;
  }

  /// Short progress label for the mini-player.
  String get progressText {
    final w = _workout;
    if (w == null) return '';
    return '$_completedSets / ${w.totalSets} ${AppLocalizations.tl('socialSetsOf')}';
  }

  int get elapsedMinutes =>
      DateTime.now().difference(_sessionStart).inMinutes;

  /// ~5 kcal/min for strength; +2 extra if the plan has cardio minutes.
  int get estimatedCaloriesBurned {
    final rate = (_workout?.cardioMinutes ?? 0) > 0 ? 7 : 5;
    return (elapsedMinutes * rate).clamp(0, 9999);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void startSession(WorkoutDay workout, {required int prepSeconds}) {
    _active = true;
    _workout = workout;
    _exIdx = 0;
    _setIdx = 0;
    _phase = WorkoutPhase.prep;
    _phaseDuration = prepSeconds;
    _phaseStart = DateTime.now();
    _completedSets = 0;
    _sessionStart = DateTime.now();
    _setLog.clear();
    notifyListeners();
  }

  /// Records one completed set. Called by WorkoutExecutionScreen on each set finish.
  void logSet({
    required String exerciseName,
    required int setNumber,
    required String plannedReps,
    double? weightKg,
  }) {
    _setLog.add({
      'exercise': exerciseName,
      'set': setNumber,
      'reps': plannedReps,
      if (weightKg != null) 'weight': weightKg,
    });
  }

  /// Called by the execution screen on every phase transition so wall-clock
  /// state is always accurate even after the screen is disposed.
  void syncState({
    required int exIdx,
    required int setIdx,
    required WorkoutPhase phase,
    required int phaseDuration,
    required DateTime phaseStart,
    required int completedSets,
  }) {
    _exIdx = exIdx;
    _setIdx = setIdx;
    _phase = phase;
    _phaseDuration = phaseDuration;
    _phaseStart = phaseStart;
    _completedSets = completedSets;
    SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  /// Saves burned calories + workout-done flag to SharedPreferences, then
  /// marks the session inactive. Returns names of completed challenges (if any).
  Future<List<String>> endSession({bool completed = true}) async {
    if (!_active) return [];
    final kcal = estimatedCaloriesBurned;
    final cardioMin = _workout?.cardioMinutes ?? 0;
    final durationMin = elapsedMinutes;
    final sets = _completedSets;
    _active = false;
    _workout = null;
    notifyListeners();

    final logSnapshot = List<Map<String, dynamic>>.from(_setLog);
    _setLog.clear();

    List<String> completedChallenges = [];

    try {
      final settings = sl<ISettingsRepository>();
      final now = DateTime.now();
      final k = dateKey(now);
      await settings.setWorkoutDone(k, completed);
      await settings.setWorkoutSets(k, sets);
      final prev = await settings.getWorkoutKcal(k);
      await settings.setWorkoutKcal(k, prev + kcal);
      if (logSnapshot.isNotEmpty) {
        await settings.setWorkoutLogDetail(k, jsonEncode(logSnapshot));
      }
      await settings.setWorkoutTime(k, now.hour * 60 + now.minute);

      if (completed) {
        int streak = 0;
        for (int i = 0; i < 120; i++) {
          final d = now.subtract(Duration(days: i));
          if (await settings.getWorkoutDone(dateKey(d))) {
            streak++;
          } else if (i > 0) {
            break;
          }
        }
        await sl<IGamificationService>().onWorkoutCompleted(
          streak: streak,
          workoutHour: now.hour,
        );
        try {
          completedChallenges = await sl<ISocialService>().recordWorkout(
            durationMinutes: durationMin,
            caloriesBurned: kcal,
            cardioMinutes: cardioMin,
            streak: streak,
          );
        } catch (e, st) {
          appLogger.w('WorkoutSession: challenge update failed', error: e, stackTrace: st);
        }
      }
    } catch (e, st) {
      appLogger.w('WorkoutSession: save data', error: e, stackTrace: st);
    }

    return completedChallenges;
  }
}
