part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final UserEntity user;
  final bool emailVerified;
  const AuthStateAuthenticated({required this.user, this.emailVerified = true});
  String get userId => user.id;
  @override
  List<Object?> get props => [user, emailVerified];
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateLegalConsentRequired extends AuthState {
  final LegalConsentSource source;
  const AuthStateLegalConsentRequired({this.source = LegalConsentSource.login});
  @override
  List<Object?> get props => [source];
}

class AuthStateError extends AuthState {
  final String message;
  const AuthStateError({required this.message});
  @override
  List<Object?> get props => [message];
}
