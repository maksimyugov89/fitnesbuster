part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();
  @override List<Object?> get props => [];
}

class OnboardingCollecting extends OnboardingState {
  final FitnessGoal? goal;
  final IntensityLevel? intensity;
  final String? location;
  final String? running;
  final String? name;
  final int? age;
  final double? weight;
  final double? height;
  final Gender? gender;
  final ActivityLevel? activity;
  final List<String> restrictions;
  final String city;

  const OnboardingCollecting({
    this.goal,
    this.intensity,
    this.location,
    this.running,
    this.name,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.activity,
    this.restrictions = const [],
    this.city = '',
  });

  UserProfile toUserProfile() => UserProfile(
    weight: weight ?? 75,
    height: height ?? 175,
    age: age ?? 25,
    gender: gender ?? Gender.male,
    goal: goal ?? FitnessGoal.loseWeight,
    intensity: intensity ?? IntensityLevel.balanced,
    activityLevel: activity ?? ActivityLevel.moderatelyActive,
    medicalRestrictions: restrictions,
    city: city.isNotEmpty ? city : null,
  );

  bool get isComplete =>
      goal != null && intensity != null && location != null && running != null &&
      name != null && age != null && weight != null && height != null && gender != null;

  OnboardingCollecting copyWith({
    FitnessGoal? goal,
    IntensityLevel? intensity,
    String? location,
    String? running,
    String? name,
    int? age,
    double? weight,
    double? height,
    Gender? gender,
    ActivityLevel? activity,
    List<String>? restrictions,
    String? city,
  }) => OnboardingCollecting(
    goal: goal ?? this.goal,
    intensity: intensity ?? this.intensity,
    location: location ?? this.location,
    running: running ?? this.running,
    name: name ?? this.name,
    age: age ?? this.age,
    weight: weight ?? this.weight,
    height: height ?? this.height,
    gender: gender ?? this.gender,
    activity: activity ?? this.activity,
    restrictions: restrictions ?? this.restrictions,
    city: city ?? this.city,
  );

  @override List<Object?> get props => [goal, intensity, location, running, name, age, weight, height, gender, activity, restrictions, city];
}

class OnboardingSaving extends OnboardingState {
  const OnboardingSaving();
}

class OnboardingGeneratingPlan extends OnboardingState {
  const OnboardingGeneratingPlan();
}

class OnboardingComplete extends OnboardingState {
  final String workoutPlanJson;
  final String mealPlanJson;
  const OnboardingComplete({required this.workoutPlanJson, required this.mealPlanJson});
  @override List<Object?> get props => [workoutPlanJson, mealPlanJson];
}

class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);
  @override List<Object?> get props => [message];
}
