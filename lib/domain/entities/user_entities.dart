enum Gender { male, female }

enum FitnessGoal {
  loseWeight,
  gainWeight,
  maintain,
  beachBody,
  sportPerformance,
}

enum IntensityLevel {
  hardcore,
  intensive,
  balanced,
  gradual,
  relaxed,
}

enum ActivityLevel {
  sedentary(1.2, 'Сидячий образ жизни'),
  lightlyActive(1.375, 'Лёгкая активность 1-3 дня/нед'),
  moderatelyActive(1.55, 'Умеренная активность 3-5 дней/нед'),
  veryActive(1.725, 'Высокая активность 6-7 дней/нед'),
  extraActive(1.9, 'Очень высокая активность');

  const ActivityLevel(this.multiplier, this.label);
  final double multiplier;
  final String label;
}

class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserProfile? profile;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.profile,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    UserProfile? profile,
    DateTime? createdAt,
    bool clearAvatar = false,
    bool clearProfile = false,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      profile: clearProfile ? null : (profile ?? this.profile),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserProfile {
  final double weight;
  final double height;
  final int age;
  final Gender gender;
  final FitnessGoal goal;
  final IntensityLevel intensity;
  final List<String> medicalRestrictions;
  final List<String> exerciseRestrictions;
  final ActivityLevel activityLevel;
  final double? targetWeight;
  final DateTime? targetDate;
  final bool testWeekCompleted;
  final List<TestExerciseResult> testResults;
  final String? workoutLocation;
  final String? runningPreference;
  final String? city;

  const UserProfile({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.goal,
    required this.intensity,
    this.medicalRestrictions = const [],
    this.exerciseRestrictions = const [],
    required this.activityLevel,
    this.targetWeight,
    this.targetDate,
    this.testWeekCompleted = false,
    this.testResults = const [],
    this.workoutLocation,
    this.runningPreference,
    this.city,
  });

  UserProfile copyWith({
    double? weight,
    double? height,
    int? age,
    Gender? gender,
    FitnessGoal? goal,
    IntensityLevel? intensity,
    List<String>? medicalRestrictions,
    List<String>? exerciseRestrictions,
    ActivityLevel? activityLevel,
    double? targetWeight,
    DateTime? targetDate,
    bool? testWeekCompleted,
    List<TestExerciseResult>? testResults,
    String? workoutLocation,
    String? runningPreference,
    String? city,
  }) {
    return UserProfile(
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      intensity: intensity ?? this.intensity,
      medicalRestrictions: medicalRestrictions ?? this.medicalRestrictions,
      exerciseRestrictions: exerciseRestrictions ?? this.exerciseRestrictions,
      activityLevel: activityLevel ?? this.activityLevel,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDate: targetDate ?? this.targetDate,
      testWeekCompleted: testWeekCompleted ?? this.testWeekCompleted,
      testResults: testResults ?? this.testResults,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      runningPreference: runningPreference ?? this.runningPreference,
      city: city ?? this.city,
    );
  }

  int get estimatedWeeksNeeded {
    if (targetWeight == null) return 4;
    final diff = (weight - targetWeight!).abs() / 0.5;
    return diff.round().clamp(4, 52);
  }

  bool get isGoalRealistic {
    if (targetDate == null) return true;
    final now = DateTime.now();
    if (!targetDate!.isAfter(now)) return false;
    final availableWeeks = targetDate!.difference(now).inDays / 7;
    return estimatedWeeksNeeded <= availableWeeks;
  }

  double get bmi {
    if (height <= 0) return 0;
    final h = height / 100;
    return weight / (h * h);
  }

  /// Harris-Benedict BMR
  double get bmr {
    if (gender == Gender.male) {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  double get tdee => bmr * activityLevel.multiplier;

  double get dailyCalorieTarget {
    switch (goal) {
      case FitnessGoal.loseWeight: return tdee - 500;
      case FitnessGoal.gainWeight: return tdee + 500;
      case FitnessGoal.maintain: return tdee;
      case FitnessGoal.beachBody: return tdee - 300;
      case FitnessGoal.sportPerformance: return tdee + 200;
    }
  }
}

// Forward declaration — defined in workout_entities.dart, referenced by UserProfile.testResults
// Dart resolves these within the same barrel export.
class TestExerciseResult {
  final String exerciseName;
  final MuscleGroup primaryMuscle;
  final double comfortableWeightKg;
  final int comfortableSets;
  final int comfortableReps;
  final String? notes;

  const TestExerciseResult({
    required this.exerciseName,
    required this.primaryMuscle,
    required this.comfortableWeightKg,
    required this.comfortableSets,
    required this.comfortableReps,
    this.notes,
  });
}

enum MuscleGroup {
  chest, back, shoulders, biceps, triceps, forearms,
  abs, glutes, quads, hamstrings, calves, fullBody, cardio
}
