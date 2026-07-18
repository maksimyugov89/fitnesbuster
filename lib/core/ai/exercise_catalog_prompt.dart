import 'dart:convert';

import 'package:fitnesbuster/core/ai/ai_exception.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/data/models/exercise_db_model.dart';

class ExerciseCatalogContext {
  final String promptBlock;
  final Set<String> exactNames;

  const ExerciseCatalogContext({
    required this.promptBlock,
    required this.exactNames,
  });
}

/// Builds a compact, location-safe subset of the exercise database for AI.
/// Sending all 1,300+ rows would dilute the prompt, so the selection is
/// balanced across muscles and capped deterministically.
class ExerciseCatalogPrompt {
  static const int maxExercises = 120;
  static const int perMuscle = 5;

  Future<ExerciseCatalogContext> build(String? workoutLocation) async {
    try {
      return buildFrom(await ExerciseDatabase.load(), workoutLocation);
    } catch (_) {
      return const ExerciseCatalogContext(
        promptBlock:
            'Каталог приложения временно недоступен. Используй только базовые '
            'упражнения с собственным весом и не предполагай наличие оборудования.',
        exactNames: {},
      );
    }
  }

  ExerciseCatalogContext buildFrom(
    List<ExerciseDbModel> exercises,
    String? workoutLocation,
  ) {
    final allowed = _allowedEquipment(workoutLocation);
    final filtered = exercises
        .where((exercise) => exercise.equipment.any(allowed.contains))
        .toList();

    final selected = <ExerciseDbModel>[];
    for (final muscle in ExMuscle.values) {
      final group =
          filtered
              .where((exercise) => exercise.primaryMuscles.contains(muscle))
              .toList()
            ..sort((a, b) {
              final difficulty = a.difficulty.index.compareTo(
                b.difficulty.index,
              );
              if (difficulty != 0) return difficulty;
              return a.nameRu.length.compareTo(b.nameRu.length);
            });
      selected.addAll(group.take(perMuscle));
      if (selected.length >= maxExercises) break;
    }

    final unique = <String, ExerciseDbModel>{};
    for (final exercise in selected.take(maxExercises)) {
      unique.putIfAbsent(exercise.nameRu.trim().toLowerCase(), () => exercise);
    }

    final lines = unique.values.map(
      (exercise) =>
          '- ${exercise.nameRu} [${exercise.equipment.map((e) => e.name).join('/')}]',
    );
    final location = switch (workoutLocation) {
      'gym' => 'тренажёрный зал',
      'outdoor' => 'стадион / уличная площадка',
      'home' => 'дом',
      _ => 'место не указано — безопасный режим без оборудования',
    };

    return ExerciseCatalogContext(
      promptBlock: '''Место: $location.
Ниже — упражнения, уже реализованные в FitnesBuster (анимации, карточки и сопоставление мышц).
ОБЯЗАТЕЛЬНО выбирай названия ТОЧНО из этого списка. Новое упражнение допустимо только если в списке нет безопасного аналога для нужной мышцы/ограничения; это исключение пометь полем "catalog_status": "new" и объясни причину в notes. Для упражнений из списка ставь "catalog_status": "existing".
${lines.join('\n')}''',
      exactNames: unique.values.map((e) => e.nameRu.trim()).toSet(),
    );
  }

  Set<ExEquipment> _allowedEquipment(String? location) => switch (location) {
    'gym' => ExEquipment.values.toSet(),
    'outdoor' || 'home' || _ => {ExEquipment.bodyweight, ExEquipment.none},
  };
}

/// Enforces that additions outside the app catalog remain exceptional.
/// Unknown names are retained (the product explicitly allows rare additions),
/// but more than 10% makes the response invalid and triggers the normal retry.
String validateWorkoutCatalogPreference(
  String validatedJson,
  Set<String> exactCatalogNames,
) {
  if (exactCatalogNames.isEmpty) return validatedJson;
  final data = jsonDecode(validatedJson) as Map<String, dynamic>;
  final known = exactCatalogNames.map((name) => name.toLowerCase()).toSet();
  final unknown = <String>[];
  var total = 0;

  for (final day in data['plan'] as List) {
    if (day is! Map<String, dynamic>) continue;
    for (final exercise in day['exercises'] as List? ?? const []) {
      if (exercise is! Map<String, dynamic>) continue;
      final name = (exercise['name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      total++;
      final exists = known.contains(name.toLowerCase());
      exercise['catalog_status'] = exists ? 'existing' : 'new';
      if (!exists) unknown.add(name);
    }
  }

  final allowedUnknown = total == 0 ? 0 : ((total + 9) ~/ 10).clamp(1, total);
  if (unknown.length > allowedUnknown) {
    throw AiException(
      AppLocalizations.tlp('aiCatalogMismatch', {
        'exercises': unknown.take(4).join(', '),
      }),
      statusCode: 422,
    );
  }
  return jsonEncode(data);
}
