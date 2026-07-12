import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/services/onboarding_workflow_service.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/utils/age_calculator.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// Collects all onboarding data step-by-step and triggers plan generation via DeepSeek.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final IUserRepository _userRepo;
  final OnboardingWorkflowService _workflowService;
  final IAuthRepository _authRepo;

  OnboardingBloc({
    required IUserRepository userRepo,
    required OnboardingWorkflowService workflowService,
    required IAuthRepository authRepo,
  }) : _userRepo = userRepo,
       _workflowService = workflowService,
       _authRepo = authRepo,
       super(const OnboardingCollecting()) {
    on<OnboardingSetGoal>(_onSetGoal);
    on<OnboardingSetIntensity>(_onSetIntensity);
    on<OnboardingSetLocation>(_onSetLocation);
    on<OnboardingSetProfile>(_onSetProfile);
    on<OnboardingFinalize>(_onFinalize);
  }

  OnboardingCollecting _collecting() => state is OnboardingCollecting
      ? state as OnboardingCollecting
      : const OnboardingCollecting();

  void _onSetGoal(OnboardingSetGoal e, Emitter<OnboardingState> emit) {
    emit(_collecting().copyWith(goal: e.goal));
  }

  void _onSetIntensity(
    OnboardingSetIntensity e,
    Emitter<OnboardingState> emit,
  ) {
    emit(_collecting().copyWith(intensity: e.intensity));
  }

  void _onSetLocation(OnboardingSetLocation e, Emitter<OnboardingState> emit) {
    emit(_collecting().copyWith(location: e.location, running: e.running));
  }

  void _onSetProfile(OnboardingSetProfile e, Emitter<OnboardingState> emit) {
    final s = _collecting();
    emit(
      s.copyWith(
        name: e.name,
        dateOfBirth: e.dateOfBirth,
        weight: e.weight,
        height: e.height,
        gender: e.gender,
        activity: e.activity,
        trainingExperience: e.trainingExperience,
        restrictions: e.restrictions,
        city: e.city,
      ),
    );
  }

  Future<void> _onFinalize(
    OnboardingFinalize event,
    Emitter<OnboardingState> emit,
  ) async {
    final data = _collecting();
    if (!data.isComplete) {
      appLogger.w(
        '[OnboardingBloc] _onFinalize called but data is NOT complete',
      );
      emit(OnboardingError(AppLocalizations.tl('onboardingIncomplete')));
      return;
    }

    final userId = _authRepo.currentUser?.id ?? 'local';
    final profile = data.toUserProfile();

    appLogger.i(
      '[OnboardingBloc] _onFinalize START — userId=$userId '
      'goal=${data.goal} intensity=${data.intensity} location=${data.location} '
      'weight=${profile.weight} height=${profile.height} age=${profile.age}',
    );

    // Step 1: Save onboarding + profile to Firestore
    emit(const OnboardingSaving());
    try {
      await _userRepo.saveOnboardingData(
        userId: userId,
        goal: data.goal!,
        intensity: data.intensity!,
        location: data.location!,
        running: data.running!,
        city: data.city.isNotEmpty ? data.city : null,
        profile: profile,
      );
      appLogger.i(
        '[OnboardingBloc] saveOnboardingData SUCCESS — now reading back user',
      );

      // Also save the user name separately via updateProfile
      final updatedUser = (await _userRepo.getUser(
        userId,
      )).copyWith(name: data.name!);
      await _userRepo.updateProfile(updatedUser);

      appLogger.i(
        '[OnboardingBloc] updateProfile SUCCESS — profile exists=${updatedUser.profile != null}',
      );
      // NOTE: AuthBloc sync is deferred until AFTER plan generation below.
      // Syncing here would cause the router to see hasProfile=true and
      // prematurely redirect from /onboarding to /dashboard, aborting the
      // AI plan generation that follows.
    } catch (e, st) {
      appLogger.w('[OnboardingBloc] save FAILED', error: e, stackTrace: st);
      emit(OnboardingError(AppLocalizations.tl('onboardingSaveFailed')));
      return;
    }

    // Step 2: Generate workout plan + meal plan via workflow service
    emit(const OnboardingGeneratingPlan());
    try {
      appLogger.i('[OnboardingBloc] Calling generatePlans...');
      final plans = await _workflowService.generatePlans(
        userId: userId,
        profile: profile,
        city: data.city.isNotEmpty ? data.city : null,
      );

      appLogger.i(
        '[OnboardingBloc] generatePlans SUCCESS — emitting OnboardingComplete',
      );

      // NOW sync into AuthBloc so that subsequent router evaluations
      // see hasProfile=true and route to /dashboard instead of /onboarding.
      final updatedUser = (await _userRepo.getUser(
        userId,
      )).copyWith(name: data.name!);
      sl<AuthBloc>().add(AuthUserChanged(user: updatedUser));
      appLogger.i(
        '[OnboardingBloc] AuthUserChanged dispatched after plan generation',
      );

      emit(
        OnboardingComplete(
          workoutPlanJson: plans.workoutPlanJson,
          mealPlanJson: plans.mealPlanJson,
        ),
      );
      _track(
        () => sl<IAnalyticsService>().logOnboardingCompleted(
          goal: data.goal?.name ?? 'unknown',
        ),
      );
    } catch (e, st) {
      appLogger.w(
        '[OnboardingBloc] plan generation FAILED',
        error: e,
        stackTrace: st,
      );
      // Profile is saved — sync so the user lands on /dashboard on
      // next login even though plans couldn't be generated now.
      try {
        final updatedUser = (await _userRepo.getUser(
          userId,
        )).copyWith(name: data.name!);
        sl<AuthBloc>().add(AuthUserChanged(user: updatedUser));
      } catch (_) {}
      emit(OnboardingError(AppLocalizations.tl('onboardingPlanFailed')));
    }
  }

  Future<void> _track(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {
      /* best-effort */
    }
  }
}
