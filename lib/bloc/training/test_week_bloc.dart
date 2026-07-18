import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/test_day_exercise.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/core/services/test_week_workflow_service.dart';
import 'package:fitnesbuster/domain/usecases/complete_test_week_use_case.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/test_week_exercises.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/utils/recent_rpe.dart';
import 'package:fitnesbuster/domain/entities/test_week_progress.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_test_week_progress_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';

part 'test_week_event.dart';
part 'test_week_state.dart';

/// Manages the test week flow:
/// 1. Shows test exercises for each day
/// 2. Records user's comfortable weight/sets/reps
/// 3. After completion, calculates adjustment and checks feasibility
/// 4. If unrealistic, offers alternatives
class TestWeekBloc extends Bloc<TestWeekEvent, TestWeekState> {
  final TestWeekWorkflowService _workflowService;
  final CompleteTestWeekUseCase _completeTestWeekUseCase;
  final IAuthRepository _authRepo;
  final IUserRepository _userRepo;
  final ITestWeekProgressRepository _progressRepo;
  final DateTime Function() _now;
  UserProfile? _profile;
  TestWeekProgress? _progress;
  String _userId = 'local';

  TestWeekBloc({
    required TestWeekWorkflowService workflowService,
    required CompleteTestWeekUseCase completeTestWeekUseCase,
    required IAuthRepository authRepo,
    required IUserRepository userRepo,
    required ITestWeekProgressRepository progressRepo,
    DateTime Function()? now,
  }) : _workflowService = workflowService,
       _completeTestWeekUseCase = completeTestWeekUseCase,
       _authRepo = authRepo,
       _userRepo = userRepo,
       _progressRepo = progressRepo,
       _now = now ?? DateTime.now,
       super(const TestWeekStateInitial()) {
    on<TestWeekInitialize>(_onInitialize);
    on<TestWeekStartDay>(_onStartDay);
    on<TestWeekRecordExercise>(_onRecordExercise);
    on<TestWeekFinishDay>(_onFinishDay);
    on<TestWeekComplete>(_onComplete);
    on<TestWeekAcceptPlan>(_onAcceptPlan);
    on<TestWeekAdjustGoal>(_onAdjustGoal);
  }

  // Тестовая неделя должна предлагать только то оборудование, которое
  // реально доступно пользователю (зал/стадион/дом) — иначе тест нечестный.
  List<List<TestDayExercise>> get _testDays =>
      testWeekDaysForLocation(_profile?.workoutLocation);

  Future<void> _onInitialize(
    TestWeekInitialize event,
    Emitter<TestWeekState> emit,
  ) async {
    _userId = _authRepo.currentUser?.id ?? 'local';
    if (_userId != 'local') {
      try {
        _profile = (await _userRepo.getUser(_userId)).profile;
      } catch (e, st) {
        appLogger.w(
          '[TestWeekBloc] profile restore failed',
          error: e,
          stackTrace: st,
        );
      }
    }
    _profile ??= UserProfile.defaults;
    if (_profile!.testWeekCompleted) {
      emit(const TestWeekStatePlanAccepted());
      return;
    }

    final selectedLocation = _profile!.workoutLocation ?? 'home';
    _progress = await _progressRepo.load(_userId);
    if (_progress == null || _progress!.workoutLocation != selectedLocation) {
      _progress = TestWeekProgress(
        startedAt: _dateOnly(_now()),
        workoutLocation: selectedLocation,
      );
      await _progressRepo.save(_userId, _progress!);
    }

    final nextDay = _progress!.nextDayIndex;
    if (nextDay >= _testDays.length) {
      emit(const TestWeekStateCalculating());
      await _calculateAndShowResults(
        _progress!.allCompletedExercises,
        _profile,
        emit,
        perceivedDifficulty: _progress!.averageRpe,
      );
      return;
    }
    if (nextDay == 0) {
      await _startDay(0, emit);
      return;
    }
    _emitDayCompleted(nextDay - 1, emit);
  }

  Future<void> _onStartDay(
    TestWeekStartDay event,
    Emitter<TestWeekState> emit,
  ) async {
    _profile = event.profile ?? _profile ?? UserProfile.defaults;
    _progress ??= TestWeekProgress(
      startedAt: _dateOnly(_now()),
      workoutLocation: _profile!.workoutLocation ?? 'home',
    );
    await _progressRepo.save(_userId, _progress!);

    final dayIdx = event.dayIndex;
    if (dayIdx < 0 || dayIdx >= _testDays.length) return;
    if (dayIdx != _progress!.nextDayIndex) return;
    if (!_progress!.isDayAvailable(dayIdx, _now())) {
      emit(
        TestWeekStateDayScheduled(
          dayIndex: dayIdx,
          totalDays: _testDays.length,
          availableAt: _progress!.availableAtForDay(dayIdx),
        ),
      );
      return;
    }
    await _startDay(dayIdx, emit);
  }

  Future<void> _startDay(int dayIdx, Emitter<TestWeekState> emit) async {
    final draft = _progress!.draftDayIndex == dayIdx
        ? _progress!.draftExercises
        : const <TestExerciseResult>[];
    _track(
      () => sl<IAnalyticsService>().logEvent(
        name: 'test_week_start',
        parameters: {'day': dayIdx.toString()},
      ),
    );
    emit(
      TestWeekStateDayInProgress(
        dayIndex: dayIdx,
        dayExercises: _testDays[dayIdx],
        completedExercises: draft,
      ),
    );
  }

