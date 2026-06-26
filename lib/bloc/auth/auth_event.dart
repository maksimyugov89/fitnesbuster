part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
  @override List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override List<Object?> get props => [email]; // password excluded — never expose in logs
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const AuthRegisterRequested({required this.name, required this.email, required this.password});
  @override List<Object?> get props => [name, email]; // password excluded — never expose in logs
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
  @override List<Object?> get props => [];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
  @override List<Object?> get props => [];
}

class AuthUserChanged extends AuthEvent {
  final UserEntity? user;
  const AuthUserChanged({this.user});
  @override List<Object?> get props => [user];
}
