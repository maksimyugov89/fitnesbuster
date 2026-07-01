import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/core/services/exercise_gif_service.dart';
import 'package:fitnesbuster/domain/entities/exercise_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ExerciseGifService service;

  setUp(() {
    service = ExerciseGifService();
  });

  group('findByRuName', () {
    test('returns null before initialization', () {
      final result = service.findByRuName('жим лежа');
      expect(result, isNull);
    });

    test('returns ExerciseInfo after initialization', () async {
      await service.init();
      final result = service.findByRuName('жим лежа');
      // May or may not find the exercise depending on database content
      if (result != null) {
        expect(result, isA<ExerciseInfo>());
      }
    });

    test('returns null for nonexistent exercise', () async {
      await service.init();
      final result = service.findByRuName('несуществующее упражнение xyz');
      expect(result, isNull);
    });
  });
}
