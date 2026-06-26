import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnesbuster/data/models/personal_record.dart';
import 'package:fitnesbuster/domain/repositories/i_pr_repository.dart';
import 'package:uuid/uuid.dart';

class PrRepository implements IPrRepository {
  static const _key = 'pr_records_v1';
  static const _uuid = Uuid();

  @override
  Future<List<PersonalRecord>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return PersonalRecord.decodeList(raw);
  }

  @override
  Future<void> save(PersonalRecord record) async {
    final all = await getAll();
    final idx = all.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      all[idx] = record;
    } else {
      all.add(record);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, PersonalRecord.encodeList(all));
  }

  @override
  Future<PersonalRecord> add({
    required String exerciseName,
    double? weightKg,
    int? reps,
    int? sets,
    DateTime? date,
    String notes = '',
  }) async {
    final record = PersonalRecord(
      id: _uuid.v4(),
      exerciseName: exerciseName.trim(),
      weightKg: weightKg,
      reps: reps,
      sets: sets,
      date: date ?? DateTime.now(),
      notes: notes,
    );
    await save(record);
    return record;
  }

  @override
  Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, PersonalRecord.encodeList(all));
  }

  // Returns records sorted newest first
  @override
  Future<List<PersonalRecord>> getForExercise(String exerciseName) async {
    final all = await getAll();
    return all
        .where((r) => r.exerciseName.toLowerCase() == exerciseName.toLowerCase())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Best record = highest score (weight × reps)
  @override
  PersonalRecord? getBest(List<PersonalRecord> records) {
    if (records.isEmpty) return null;
    return records.reduce((best, r) => r.score > best.score ? r : best);
  }

  // Returns map: exerciseName → sorted records (newest first)
  @override
  Map<String, List<PersonalRecord>> groupByExercise(List<PersonalRecord> records) {
    final map = <String, List<PersonalRecord>>{};
    for (final r in records) {
      (map[r.exerciseName] ??= []).add(r);
    }
    for (final key in map.keys) {
      map[key]!.sort((a, b) => b.date.compareTo(a.date));
    }
    return map;
  }
}
