import 'package:fitnesbuster/data/models/exercise_db_model.dart';
import 'package:fitnesbuster/data/models/free_exercise_db.dart';

class ExerciseMatcher {
  static ExerciseMatcher? _instance;
  static ExerciseMatcher get instance => _instance ??= ExerciseMatcher._();
  ExerciseMatcher._();

  List<ExerciseDbModel> _db = [];
  Map<String, ExerciseDbModel> _exactIndex = {}; // nameRu.toLowerCase() → model

  Future<void> init() async {
    if (_db.isNotEmpty) return;
    await Future.wait([_loadDb(), FreeExerciseDb.instance.load()]);
  }

  Future<void> _loadDb() async {
    _db = await ExerciseDatabase.load();
    _exactIndex = {for (final ex in _db) ex.nameRu.toLowerCase().trim(): ex};
  }

  /// Finds best matching ExerciseDbModel for a Russian AI name. Returns null if no match.
  ExerciseDbModel? findByRuName(String ruName) {
    if (_db.isEmpty) return null;
    final key = ruName.toLowerCase().trim();

    // 1. Exact match
    if (_exactIndex.containsKey(key)) return _exactIndex[key];

    // 2. Substring match (AI name is contained in db nameRu or vice versa)
    for (final ex in _db) {
      final dbKey = ex.nameRu.toLowerCase();
      if (dbKey.contains(key) || key.contains(dbKey)) return ex;
    }

    // 3. Word overlap — count common words, return best if ≥ 2 words match
    final queryWords = key
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();
    ExerciseDbModel? best;
    int bestScore = 1; // minimum 2 matching words
    for (final ex in _db) {
      final dbWords = ex.nameRu.toLowerCase().split(RegExp(r'\s+')).toSet();
      final overlap = queryWords.intersection(dbWords).length;
      if (overlap > bestScore) {
        bestScore = overlap;
        best = ex;
      }
    }
    return best;
  }
}
