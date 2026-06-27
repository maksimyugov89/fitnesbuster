import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/entities/entities.dart' show MuscleGroup;

class TestDayExercise extends Equatable {
  final String name;
  final MuscleGroup muscle;
  final double baseWeight;
  const TestDayExercise({
    required this.name,
    required this.muscle,
    required this.baseWeight,
  });

  @override
  List<Object?> get props => [name, muscle, baseWeight];
}
