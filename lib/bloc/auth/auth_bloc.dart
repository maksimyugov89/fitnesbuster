import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;
  StreamSubscription<UserEntity?>? _userSubscription;

  AuthBloc({required IAuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthStateUnknown()) {
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
      emit(AuthStateAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthStateError(message: 'Произошла ошибка. Попробуйте снова.'));
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
      emit(AuthStateAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthStateError(message: 'Произошла ошибка. Попробуйте снова.'));
    }
  }

  Future<void> _onGoogleLoginRequested(AuthGoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthStateLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthStateAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthStateError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('отменён')) {
        emit(const AuthStateUnauthenticated());
      } else {
        emit(AuthStateError(message: 'Ошибка входа через Google. Попробуйте снова.'));
      }
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
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
      case 'user-not-found': return 'Пользователь не найден';
      case 'wrong-password': return 'Неверный пароль';
      case 'invalid-email': return 'Неверный формат email';
      case 'user-disabled': return 'Пользователь заблокирован';
      case 'email-already-in-use': return 'Email уже используется';
      case 'weak-password': return 'Слишком слабый пароль (минимум 6 символов)';
      case 'operation-not-allowed': return 'Вход через email выключен';
      case 'too-many-requests': return 'Слишком много попыток. Попробуйте позже.';
      default: return 'Произошла ошибка входа. Попробуйте снова.';
    }
  }
}
