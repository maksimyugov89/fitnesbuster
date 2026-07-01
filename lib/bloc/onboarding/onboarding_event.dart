part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class OnboardingSetGoal extends OnboardingEvent {
  final FitnessGoal goal;
  const OnboardingSetGoal(this.goal);
  @override
  List<Object?> get props => [goal];
}

class OnboardingSetIntensity extends OnboardingEvent {
  final IntensityLevel intensity;
  const OnboardingSetIntensity(this.intensity);
  @override
  List<Object?> get props => [intensity];
}

class OnboardingSetLocation extends OnboardingEvent {
  final String location;
  final String running;
  const OnboardingSetLocation({required this.location, required this.running});
  @override
  List<Object?> get props => [location, running];
}

class OnboardingSetProfile extends OnboardingEvent {
  final String name;
  final int age;
  final double weight;
  final double height;
  final Gender gender;
  final ActivityLevel activity;
  final List<String> restrictions;
  final String city;
  const OnboardingSetProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activity,
    this.restrictions = const [],
    this.city = '',
  });
  @override
  List<Object?> get props => [
    name,
    age,
    weight,
    height,
    gender,
    activity,
    restrictions,
    city,
  ];
}

class OnboardingFinalize extends OnboardingEvent {
  const OnboardingFinalize();
}
