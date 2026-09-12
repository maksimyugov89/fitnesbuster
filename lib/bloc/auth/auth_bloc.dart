import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/domain/exceptions/auth_exception.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/legal/legal_consent.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;
  StreamSubscription<UserEntity?>? _userSubscription;

  /// Set while the consent dialog is on screen; `true` when accepting it
  /// finishes a registration that has just been created (analytics: sign_up).
  bool _consentFinishesNewRegistration = false;

  AuthBloc({required IAuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthStateInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLegalConsentAccepted>(_onLegalConsentAccepted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthEmailVerificationChecked>(_onEmailVerificationChecked);

    _userSubscription = _authRepository.userChanges.listen(
      (user) => add(AuthUserChanged(user: user)),
    );
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final fastUser = _authRepository.currentUser;
    if (fastUser == null) {
      emit(const AuthStateUnauthenticated());
      return;
    }

    // Verify the user still exists on the server. If the account was deleted
    // but the local Firebase Auth cache was not cleared (e.g. network error
    // during the Cloud Function call), force a sign-out so the user cannot
    // re-enter a deleted account.
    try {
      await _authRepository.reloadUser();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'user-token-expired' ||
          e.code == 'user-disabled') {
        await _authRepository.signOut();
        emit(const AuthStateUnauthenticated());
        return;
      }
      // Network / transient errors: continue with cached user so offline
      // mode still works.
    } catch (_) {
      // Non-FirebaseAuth exceptions: continue with cached user.
    }

    if (!await _authRepository.hasCurrentLegalConsent()) {
      _consentFinishesNewRegistration = false;
      emit(const AuthStateLegalConsentRequired());
      return;
    }

    // Fetch the full Firestore profile BEFORE emitting any AuthState.
    // Previously the intermediate emit (without profile) could cause the
    // splash screen to navigate to /dashboard with hasProfile=false,
    // which the router would then redirect to /onboarding — trapping the
    // user in an infinite onboarding loop even though Firestore has a
    // complete profile.
    final fullUser = await _authRepository.getCurrentUserWithProfile();

    emit(
      AuthStateAuthenticated(
        user: fullUser ?? fastUser,
        emailVerified: _authRepository.isEmailVerified,
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      _track(() => sl<IAnalyticsService>().logLogin(method: 'email'));
      emit(
        AuthStateAuthenticated(
          user: user,
          emailVerified: _authRepository.isEmailVerified,
        ),
      );
    } on AuthException catch (e) {
      appLogger.w('[AuthBloc] login error', error: e);
      if (e.code == 'terms-required' && _authRepository.currentUser != null) {
        _consentFinishesNewRegistration = false;
        emit(const AuthStateLegalConsentRequired());
      } else {
        emit(AuthStateError(message: _mapFirebaseError(e.code)));
      }
    } catch (e, st) {
      appLogger.w('[AuthBloc] login failed', error: e, stackTrace: st);
      emit(AuthStateError(message: AppLocalizations.tl('genericError')));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
        consent: event.consent,
      );
      _track(() => sl<IAnalyticsService>().logSignUp(method: 'email'));
      emit(
        AuthStateAuthenticated(
          user: user,
          emailVerified: _authRepository.isEmailVerified,
        ),
      );
    } on AuthException catch (e) {
      appLogger.w('[AuthBloc] register error', error: e);
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e, st) {
      appLogger.w('[AuthBloc] register failed', error: e, stackTrace: st);
      emit(AuthStateError(message: AppLocalizations.tl('genericError')));
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.signInWithGoogle(
        newAccountConsent: event.newAccountConsent,
      );
      _track(
        () => event.newAccountConsent == null
            ? sl<IAnalyticsService>().logLogin(method: 'google')
            : sl<IAnalyticsService>().logSignUp(method: 'google'),
      );
      emit(
        AuthStateAuthenticated(
          user: user,
          emailVerified: _authRepository.isEmailVerified,
        ),
      );
    } on AuthException catch (e) {
      appLogger.w('[AuthBloc] googleLogin error', error: e);
      if (e.code == 'terms-required' && _authRepository.currentUser != null) {
        _consentFinishesNewRegistration =
            e is TermsRequiredException && e.isNewRegistration;
        emit(
          const AuthStateLegalConsentRequired(
            source: LegalConsentSource.googleLogin,
          ),
        );
      } else {
        emit(AuthStateError(message: _mapFirebaseError(e.code)));
      }
    } catch (e, st) {
      appLogger.w('[AuthBloc] googleLogin failed', error: e, stackTrace: st);
      if (e.toString().contains('cancelled')) {
        emit(const AuthStateUnauthenticated());
      } else {
        emit(AuthStateError(message: AppLocalizations.tl('googleLoginError')));
      }
    }
  }

  Future<void> _onLegalConsentAccepted(
    AuthLegalConsentAccepted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.acceptCurrentLegalConsent(
        consent: event.consent,
      );
      _track(
        () => _consentFinishesNewRegistration
            ? sl<IAnalyticsService>().logSignUp(method: 'google')
            : sl<IAnalyticsService>().logLogin(method: 'google'),
      );
      _consentFinishesNewRegistration = false;
      emit(
        AuthStateAuthenticated(
          user: user,
          emailVerified: _authRepository.isEmailVerified,
        ),
      );
    } on AuthException catch (e) {
      appLogger.w('[AuthBloc] legal consent accept error', error: e);
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e, st) {
      appLogger.w(
        '[AuthBloc] legal consent accept failed',
        error: e,
        stackTrace: st,
      );
      emit(AuthStateError(message: AppLocalizations.tl('genericError')));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
    } catch (e, st) {
      appLogger.w('[AuthBloc] logout failed', error: e, stackTrace: st);
    }
    emit(const AuthStateUnauthenticated());
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (state is AuthStateLoading || state is AuthStateLegalConsentRequired) {
      return;
    }
    if (event.user != null) {
      emit(
        AuthStateAuthenticated(
          user: event.user!,
          emailVerified: _authRepository.isEmailVerified,
        ),
      );
    } else {
      emit(const AuthStateUnauthenticated());
    }
  }

  Future<void> _onEmailVerificationChecked(
    AuthEmailVerificationChecked event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthStateAuthenticated) return;
    try {
      final verified = await _authRepository.reloadAndCheckEmailVerified();
      emit(AuthStateAuthenticated(user: current.user, emailVerified: verified));
    } catch (e, st) {
      appLogger.w(
        '[AuthBloc] email verification check failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return AppLocalizations.tl('userNotFound');
      case 'wrong-password':
        return AppLocalizations.tl('wrongPassword');
      case 'invalid-email':
        return AppLocalizations.tl('invalidEmail');
      case 'user-disabled':
        return AppLocalizations.tl('userDisabled');
      case 'email-already-in-use':
        return AppLocalizations.tl('emailAlreadyInUse');
      case 'weak-password':
        return AppLocalizations.tl('weakPassword');
      case 'operation-not-allowed':
        return AppLocalizations.tl('operationNotAllowed');
      case 'too-many-requests':
        return AppLocalizations.tl('tooManyRequests');
      case 'terms-required':
        return AppLocalizations.tl('authTermsRequired');
      default:
        return AppLocalizations.tl('loginError');
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