  Future<void> _onRecordExercise(
    TestWeekRecordExercise event,
    Emitter<TestWeekState> emit,
  ) async {
    if (state is! TestWeekStateDayInProgress) return;
    final current = state as TestWeekStateDayInProgress;

    final result = TestExerciseResult(
      exerciseName: event.exerciseName,
      primaryMuscle: event.muscle,
      comfortableWeightKg: event.comfortableWeightKg,
      comfortableSets: event.comfortableSets,
      comfortableReps: event.comfortableReps,
      notes: event.notes,
    );

    final updated = [...current.completedExercises];
    final existing = updated.indexWhere(
      (item) => item.exerciseName == event.exerciseName,
    );
    if (existing >= 0) {
      updated[existing] = result;
    } else {
      updated.add(result);
    }
    _progress = _progress!.copyWith(
      draftDayIndex: current.dayIndex,
      draftExercises: updated,
    );
    await _progressRepo.save(_userId, _progress!);
    emit(current.copyWith(completedExercises: updated));
  }

  Future<void> _onFinishDay(
    TestWeekFinishDay event,
    Emitter<TestWeekState> emit,
  ) async {
    if (state is! TestWeekStateDayInProgress) return;
    final current = state as TestWeekStateDayInProgress;
    if (current.completedExercises.length < current.dayExercises.length) return;

    final completedDays = [
      ..._progress!.completedDays,
      TestWeekCompletedDay(
        dayIndex: current.dayIndex,
        completedAt: _now(),
        rpe: event.perceivedDifficulty.clamp(1, 10),
        exercises: current.completedExercises,
      ),
    ];
    _progress = _progress!.copyWith(
      completedDays: completedDays,
      clearDraftDayIndex: true,
      draftExercises: const [],
    );
    await _progressRepo.save(_userId, _progress!);

    // If more days remain, show next day prompt
    if (current.dayIndex < _testDays.length - 1) {
      _emitDayCompleted(current.dayIndex, emit);
    } else {
      // All days completed — show completion summary
      emit(const TestWeekStateCalculating());
      await _calculateAndShowResults(
        _progress!.allCompletedExercises,
        _profile,
        emit,
        perceivedDifficulty: _progress!.averageRpe,
      );
    }
  }

  void _emitDayCompleted(int dayIndex, Emitter<TestWeekState> emit) {
    final nextDayIndex = dayIndex + 1;
    final completedDay = _progress!.completedDays[dayIndex];
    final availableAt = _progress!.availableAtForDay(nextDayIndex);
    emit(
      TestWeekStateDayCompleted(
        dayIndex: dayIndex,
        exercisesCompleted: completedDay.exercises,
        nextDayIndex: nextDayIndex,
        totalDays: _testDays.length,
        nextAvailableAt: availableAt,
        nextDayAvailable: _progress!.isDayAvailable(nextDayIndex, _now()),
      ),
    );
  }

  Future<void> _onComplete(
    TestWeekComplete event,
    Emitter<TestWeekState> emit,
  ) async {
    emit(const TestWeekStateCalculating());
    await _calculateAndShowResults(event.results, _profile, emit);
  }

  Future<void> _calculateAndShowResults(
    List<TestExerciseResult> exercises,
    UserProfile? profile,
    Emitter<TestWeekState> emit, {
    int? perceivedDifficulty,
  }) async {
    final effectiveProfile = profile ?? UserProfile.defaults;
    final result = await _workflowService.calculateResults(
      exercises: exercises,
      profile: effectiveProfile,
      perceivedDifficulty: perceivedDifficulty ?? await recentAverageRpe() ?? 5,
    );

    emit(
      TestWeekStateCompleted(
        testResult: result.testResult,
        adjustment: result.adjustment,
        adaptedPlan: result.adaptedPlan,
        feasibility: result.feasibility,
      ),
    );
  }

  Future<void> _onAcceptPlan(
    TestWeekAcceptPlan event,
    Emitter<TestWeekState> emit,
  ) async {
    TestWeekResult? testResult;
    if (state is TestWeekStateCompleted) {
      testResult = (state as TestWeekStateCompleted).testResult;
    }

    emit(const TestWeekStateCalculating());

    try {
      if (testResult != null) {
        await _completeTestWeekUseCase.execute(testResult);
        await _progressRepo.clear(_userId);
        _track(
          () => sl<IAnalyticsService>().logEvent(
            name: 'test_week_complete',
            parameters: {'exercises': testResult!.exercises.length.toString()},
          ),
        );
      }
      emit(const TestWeekStatePlanAccepted());
    } catch (e, st) {
      appLogger.w(
        '[TestWeekBloc] _onAcceptPlan failed',
        error: e,
        stackTrace: st,
      );
      emit(TestWeekStateError(AppLocalizations.tl('testWeekPlanNotAccepted')));
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void _onAdjustGoal(TestWeekAdjustGoal event, Emitter<TestWeekState> emit) {
    emit(
      TestWeekStateNeedsAdjustment(
        reason: event.reason,
        suggestions: event.suggestions,
      ),
    );
  }

  Future<void> _track(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {
      /* best-effort */
    }
  }
}
