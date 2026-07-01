import 'package:fitnesbuster/domain/entities/exercise_info.dart';

abstract interface class IExerciseService {
  Future<void> init();

  /// Finds best matching ExerciseInfo for a Russian AI name. Returns null if no match.
  ExerciseInfo? findByRuName(String ruName);
}
