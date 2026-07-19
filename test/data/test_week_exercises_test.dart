import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/data/test_week_exercises.dart';

void main() {
  group('testWeekDaysForLocation', () {
    test('always returns 4 days with the fixed muscle-group split', () {
      for (final location in [null, 'gym', 'outdoor', 'home']) {
        final days = testWeekDaysForLocation(location);
        expect(days.length, 4, reason: 'location=$location');
        expect(days.map((d) => d.length).toList(), [
          4,
          3,
          4,
          2,
        ], reason: 'location=$location');
      }
    });

    test('gym includes barbell/dumbbell exercises with weight', () {
      final days = testWeekDaysForLocation('gym');
      final all = days.expand((d) => d).toList();
      expect(all.any((e) => e.baseWeight > 0), isTrue);
    });

    test('outdoor uses only bodyweight exercises (no gym equipment)', () {
      final days = testWeekDaysForLocation('outdoor');
      final all = days.expand((d) => d).toList();
      expect(all.every((e) => e.baseWeight == 0), isTrue);
      expect(all.any((e) => e.name.contains('турник')), isTrue);
    });

    test('home uses only bodyweight/band exercises (no gym equipment)', () {
      final days = testWeekDaysForLocation('home');
      final all = days.expand((d) => d).toList();
      expect(all.every((e) => e.baseWeight == 0), isTrue);
      expect(all.any((e) => e.name.contains('эспандер')), isTrue);
    });

    test('unknown/null location defaults to safe home exercises', () {
      final unknown = testWeekDaysForLocation('spaceship');
      final home = testWeekDaysForLocation('home');
      expect(unknown, equals(home));
      expect(testWeekDaysForLocation(null), equals(home));
    });
  });
}
