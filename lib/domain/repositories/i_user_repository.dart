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
  Future<void> updateGoal({required String userId, required FitnessGoal goal});
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
