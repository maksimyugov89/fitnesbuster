import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fitnesbuster/domain/entities/entities.dart' show MuscleGroup;

part 'test_day_exercise.freezed.dart';
part 'test_day_exercise.g.dart';

@freezed
class TestDayExercise with _$TestDayExercise {
  const factory TestDayExercise({
    required String name,
    required MuscleGroup muscle,
    required double baseWeight,
  }) = _TestDayExercise;

  factory TestDayExercise.fromJson(Map<String, dynamic> json) =>
      _$TestDayExerciseFromJson(json);
}
