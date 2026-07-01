part of 'user_bloc.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class UserLoadRequested extends UserEvent {
  final String userId;
  const UserLoadRequested({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class UserUpdateProfile extends UserEvent {
  final String name;
  final String email;
  const UserUpdateProfile({required this.name, required this.email});
  @override
  List<Object?> get props => [name, email];
}

class UserUpdateBodyParams extends UserEvent {
  final double weight;
  final double height;
  final int age;
  final Gender gender;
  const UserUpdateBodyParams({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
  });
  @override
  List<Object?> get props => [weight, height, age, gender];
}

class UserUpdateGoal extends UserEvent {
  final FitnessGoal goal;
  final IntensityLevel intensity;
  final String? location;
  final String? running;
  const UserUpdateGoal({
    required this.goal,
    required this.intensity,
    this.location,
    this.running,
  });
  @override
  List<Object?> get props => [goal, intensity, location ?? '', running ?? ''];
}

class UserUpdateSettings extends UserEvent {
  final String location;
  final String running;
  const UserUpdateSettings({required this.location, required this.running});
  @override
  List<Object?> get props => [location, running];
}
