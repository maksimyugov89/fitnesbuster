import 'dart:convert';
import 'package:flutter/services.dart';

/// Lookup into the bundled free-exercise-db JSON.
///
/// Primary source: assets/data/exercise_image_map.json
///   Pre-computed mapping: our English exercise name → free-db folder ID.
///   Covers ~209 exercises (38% of our DB).
///
/// Fallback: name-based prefix search in free_exercises.json
///   For any exercise not in the pre-computed map.
class FreeExerciseDb {
  static FreeExerciseDb? _instance;
  static FreeExerciseDb get instance => _instance ??= FreeExerciseDb._();
  FreeExerciseDb._();

  // Pre-computed map: our exercise name (lowercase) → free-db id
  final Map<String, String> _imageMap = {};

  // Fallback: free-db name (lowercase, normalized) → free-db id
  final Map<String, String> _exactIndex = {};
  final List<(String, String)> _sorted = [];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    // Load pre-computed mapping (primary)
    final mapRaw =
        await rootBundle.loadString('assets/data/exercise_image_map.json');
    final mapData = jsonDecode(mapRaw) as Map<String, dynamic>;
    for (final entry in mapData.entries) {
      _imageMap[entry.key.toLowerCase().trim()] = entry.value as String;
    }

    // Load free-exercise-db for fallback prefix matching
    final raw =
        await rootBundle.loadString('assets/data/free_exercises.json');
    final list = jsonDecode(raw) as List;
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id'] as String?;
      final name = entry['name'] as String?;
      if (id == null || id.isEmpty || name == null) continue;
      final key = name.toLowerCase().trim();
      _exactIndex[key] = id;
      _sorted.add((key, id));
    }
    _sorted.sort((a, b) => a.$1.compareTo(b.$1));
    _loaded = true;
  }

  /// Returns the free-exercise-db folder ID for the given English exercise name,
  /// or null if not found.
  ///
  /// Strategy:
  /// 1. Pre-computed map lookup (covers ~209 exercises)
  /// 2. Exact name match in free-db
  /// 3. Prefix match — free-db name starts with our name
  String? idForName(String englishName) {
    if (!_loaded) return null;
    final key = englishName.toLowerCase().trim();

    // Primary: pre-computed mapping
    if (_imageMap.containsKey(key)) return _imageMap[key];

    // Fallback: exact name in free-db
    if (_exactIndex.containsKey(key)) return _exactIndex[key];

    // Fallback: prefix — free-db name starts with our name
    for (final (n, id) in _sorted) {
      if (n.startsWith(key)) return id;
    }
    return null;
  }

  bool get isLoaded => _loaded;
}
