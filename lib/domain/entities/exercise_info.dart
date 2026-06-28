import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_info.freezed.dart';
part 'exercise_info.g.dart';

@freezed
class ExerciseInfo with _$ExerciseInfo {
  const factory ExerciseInfo({
    required String id,
    required String name,
    String? muscleGroup,
    String? gifUrl,
  }) = _ExerciseInfo;

  factory ExerciseInfo.fromJson(Map<String, dynamic> json) => _$ExerciseInfoFromJson(json);
}
