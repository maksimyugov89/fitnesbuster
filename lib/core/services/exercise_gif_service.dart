import 'package:fitnesbuster/core/services/exercise_matcher.dart';
import 'package:fitnesbuster/domain/entities/exercise_info.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';

/// Resolves AI-generated Russian exercise names to the local exercise
/// database and its GIF demo URL (served from Firebase Hosting CDN).
class ExerciseGifService implements IExerciseService {
  ExerciseGifService();

  @override
  Future<void> init() => ExerciseMatcher.instance.init();

  @override
  ExerciseInfo? findByRuName(String ruName) =>
      ExerciseMatcher.instance.findByRuName(ruName)?.toExerciseInfo();
}
