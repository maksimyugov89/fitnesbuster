import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/domain/exceptions/auth_exception.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;
  StreamSubscription<UserEntity?>? _userSubscription;

  AuthBloc({required IAuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthStateInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserChanged>(_onUserChanged);

    _userSubscription = _authRepository.userChanges.listen(
      (user) => add(AuthUserChanged(user: user)),
    );
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }

  void _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(AuthStateAuthenticated(user: user));
    } else {
      emit(const AuthStateUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      _track(() => sl<IAnalyticsService>().logLogin(method: 'email'));
      emit(AuthStateAuthenticated(user: user));
    } on AuthException catch (e) {
      appLogger.w('[AuthBloc] login error', error: e);
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e, st) {
      appLogger.w('[AuthBloc] login failed', error: e, stackTrace: st);
      emit(AuthStateError(message: AppLocalizations.tl('genericError')));
    }
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      _track(() => sl<IAnalyticsService>().logSignUp(method: 'email'));
      emit(AuthStateAuthenticated(user: user));
    } on AuthException catch (e) {
      appLogger.w('[AuthBloc] register error', error: e);
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e, st) {
      appLogger.w('[AuthBloc] register failed', error: e, stackTrace: st);
      emit(AuthStateError(message: AppLocalizations.tl('genericError')));
    }
  }

  Future<void> _onGoogleLoginRequested(AuthGoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      _track(() => sl<IAnalyticsService>().logLogin(method: 'google'));
      emit(AuthStateAuthenticated(user: user));
    } on AuthException catch (e) {
      appLogger.w('[AuthBloc] googleLogin error', error: e);
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e, st) {
      appLogger.w('[AuthBloc] googleLogin failed', error: e, stackTrace: st);
      if (e.toString().contains('cancelled')) {
        emit(const AuthStateUnauthenticated());
      } else {
        emit(AuthStateError(message: AppLocalizations.tl('googleLoginError')));
      }
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.logout();
    } catch (e, st) {
      appLogger.w('[AuthBloc] logout failed', error: e, stackTrace: st);
    }
    emit(const AuthStateUnauthenticated());
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(AuthStateAuthenticated(user: event.user!));
    } else {
      emit(const AuthStateUnauthenticated());
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return AppLocalizations.tl('userNotFound');
      case 'wrong-password': return AppLocalizations.tl('wrongPassword');
      case 'invalid-email': return AppLocalizations.tl('invalidEmail');
      case 'user-disabled': return AppLocalizations.tl('userDisabled');
      case 'email-already-in-use': return AppLocalizations.tl('emailAlreadyInUse');
      case 'weak-password': return AppLocalizations.tl('weakPassword');
      case 'operation-not-allowed': return AppLocalizations.tl('operationNotAllowed');
      case 'too-many-requests': return AppLocalizations.tl('tooManyRequests');
      default: return AppLocalizations.tl('loginError');
    }
  }

  Future<void> _track(Future<void> Function() fn) async {
    try { await fn(); } catch (_) { /* best-effort */ }
  }
}
