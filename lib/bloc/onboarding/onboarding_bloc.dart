import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// Collects all onboarding data step-by-step and triggers plan generation via DeepSeek.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final IUserRepository _userRepo;
  final IDeepSeekService _aiService;
  final IAuthRepository _authRepo;

  OnboardingBloc({
    required IUserRepository userRepo,
    required IDeepSeekService aiService,
    required IAuthRepository authRepo,
  })  : _userRepo = userRepo,
        _aiService = aiService,
        _authRepo = authRepo,
        super(const OnboardingCollecting()) {
    on<OnboardingSetGoal>(_onSetGoal);
    on<OnboardingSetIntensity>(_onSetIntensity);
    on<OnboardingSetLocation>(_onSetLocation);
    on<OnboardingSetProfile>(_onSetProfile);
    on<OnboardingFinalize>(_onFinalize);
  }

  OnboardingCollecting _collecting() =>
      state is OnboardingCollecting ? state as OnboardingCollecting : const OnboardingCollecting();

  void _onSetGoal(OnboardingSetGoal e, Emitter<OnboardingState> emit) {
    emit(_collecting().copyWith(goal: e.goal));
  }

  void _onSetIntensity(OnboardingSetIntensity e, Emitter<OnboardingState> emit) {
    emit(_collecting().copyWith(intensity: e.intensity));
  }

  void _onSetLocation(OnboardingSetLocation e, Emitter<OnboardingState> emit) {
    emit(_collecting().copyWith(location: e.location, running: e.running));
  }

  void _onSetProfile(OnboardingSetProfile e, Emitter<OnboardingState> emit) {
    final s = _collecting();
    emit(s.copyWith(
      name: e.name,
      age: e.age,
      weight: e.weight,
      height: e.height,
      gender: e.gender,
      activity: e.activity,
      restrictions: e.restrictions,
      city: e.city,
    ));
  }

  Future<void> _onFinalize(
    OnboardingFinalize event,
    Emitter<OnboardingState> emit,
  ) async {
    final data = _collecting();
    if (!data.isComplete) {
      emit(OnboardingError(AppLocalizations.tl('onboardingIncomplete')));
      return;
    }

    final userId = _authRepo.currentUser?.id ?? 'local';
    final profile = data.toUserProfile();

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
      // Also save the user name separately via updateProfile
      await _userRepo.updateProfile(
        (await _userRepo.getUser(userId)).copyWith(name: data.name!),
      );
    } catch (e, st) {
      appLogger.w('[OnboardingBloc] save failed', error: e, stackTrace: st);
      emit(OnboardingError(AppLocalizations.tl('onboardingSaveFailed')));
      return;
    }

    // Step 2: Generate workout plan + meal plan via DeepSeek AI
    emit(const OnboardingGeneratingPlan());
    try {
      final workoutPlan = await _aiService.generateWorkoutPlan(profile);
      final mealPlan = await _aiService.generateMealPlan(
        profile,
        city: data.city.isNotEmpty ? data.city : null,
      );

      // Save plans to Firestore so they persist (non-fatal if fails)
      try {
        await _userRepo.saveAiPlans(
          userId: userId,
          workoutPlanJson: workoutPlan,
          mealPlanJson: mealPlan,
        );
      } catch (e, st) {
        appLogger.w('[OnboardingBloc] AI plans save failed', error: e, stackTrace: st);
      }

      emit(OnboardingComplete(
        workoutPlanJson: workoutPlan,
        mealPlanJson: mealPlan,
      ));
    } catch (e, st) {
      appLogger.w('[OnboardingBloc] plan generation failed', error: e, stackTrace: st);
      emit(OnboardingError(AppLocalizations.tl('onboardingPlanFailed')));
    }
  }
}
