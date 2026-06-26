import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads exercise GIFs from ExerciseDB (via Firebase Cloud Function proxy)
/// and caches them locally in ApplicationDocumentsDirectory/exercise_gifs/.
///
/// The RapidAPI key never leaves the server — all API calls go through
/// the `exerciseDbProxy` Cloud Function, identical to how DeepSeek is handled.
class ExerciseGifService {
  ExerciseGifService();

  // Popular exercises to pre-cache after onboarding for a smooth first run.
  static const preloadExercises = <({String id, String name})>[
    (id: 'push_up',         name: 'Push Up'),
    (id: 'bodyweight_squat', name: 'Bodyweight Squat'),
    (id: 'barbell_bench_press', name: 'Barbell Bench Press'),
    (id: 'barbell_deadlift', name: 'Barbell Deadlift'),
    (id: 'pull_up',         name: 'Pull Up'),
    (id: 'lat_pulldown',    name: 'Lat Pulldown'),
    (id: 'barbell_overhead_press', name: 'Barbell Overhead Press'),
    (id: 'barbell_biceps_curl', name: 'Barbell Biceps Curl'),
    (id: 'cable_tricep_pushdown', name: 'Cable Tricep Pushdown'),
    (id: 'plank',           name: 'Plank'),
  ];

  Future<Directory> _gifsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/exercise_gifs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  File _gifFile(Directory dir, String exerciseId) =>
      File('${dir.path}/$exerciseId.gif');

  /// Returns the local file path to the GIF, downloading it on first access.
  /// Returns null if the API is unavailable or the exercise is not in ExerciseDB.
  Future<String?> getGifPath(String exerciseId, String exerciseName) async {
    final dir = await _gifsDir();
    final file = _gifFile(dir, exerciseId);

    if (file.existsSync()) return file.path;

    final gifUrl = await _fetchGifUrl(exerciseName);
    if (gifUrl == null) return null;

    return _downloadGif(gifUrl, file);
  }

  /// Deletes all cached GIFs (used in settings → "Очистить кэш").
  Future<void> clearCache() async {
    final dir = await _gifsDir();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  /// Pre-downloads popular exercises in the background (called after onboarding).
  Future<void> preloadPopular() async {
    for (final ex in preloadExercises) {
      await getGifPath(ex.id, ex.name);
    }
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  Future<String?> _fetchGifUrl(String exerciseName) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('exerciseDbProxy');
      final result =
          await callable.call<Map<String, dynamic>>({'exerciseName': exerciseName});
      return result.data['gifUrl'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('[ExerciseGifService] API error: $e');
      return null;
    }
  }

  Future<String?> _downloadGif(String url, File target) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      target.writeAsBytesSync(response.bodyBytes);
      return target.path;
    } catch (e) {
      if (kDebugMode) debugPrint('[ExerciseGifService] Download error: $e');
      return null;
    }
  }
}
