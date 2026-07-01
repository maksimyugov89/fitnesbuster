import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/test_day_exercise.dart';

/// Static list of test-week exercises distributed across 4 days.
/// Day 1: Chest + Triceps, Day 2: Back + Biceps,
/// Day 3: Shoulders + Legs, Day 4: Abs + Cardio.
const List<TestDayExercise> kTestWeekExercises = [
  TestDayExercise(
    name: 'Жим штанги лёжа',
    muscle: MuscleGroup.chest,
    baseWeight: 20,
  ),
  TestDayExercise(
    name: 'Разведение гантелей',
    muscle: MuscleGroup.chest,
    baseWeight: 8,
  ),
  TestDayExercise(
    name: 'Отжимания от пола',
    muscle: MuscleGroup.chest,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Французский жим',
    muscle: MuscleGroup.triceps,
    baseWeight: 10,
  ),
  TestDayExercise(
    name: 'Тяга гантели к поясу',
    muscle: MuscleGroup.back,
    baseWeight: 12,
  ),
  TestDayExercise(
    name: 'Подтягивания (или тяга)',
    muscle: MuscleGroup.back,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Сгибание рук с гантелями',
    muscle: MuscleGroup.biceps,
    baseWeight: 6,
  ),
  TestDayExercise(
    name: 'Жим гантелей сидя',
    muscle: MuscleGroup.shoulders,
    baseWeight: 8,
  ),
  TestDayExercise(
    name: 'Приседания с гантелями',
    muscle: MuscleGroup.quads,
    baseWeight: 12,
  ),
  TestDayExercise(name: 'Выпады', muscle: MuscleGroup.glutes, baseWeight: 8),
  TestDayExercise(
    name: 'Подъём на носки',
    muscle: MuscleGroup.calves,
    baseWeight: 10,
  ),
  TestDayExercise(name: 'Планка', muscle: MuscleGroup.abs, baseWeight: 0),
  TestDayExercise(name: 'Скручивания', muscle: MuscleGroup.abs, baseWeight: 0),
];

List<List<TestDayExercise>> get kTestWeekDays => [
  kTestWeekExercises.sublist(0, 4), // Day 1: Chest + Triceps
  kTestWeekExercises.sublist(4, 7), // Day 2: Back + Biceps
  kTestWeekExercises.sublist(7, 11), // Day 3: Shoulders + Legs
  kTestWeekExercises.sublist(11, 13), // Day 4: Abs + Cardio
];
