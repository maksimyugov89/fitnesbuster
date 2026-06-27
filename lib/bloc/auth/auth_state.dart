part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

class AuthStateUnknown extends AuthState {
  const AuthStateUnknown();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final UserEntity user;
  const AuthStateAuthenticated({required this.user});
  String get userId => user.id;
  @override List<Object?> get props => [user];
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;
  const AuthStateError({required this.message});
  @override List<Object?> get props => [message];
}
