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
  UserProfile? _profile;

  TestWeekBloc({
    required TestWeekWorkflowService workflowService,
    required CompleteTestWeekUseCase completeTestWeekUseCase,
  })  : _workflowService = workflowService,
        _completeTestWeekUseCase = completeTestWeekUseCase,
        super(const TestWeekStateInitial()) {
    on<TestWeekStartDay>(_onStartDay);
    on<TestWeekRecordExercise>(_onRecordExercise);
    on<TestWeekFinishDay>(_onFinishDay);
    on<TestWeekComplete>(_onComplete);
    on<TestWeekAcceptPlan>(_onAcceptPlan);
    on<TestWeekAdjustGoal>(_onAdjustGoal);
  }

  List<List<TestDayExercise>> get _testDays => kTestWeekDays;

  void _onStartDay(TestWeekStartDay event, Emitter<TestWeekState> emit) {
    final dayIdx = event.dayIndex;
    if (dayIdx >= 0 && dayIdx < _testDays.length) {
      _profile = event.profile;
      _track(() => sl<IAnalyticsService>().logEvent(name: 'test_week_start', parameters: {'day': dayIdx.toString()}));
      emit(TestWeekStateDayInProgress(
        dayIndex: event.dayIndex,
        dayExercises: _testDays[dayIdx],
        completedExercises: const [],
      ));
    }
  }

  void _onRecordExercise(TestWeekRecordExercise event, Emitter<TestWeekState> emit) {
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

    final updated = [...current.completedExercises, result];
    emit(current.copyWith(completedExercises: updated));
  }

  Future<void> _onFinishDay(TestWeekFinishDay event, Emitter<TestWeekState> emit) async {
    if (state is! TestWeekStateDayInProgress) return;
    final current = state as TestWeekStateDayInProgress;

    // If more days remain, show next day prompt
    if (current.dayIndex < _testDays.length - 1) {
      emit(TestWeekStateDayCompleted(
        dayIndex: current.dayIndex,
        exercisesCompleted: current.completedExercises,
        nextDayIndex: current.dayIndex + 1,
        totalDays: _testDays.length,
      ));
    } else {
      // All days completed — show completion summary
      emit(const TestWeekStateCalculating());
      await _calculateAndShowResults(current.completedExercises, _profile, emit);
    }
  }

  Future<void> _onComplete(TestWeekComplete event, Emitter<TestWeekState> emit) async {
    emit(const TestWeekStateCalculating());
    await _calculateAndShowResults(event.results, _profile, emit);
  }

  Future<void> _calculateAndShowResults(
    List<TestExerciseResult> exercises,
    UserProfile? profile,
    Emitter<TestWeekState> emit,
  ) async {
    final effectiveProfile = profile ?? UserProfile.defaults;
    final result = await _workflowService.calculateResults(
      exercises: exercises,
      profile: effectiveProfile,
    );

    emit(TestWeekStateCompleted(
      testResult: result.testResult,
      adjustment: result.adjustment,
      adaptedPlan: result.adaptedPlan,
      feasibility: result.feasibility,
    ));
  }

  Future<void> _onAcceptPlan(TestWeekAcceptPlan event, Emitter<TestWeekState> emit) async {
    TestWeekResult? testResult;
    if (state is TestWeekStateCompleted) {
      testResult = (state as TestWeekStateCompleted).testResult;
    }

    emit(const TestWeekStateCalculating());

    try {
      if (testResult != null) {
        await _completeTestWeekUseCase.execute(testResult);
        _track(() => sl<IAnalyticsService>().logEvent(name: 'test_week_complete', parameters: {'exercises': testResult!.exercises.length.toString()}));
      }
      emit(const TestWeekStatePlanAccepted());
    } catch (e, st) {
      appLogger.w('[TestWeekBloc] _onAcceptPlan failed', error: e, stackTrace: st);
      emit(TestWeekStateError(AppLocalizations.tl('testWeekPlanNotAccepted')));
    }
  }

  void _onAdjustGoal(TestWeekAdjustGoal event, Emitter<TestWeekState> emit) {
    emit(TestWeekStateNeedsAdjustment(
      reason: event.reason,
      suggestions: event.suggestions,
    ));
  }

  Future<void> _track(Future<void> Function() fn) async {
    try { await fn(); } catch (_) { /* best-effort */ }
  }
}


