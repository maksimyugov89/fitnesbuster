import 'package:fitnesbuster/domain/entities/exercise_info.dart';

abstract interface class IExerciseService {
  Future<String?> getGifPath(String exerciseId, String exerciseName);
  Future<void> clearCache();
  Future<void> preloadPopular();

  /// Finds best matching ExerciseInfo for a Russian AI name. Returns null if no match.
  ExerciseInfo? findByRuName(String ruName);
  Future<void> init();
}
