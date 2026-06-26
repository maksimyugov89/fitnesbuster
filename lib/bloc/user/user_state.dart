part of 'user_bloc.dart';

sealed class UserState extends Equatable {
  const UserState();
  @override List<Object?> get props => [];
}

class UserStateUnknown extends UserState {
  const UserStateUnknown();
}

class UserStateLoading extends UserState {
  const UserStateLoading();
}

class UserStateLoaded extends UserState {
  final UserEntity user;
  const UserStateLoaded({required this.user});
  @override List<Object?> get props => [user];
}

class UserStateError extends UserState {
  final String message;
  const UserStateError({required this.message});
  @override List<Object?> get props => [message];
}
