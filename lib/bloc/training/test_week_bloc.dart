import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/test_day_exercise.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
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
  final IAdaptiveTrainingService _trainingService;
  final IDeepSeekService _aiService;
  final IUserRepository _userRepo;
  final IAuthRepository _authRepo;

  TestWeekBloc({
    required IAdaptiveTrainingService trainingService,
    required IDeepSeekService aiService,
    required IUserRepository userRepo,
    required IAuthRepository authRepo,
  })  : _trainingService = trainingService,
        _aiService = aiService,
        _userRepo = userRepo,
        _authRepo = authRepo,
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
      emit(TestWeekStateDayInProgress(
        dayIndex: dayIdx,
        dayExercises: _testDays[dayIdx],
        completedExercises: const [],
        overallRpe: 5,
        sessionNotes: '',
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
      await _calculateAndShowResults(current.completedExercises, event.profile, emit);
    }
  }

  Future<void> _onComplete(TestWeekComplete event, Emitter<TestWeekState> emit) async {
    emit(const TestWeekStateCalculating());
    await _calculateAndShowResults(event.results, event.profile, emit);
  }

  Future<void> _calculateAndShowResults(
    List<TestExerciseResult> exercises,
    UserProfile? profile,
    Emitter<TestWeekState> emit,
  ) async {
    // Build TestWeekResult from collected data
    final testResult = TestWeekResult(
      completedAt: DateTime.now(),
      exercises: exercises,
      averageHeartRate: 0,
      averageSessionDuration: 0,
      perceivedDifficulty: 5,
    );

    // Calculate adjustment
    final effectiveProfile = profile ?? const UserProfile.defaults();

    final adjustment = _trainingService.calculateAdjustment(
      testResult: testResult,
      profile: effectiveProfile,
    );

    // Check feasibility via AI
    FeasibilityResult feasibility;
    try {
      feasibility = await _trainingService.checkGoalFeasibility(
        profile: effectiveProfile,
        adjustment: adjustment,
      );
    } catch (e, st) {
      appLogger.w('[TestWeekBloc] feasibility check failed', error: e, stackTrace: st);
      feasibility = FeasibilityResult(
        isFeasible: true,
        reason: AppLocalizations.tl('testWeekPlanReady'),
        suggestedActions: [],
      );
    }

    final adaptedPlan = _trainingService.buildAdaptedPlan(
      testResult: testResult,
      adjustment: adjustment,
      durationWeeks: effectiveProfile.targetDate != null
          ? effectiveProfile.estimatedWeeksNeeded
          : 12,
    );

    emit(TestWeekStateCompleted(
      testResult: testResult,
      adjustment: adjustment,
      adaptedPlan: adaptedPlan,
      feasibility: feasibility,
    ));
  }

  Future<void> _onAcceptPlan(TestWeekAcceptPlan event, Emitter<TestWeekState> emit) async {
    // Capture test results before emitting a new state (state will change)
    TestWeekResult? testResult;
    if (state is TestWeekStateCompleted) {
      testResult = (state as TestWeekStateCompleted).testResult;
    }

    emit(const TestWeekStateCalculating());

    try {
      final uid = _authRepo.currentUser?.id;
      if (uid != null) {
        UserProfile? profile;
        try {
          final user = await _userRepo.getUser(uid);
          profile = user.profile;
        } catch (e, st) {
          appLogger.w('[TestWeekBloc] getUser failed', error: e, stackTrace: st);
        }

        if (testResult != null && profile != null) {
          try {
            final refined = await _aiService.refineWorkoutPlan(profile, testResult.exercises);
            await _userRepo.updateWorkoutPlan(userId: uid, workoutPlanJson: refined);
          } catch (e, st) {
            appLogger.w('[TestWeekBloc] AI refinement failed', error: e, stackTrace: st);
          }
        }

        try {
          await _userRepo.saveTestWeekCompleted(userId: uid);
        } catch (e, st) {
          appLogger.w('[TestWeekBloc] saveTestWeekCompleted failed', error: e, stackTrace: st);
        }
      }
    } catch (e, st) {
      appLogger.w('[TestWeekBloc] _onAcceptPlan failed', error: e, stackTrace: st);
    }

    emit(const TestWeekStatePlanAccepted());
  }

  void _onAdjustGoal(TestWeekAdjustGoal event, Emitter<TestWeekState> emit) {
    emit(TestWeekStateNeedsAdjustment(
      reason: event.reason,
      suggestions: event.suggestions,
    ));
  }
}


