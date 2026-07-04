import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

part 'user_entities.freezed.dart';
part 'user_entities.g.dart';

enum Gender { male, female }

enum FitnessGoal {
  loseWeight,
  gainWeight,
  maintain,
  beachBody,
  sportPerformance,
}

enum IntensityLevel { hardcore, intensive, balanced, gradual, relaxed }

enum ActivityLevel {
  sedentary(1.2),
  lightlyActive(1.375),
  moderatelyActive(1.55),
  veryActive(1.725),
  extraActive(1.9);

  const ActivityLevel(this.multiplier);
  final double multiplier;

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return AppLocalizations.tl('activitySedentaryLabel');
      case ActivityLevel.lightlyActive:
        return AppLocalizations.tl('activityLightLabel');
      case ActivityLevel.moderatelyActive:
        return AppLocalizations.tl('activityModerateLabel');
      case ActivityLevel.veryActive:
        return AppLocalizations.tl('activityHighLabel');
      case ActivityLevel.extraActive:
        return AppLocalizations.tl('activityVeryHighLabel');
    }
  }
}

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  abs,
  glutes,
  quads,
  hamstrings,
  calves,
  fullBody,
  cardio,
}

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    UserProfile? profile,
    required DateTime createdAt,
    // Server-authoritative workout streak (Cloud Function `recordWorkout`
    // increments/resets these on each completed workout) — kept at the
    // top level, alongside name/email, since it's account-wide account
    // state rather than a fitness-profile attribute.
    int? currentStreak,
    String? lastWorkoutDate,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}

@freezed
class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required double weight,
    required double height,
    required int age,
    DateTime? dateOfBirth,
    required Gender gender,
    required FitnessGoal goal,
    required IntensityLevel intensity,
    @Default([]) List<String> medicalRestrictions,
    @Default([]) List<String> exerciseRestrictions,
    required ActivityLevel activityLevel,
    double? targetWeight,
    DateTime? targetDate,
    @Default(false) bool testWeekCompleted,
    @Default([]) List<TestExerciseResult> testResults,
    String? workoutLocation,
    String? runningPreference,
    String? city,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  static const defaults = UserProfile(
    weight: 80,
    height: 175,
    age: 30,
    gender: Gender.male,
    goal: FitnessGoal.loseWeight,
    intensity: IntensityLevel.balanced,
    activityLevel: ActivityLevel.moderatelyActive,
  );

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

  double get bmr {
    final base = (10 * weight) + (6.25 * height) - (5 * age);
    return gender == Gender.male ? base + 5 : base - 161;
  }

  double get tdee => bmr * activityLevel.multiplier;

  double get dailyCalorieTarget {
    switch (goal) {
      case FitnessGoal.loseWeight:
        return tdee - 500;
      case FitnessGoal.gainWeight:
        return tdee + 500;
      case FitnessGoal.maintain:
        return tdee;
      case FitnessGoal.beachBody:
        return tdee - 300;
      case FitnessGoal.sportPerformance:
        return tdee + 200;
    }
  }
}

@freezed
class TestExerciseResult with _$TestExerciseResult {
  const factory TestExerciseResult({
    required String exerciseName,
    required MuscleGroup primaryMuscle,
    required double comfortableWeightKg,
    required int comfortableSets,
    required int comfortableReps,
    String? notes,
  }) = _TestExerciseResult;

  factory TestExerciseResult.fromJson(Map<String, dynamic> json) =>
      _$TestExerciseResultFromJson(json);
}
