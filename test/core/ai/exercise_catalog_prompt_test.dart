import 'dart:convert';

import 'package:fitnesbuster/core/ai/ai_exception.dart';
import 'package:fitnesbuster/core/ai/exercise_catalog_prompt.dart';
import 'package:fitnesbuster/data/models/exercise_db_model.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseDbModel _exercise({
  required String id,
  required String nameRu,
  required ExEquipment equipment,
  ExMuscle muscle = ExMuscle.pectoralisMajor,
}) => ExerciseDbModel(
  id: id,
  name: id,
  nameRu: nameRu,
  difficulty: ExDifficulty.beginner,
  equipment: [equipment],
  primaryMuscles: [muscle],
  secondaryMuscles: const [],
  instructions: const [],
  movementType: ExMovementType.push,
  tags: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExerciseCatalogPrompt', () {
    final exercises = [
      _exercise(
        id: 'push_up',
        nameRu: 'Отжимания',
        equipment: ExEquipment.bodyweight,
      ),
      _exercise(
        id: 'bench_press',
        nameRu: 'Жим штанги лёжа',
        equipment: ExEquipment.barbell,
      ),
    ];

    test('home and unknown locations never expose gym equipment', () {
      for (final location in ['home', 'outdoor', null]) {
        final context = ExerciseCatalogPrompt().buildFrom(exercises, location);
        expect(context.exactNames, contains('Отжимания'));
        expect(context.exactNames, isNot(contains('Жим штанги лёжа')));
      }
    });

    test('gym exposes both bodyweight and weighted exercises', () {
      final context = ExerciseCatalogPrompt().buildFrom(exercises, 'gym');
      expect(context.exactNames, containsAll(['Отжимания', 'Жим штанги лёжа']));
    });
  });

  group('validateWorkoutCatalogPreference', () {
    String plan(List<String> names) => jsonEncode({
      'plan': [
        {
          'day': 1,
          'exercises': names.map((name) => {'name': name}).toList(),
        },
      ],
    });

    test('marks a rare new exercise but allows one exception', () {
      final result =
          jsonDecode(
                validateWorkoutCatalogPreference(
                  plan(['Отжимания', 'Авторское безопасное упражнение']),
                  {'Отжимания'},
                ),
              )
              as Map<String, dynamic>;
      final items = (result['plan'] as List).first['exercises'] as List;
      expect(items.first['catalog_status'], 'existing');
      expect(items.last['catalog_status'], 'new');
    });

    test('rejects a plan dominated by exercises outside the app', () {
      expect(
        () => validateWorkoutCatalogPreference(plan(['Новое 1', 'Новое 2']), {
          'Отжимания',
        }),
        throwsA(isA<AiException>()),
      );
    });

    test(
      'production home catalog is loaded, compact and equipment-safe',
      () async {
        final context = await ExerciseCatalogPrompt().build('home');
        expect(context.exactNames, isNotEmpty);
        expect(context.exactNames.length, lessThanOrEqualTo(120));
        expect(context.promptBlock, isNot(contains('[barbell]')));
        expect(context.promptBlock, isNot(contains('[machine]')));
        expect(context.promptBlock, isNot(contains('[cables]')));
      },
    );
  });
}
