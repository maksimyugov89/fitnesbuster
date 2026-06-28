import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/data/models/weekly_debrief.dart';

void main() {
  group('WeeklyDebrief', () {
    test('fromJson parses all fields', () {
      final d = WeeklyDebrief.fromJson({
        'overall_score': 8,
        'workout_adherence': 90,
        'workout_summary': 'Great week',
        'nutrition_summary': 'Clean eating',
        'highlights': ['5 workouts', 'PR'],
        'improvements': ['More water'],
        'next_week_focus': 'Add cardio',
        'recovery_tips': ['Sleep 8h', 'Stretch'],
        'generated_at': '2024-01-15T12:00:00.000Z',
      });
      expect(d.overallScore, 8);
      expect(d.workoutAdherence, 90);
      expect(d.highlights.length, 2);
      expect(d.generatedAt.year, 2024);
    });

    test('fromJson handles missing fields with defaults', () {
      final d = WeeklyDebrief.fromJson({});
      expect(d.overallScore, 5);
      expect(d.workoutAdherence, 0);
      expect(d.highlights, isEmpty);
    });

    test('toJson round-trips correctly', () {
      final d = WeeklyDebrief(
        overallScore: 7,
        workoutAdherence: 80,
        workoutSummary: 'Good',
        nutritionSummary: 'OK',
        highlights: ['PR'],
        improvements: [],
        nextWeekFocus: 'Legs',
        recoveryTips: ['Sleep'],
        generatedAt: DateTime(2024, 1, 15),
      );
      final j = d.toJson();
      expect(j['overall_score'], 7);
      expect(j['highlights'], ['PR']);
      final restored = WeeklyDebrief.fromJson(j);
      expect(restored.overallScore, 7);
      expect(restored.workoutSummary, 'Good');
    });
  });
}
