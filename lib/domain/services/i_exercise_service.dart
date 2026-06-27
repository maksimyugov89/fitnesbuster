import 'package:fitnesbuster/data/models/exercise_db_model.dart';

abstract interface class IExerciseService {
  Future<String?> getGifPath(String exerciseId, String exerciseName);
  Future<void> clearCache();
  Future<void> preloadPopular();

  /// Finds best matching ExerciseDbModel for a Russian AI name. Returns null if no match.
  ExerciseDbModel? findByRuName(String ruName);
  Future<void> init();
}
