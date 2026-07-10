import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutExercise', () {
    test('isTimedReps detects seconds pattern', () {
      const ex1 = WorkoutExercise(
        name: 'Plank',
        sets: 3,
        reps: '30 сек',
        restSeconds: 30,
      );
      const ex2 = WorkoutExercise(
        name: 'Hold',
        sets: 2,
        reps: '60 sec',
        restSeconds: 45,
      );
      const ex3 = WorkoutExercise(
        name: 'Bike',
        sets: 1,
        reps: '5 мин',
        restSeconds: 60,
      );
      const ex4 = WorkoutExercise(
        name: 'Squat',
        sets: 4,
        reps: '10',
        restSeconds: 60,
      );

      expect(ex1.isTimedReps, isTrue);
      expect(ex2.isTimedReps, isTrue);
      expect(ex3.isTimedReps, isTrue);
      expect(ex4.isTimedReps, isFalse);
    });

    test('durationSeconds extracts and converts timed exercises', () {
      const exSec = WorkoutExercise(
        name: 'A',
        sets: 3,
        reps: '45 сек',
        restSeconds: 20,
      );
      const exMin = WorkoutExercise(
        name: 'B',
        sets: 1,
        reps: '2 мин',
        restSeconds: 30,
      );
      // Untimed exercise: returns the rep number (not a default)
      const exUntimed = WorkoutExercise(
        name: 'C',
        sets: 3,
        reps: '12',
        restSeconds: 60,
      );
      // Timed exercise without explicit seconds: defaults to 30s minimum
      const exTimedDefault = WorkoutExercise(
        name: 'D',
        sets: 2,
        reps: 'сек',
        restSeconds: 15,
      );

      expect(exSec.durationSeconds, 45);
      expect(exMin.durationSeconds, 120);
      expect(exUntimed.durationSeconds, 12);
      expect(exTimedDefault.durationSeconds, 30);
    });

    test('fromJson parses all fields', () {
      final ex = WorkoutExercise.fromJson({
        'name': 'Bench Press',
        'sets': 4,
        'reps': '10',
        'rest_seconds': 60,
        'muscle_primary': 'chest',
        'rpe': 8,
        'tempo': '3-1-3',
        'technique_cue': 'elbows tucked',
      });
      expect(ex.name, 'Bench Press');
      expect(ex.sets, 4);
      expect(ex.reps, '10');
      expect(ex.restSeconds, 60);
      expect(ex.musclePrimary, 'chest');
      expect(ex.rpe, 8);
      expect(ex.tempo, '3-1-3');
      expect(ex.techniqueCue, 'elbows tucked');
    });

    test('fromJson falls back to muscle_group for primary', () {
      final ex = WorkoutExercise.fromJson({
        'name': 'Row',
        'sets': 3,
        'reps': '12',
        'rest_seconds': 45,
        'muscle_group': 'back',
      });
      expect(ex.musclePrimary, 'back');
    });
  });

  group('WorkoutDay', () {
    test('totalSets sums all exercise sets', () {
      const day = WorkoutDay(
        day: 1,
        focus: 'Chest',
        exercises: [
          WorkoutExercise(name: 'A', sets: 3, reps: '10', restSeconds: 60),
          WorkoutExercise(name: 'B', sets: 4, reps: '12', restSeconds: 45),
          WorkoutExercise(name: 'C', sets: 2, reps: '15', restSeconds: 30),
        ],
      );
      expect(day.totalSets, 9);
    });

    test('totalSets returns 0 for empty exercises', () {
      const day = WorkoutDay(day: 1, focus: 'Rest', exercises: []);
      expect(day.totalSets, 0);
    });

    test('fromJson parses workout day', () {
      final day = WorkoutDay.fromJson({
        'day': 3,
        'focus': 'Leg Day',
        'exercises': [
          {'name': 'Squat', 'sets': 4, 'reps': '10', 'rest_seconds': 90},
        ],
        'cardio_minutes': 15,
        'notes': 'go heavy',
        'duration_minutes': 45,
        'estimated_calories_burned': 350,
      });
      expect(day.day, 3);
      expect(day.focus, 'Leg Day');
      expect(day.exercises.length, 1);
      expect(day.exercises[0].name, 'Squat');
      expect(day.cardioMinutes, 15);
      expect(day.notes, 'go heavy');
      expect(day.durationMinutes, 45);
      expect(day.estimatedCaloriesBurned, 350);
    });

    test('fromJson handles missing exercises gracefully', () {
      final day = WorkoutDay.fromJson({
        'day': 2,
        'focus': 'Rest',
        'exercises': null,
      });
      expect(day.exercises, isEmpty);
    });

    test('todayFromPlanJson returns first day when no weekday match', () {
      final plan = WorkoutDay.todayFromPlanJson('''
        {"plan": [
          {"day": 2, "focus": "Back", "exercises": []}
        ]}
      ''');
      expect(plan, isNotNull);
      expect(plan!.focus, 'Back');
    });

    test('todayFromPlanJson returns null for empty/missing plan', () {
      expect(WorkoutDay.todayFromPlanJson(''), isNull);
      expect(WorkoutDay.todayFromPlanJson('{}'), isNull);
      expect(WorkoutDay.todayFromPlanJson('{"plan": []}'), isNull);
    });
  });
}
