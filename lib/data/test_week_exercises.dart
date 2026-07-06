import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/test_day_exercise.dart';

/// Test-week exercises for GYM (barbell/dumbbells available), distributed
/// across 4 days. Day 1: Chest + Triceps, Day 2: Back + Biceps,
/// Day 3: Shoulders + Legs, Day 4: Abs + Cardio.
const List<TestDayExercise> _kGymExercises = [
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

/// Test-week exercises for OUTDOOR / стадион (турники, брусья, скамейки —
/// без штанг и тренажёров). Same 4-day muscle-group structure as gym.
const List<TestDayExercise> _kOutdoorExercises = [
  TestDayExercise(
    name: 'Отжимания от пола',
    muscle: MuscleGroup.chest,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Отжимания на брусьях',
    muscle: MuscleGroup.chest,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Отжимания узким хватом',
    muscle: MuscleGroup.triceps,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Отжимания с ногами на скамье',
    muscle: MuscleGroup.chest,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Подтягивания широким хватом',
    muscle: MuscleGroup.back,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Подтягивания обратным хватом',
    muscle: MuscleGroup.back,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Австралийские подтягивания',
    muscle: MuscleGroup.biceps,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Пайк-отжимания (стойка)',
    muscle: MuscleGroup.shoulders,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Приседания с прыжком',
    muscle: MuscleGroup.quads,
    baseWeight: 0,
  ),
  TestDayExercise(name: 'Выпады', muscle: MuscleGroup.glutes, baseWeight: 0),
  TestDayExercise(
    name: 'Зашагивания на скамью',
    muscle: MuscleGroup.calves,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Подъём ног в висе на турнике',
    muscle: MuscleGroup.abs,
    baseWeight: 0,
  ),
  TestDayExercise(name: 'Скручивания', muscle: MuscleGroup.abs, baseWeight: 0),
];

/// Test-week exercises for HOME (только собственный вес + опционально лёгкие
/// эспандеры). Same 4-day muscle-group structure as gym.
const List<TestDayExercise> _kHomeExercises = [
  TestDayExercise(
    name: 'Отжимания от пола',
    muscle: MuscleGroup.chest,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Отжимания широкой постановкой рук',
    muscle: MuscleGroup.chest,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Отжимания узкой постановкой рук',
    muscle: MuscleGroup.triceps,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Отжимания с ногами на стуле',
    muscle: MuscleGroup.chest,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Тяга эспандера к поясу',
    muscle: MuscleGroup.back,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Супермен (разгибание спины)',
    muscle: MuscleGroup.back,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Сгибание рук с эспандером',
    muscle: MuscleGroup.biceps,
    baseWeight: 0,
  ),
  TestDayExercise(
    name: 'Пайк-отжимания (плечи)',
    muscle: MuscleGroup.shoulders,
    baseWeight: 0,
  ),
  TestDayExercise(name: 'Приседания', muscle: MuscleGroup.quads, baseWeight: 0),
  TestDayExercise(name: 'Выпады', muscle: MuscleGroup.glutes, baseWeight: 0),
  TestDayExercise(
    name: 'Ягодичный мостик',
    muscle: MuscleGroup.calves,
    baseWeight: 0,
  ),
  TestDayExercise(name: 'Планка', muscle: MuscleGroup.abs, baseWeight: 0),
  TestDayExercise(name: 'Скручивания', muscle: MuscleGroup.abs, baseWeight: 0),
];

List<List<TestDayExercise>> _daysFrom(List<TestDayExercise> exercises) => [
  exercises.sublist(0, 4), // Day 1: Chest + Triceps
  exercises.sublist(4, 7), // Day 2: Back + Biceps
  exercises.sublist(7, 11), // Day 3: Shoulders + Legs
  exercises.sublist(11, 13), // Day 4: Abs + Cardio
];

/// Backward-compatible default (gym) — kept for callers that don't yet pass
/// a location.
List<List<TestDayExercise>> get kTestWeekDays => _daysFrom(_kGymExercises);

/// Тестовая неделя должна использовать только то оборудование, которое
/// реально доступно пользователю — иначе он не сможет протестировать вес,
/// которого физически нет (штанга дома, тренажёры на стадионе и т.д.).
List<List<TestDayExercise>> testWeekDaysForLocation(String? location) {
  switch (location) {
    case 'outdoor':
      return _daysFrom(_kOutdoorExercises);
    case 'home':
      return _daysFrom(_kHomeExercises);
    default:
      return _daysFrom(_kGymExercises);
  }
}
