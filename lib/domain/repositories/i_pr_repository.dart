import 'package:fitnesbuster/data/models/personal_record.dart';

abstract interface class IPrRepository {
  Future<List<PersonalRecord>> getAll();
  Future<void> save(PersonalRecord record);
  Future<PersonalRecord> add({
    required String exerciseName,
    double? weightKg,
    int? reps,
    int? sets,
    DateTime? date,
    String notes,
  });
  Future<void> delete(String id);
  Future<List<PersonalRecord>> getForExercise(String exerciseName);
  PersonalRecord? getBest(List<PersonalRecord> records);
  Map<String, List<PersonalRecord>> groupByExercise(List<PersonalRecord> records);
}
