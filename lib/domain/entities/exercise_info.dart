/// Domain-level exercise metadata — decoupled from data-layer model.
class ExerciseInfo {
  final String id;
  final String name;
  final String? muscleGroup;
  final String? gifUrl;

  const ExerciseInfo({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.gifUrl,
  });
}
