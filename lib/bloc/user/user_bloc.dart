import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final IUserRepository _userRepository;

  UserBloc({required IUserRepository userRepository})
      : _userRepository = userRepository,
        super(const UserStateUnknown()) {
    on<UserLoadRequested>(_onLoadRequested);
    on<UserUpdateProfile>(_onUpdateProfile);
    on<UserUpdateBodyParams>(_onUpdateBodyParams);
    on<UserUpdateGoal>(_onUpdateGoal);
    on<UserUpdateSettings>(_onUpdateSettings);
  }

  Future<void> _onLoadRequested(UserLoadRequested event, Emitter<UserState> emit) async {
    emit(const UserStateLoading());
    try {
      final user = await _userRepository.getUser(event.userId);
      emit(UserStateLoaded(user: user));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[UserBloc] getUser failed: $e\n$st');
      emit(const UserStateError(message: 'Не удалось загрузить профиль. Попробуйте снова.'));
    }
  }

  Future<void> _onUpdateProfile(UserUpdateProfile event, Emitter<UserState> emit) async {
    if (state is! UserStateLoaded) return;
    final current = (state as UserStateLoaded).user;
    try {
      final updated = await _userRepository.updateProfile(
        current.copyWith(name: event.name, email: event.email),
      );
      emit(UserStateLoaded(user: updated));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[UserBloc] updateProfile failed: $e\n$st');
      emit(const UserStateError(message: 'Не удалось сохранить профиль. Попробуйте снова.'));
    }
  }

  Future<void> _onUpdateBodyParams(UserUpdateBodyParams event, Emitter<UserState> emit) async {
    if (state is! UserStateLoaded) return;
    final current = (state as UserStateLoaded).user;
    final profile = current.profile ?? UserProfile(
      weight: event.weight, height: event.height, age: event.age,
      gender: event.gender, goal: FitnessGoal.loseWeight,
      intensity: IntensityLevel.balanced,
      activityLevel: ActivityLevel.moderatelyActive,
    );
    final updatedProfile = profile.copyWith(
      weight: event.weight, height: event.height,
      age: event.age, gender: event.gender,
    );
    try {
      final updated = await _userRepository.updateProfile(
        current.copyWith(profile: updatedProfile),
      );
      emit(UserStateLoaded(user: updated));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[UserBloc] updateBodyParams failed: $e\n$st');
      emit(const UserStateError(message: 'Не удалось сохранить параметры. Попробуйте снова.'));
    }
  }

  Future<void> _onUpdateGoal(UserUpdateGoal event, Emitter<UserState> emit) async {
    if (state is! UserStateLoaded) return;
    final current = (state as UserStateLoaded).user;
    try {
      final updated = await _userRepository.saveOnboardingData(
        userId: current.id,
        goal: event.goal,
        intensity: event.intensity,
        location: event.location,
        running: event.running,
        profile: current.profile,
      );
      emit(UserStateLoaded(user: updated));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[UserBloc] updateGoal failed: $e\n$st');
      emit(const UserStateError(message: 'Не удалось сохранить цель. Попробуйте снова.'));
    }
  }

  Future<void> _onUpdateSettings(UserUpdateSettings event, Emitter<UserState> emit) async {
    if (state is! UserStateLoaded) return;
    final current = (state as UserStateLoaded).user;
    try {
      final updated = await _userRepository.updateWorkoutSettings(
        userId: current.id,
        location: event.location,
        running: event.running,
      );
      emit(UserStateLoaded(user: updated));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[UserBloc] updateSettings failed: $e\n$st');
      emit(const UserStateError(message: 'Не удалось сохранить настройки. Попробуйте снова.'));
    }
  }
}
