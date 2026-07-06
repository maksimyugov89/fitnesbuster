import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/body_measurement.dart';

abstract interface class IUserRepository {
  Future<UserEntity> getUser(String userId);
  Future<UserEntity> updateProfile(UserEntity user);
  Future<UserEntity> saveOnboardingData({
    required String userId,
    required FitnessGoal goal,
    required IntensityLevel intensity,
    String? location,
    String? running,
    String? city,
    UserProfile? profile,
  });
  Future<UserEntity> updateWorkoutSettings({
    required String userId,
    required String location,
    required String running,
  });
  Future<void> saveAiPlans({
    required String userId,
    required String workoutPlanJson,
    required String mealPlanJson,
  });
  Future<void> saveTestWeekCompleted({required String userId});
  Future<bool> isTestWeekCompleted(String userId);

  /// One-time migration write: seeds the server-tracked workout streak from
  /// the locally-computed value the first time this account is seen without
  /// a `lastWorkoutDate` field, so existing streaks aren't lost when the
  /// streak becomes server-authoritative (updated via `recordWorkout`
  /// from then on). Callers must only invoke this when the Firestore doc
  /// has no `lastWorkoutDate` yet — it unconditionally overwrites.
  Future<void> bootstrapStreak({
    required String userId,
    required int streak,
    required String lastWorkoutDate,
  });
  Future<void> updateGoal({required String userId, required FitnessGoal goal});
  Future<void> updateTrainingExperience({
    required String userId,
    required TrainingExperience trainingExperience,
  });
  Future<void> saveMeasurement({
    required String userId,
    required BodyMeasurement measurement,
  });
  Future<List<BodyMeasurement>> getMeasurements(String userId);
  Future<void> updateWorkoutPlan({
    required String userId,
    required String workoutPlanJson,
  });
  Future<Map<String, String?>> getAiPlans(String userId);
}
