import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/core/services/recovery_score_service.dart';

void main() {
  // ── sleepScore ──────────────────────────────────────────────────

  group('_sleepScore', () {
    test('null returns neutral 65', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: null, hrv: null, restingHr: null);
      expect(r.score, closeTo(65, 1));
    });

    test('≥480 min (8h) returns high score', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 480, hrv: null, restingHr: null);
      expect(r.score, greaterThan(70));
    });

    test('≥420 min (7h) with good HRV/HR returns excellent', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 420, hrv: 60, restingHr: 55);
      expect(r.score, greaterThan(80));
      expect(r.level, RecoveryLevel.excellent);
    });

    test('≥360 min (6h) with no HRV/HR returns medium', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 360, hrv: null, restingHr: null);
      expect(r.score, lessThan(65));
    });

    test('≥300 min (5h) returns under 60', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 300, hrv: null, restingHr: null);
      expect(r.score, lessThan(60));
    });

    test('<300 min returns very low', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 180, hrv: null, restingHr: null);
      expect(r.level, RecoveryLevel.low);
    });

    test('score uses weighted average: 0.40 sleep + 0.35 HRV + 0.25 HR', () {
      final optimal = RecoveryScoreService.calculate(sleepMinutes: 480, hrv: 60, restingHr: 55);
      final poor = RecoveryScoreService.calculate(sleepMinutes: 200, hrv: 10, restingHr: 90);
      expect(optimal.score, greaterThan(poor.score));
    });
  });

  // ── calculate + recovery levels ─────────────────────────────────

  group('calculate', () {
    test('excellent recovery with optimal data', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 500, hrv: 65, restingHr: 50);
      expect(r.level, RecoveryLevel.excellent);
      expect(r.score, greaterThanOrEqualTo(80));
      expect(r.shouldReduceIntensity, isFalse);
    });

    test('good recovery with decent data', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 400, hrv: 40, restingHr: 68);
      expect(r.level, RecoveryLevel.good);
      expect(r.score, greaterThanOrEqualTo(65));
      expect(r.score, lessThan(80));
    });

    test('fair recovery with mixed data', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 360, hrv: 30, restingHr: 72);
      expect(r.level, RecoveryLevel.fair);
      expect(r.shouldReduceIntensity, isTrue);
    });

    test('low recovery with poor data', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 280, hrv: 14, restingHr: 88);
      expect(r.level, RecoveryLevel.low);
      expect(r.shouldReduceIntensity, isTrue);
    });

    test('neutral when all data is null', () {
      final r = RecoveryScoreService.calculate();
      expect(r.score, closeTo(65, 5));
      expect(r.level, anyOf(RecoveryLevel.good, RecoveryLevel.fair));
    });

    test('restingHr null returns neutral 65 for HR', () {
      final r = RecoveryScoreService.calculate(sleepMinutes: 500, hrv: 60, restingHr: null);
      expect(r.score, closeTo(93, 5));
    });
  });

  // ── RecoveryScore properties ────────────────────────────────────

  group('RecoveryScore properties', () {
    test('color returns correct colors per level', () {
      final excellent = RecoveryScoreService.calculate(sleepMinutes: 500, hrv: 65, restingHr: 50).color;
      final good = RecoveryScoreService.calculate(sleepMinutes: 420, hrv: 45, restingHr: 62).color;
      final fair = RecoveryScoreService.calculate(sleepMinutes: 360, hrv: 30, restingHr: 72).color;
      final low = RecoveryScoreService.calculate(sleepMinutes: 280, hrv: 14, restingHr: 88).color;
      expect(excellent, isNotNull);
      expect(good, isNotNull);
      expect(fair, isNotNull);
      expect(low, isNotNull);
    });

    test('shouldReduceIntensity is true for fair and low', () {
      final fair = RecoveryScoreService.calculate(sleepMinutes: 360, hrv: 30, restingHr: 72);
      expect(fair.shouldReduceIntensity, isTrue);

      final low = RecoveryScoreService.calculate(sleepMinutes: 280, hrv: 14, restingHr: 88);
      expect(low.shouldReduceIntensity, isTrue);
    });
  });

  // ── formatSleep ─────────────────────────────────────────────────

  group('formatSleep', () {
    test('null returns —', () {
      expect(RecoveryScoreService.formatSleep(null), '—');
    });

    test('480 min returns 8ч', () {
      expect(RecoveryScoreService.formatSleep(480), contains('8'));
    });

    test('450 min returns 7ч 30м', () {
      final formatted = RecoveryScoreService.formatSleep(450);
      expect(formatted, anyOf(contains('7'), contains('30')));
    });
  });
}
