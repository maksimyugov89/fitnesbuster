import 'dart:convert';
import 'package:flutter/services.dart';

class ExerciseLocalization {
  static ExerciseLocalization? _instance;
  static ExerciseLocalization get instance =>
      _instance ??= ExerciseLocalization._();
  ExerciseLocalization._();

  Map<String, String>? _names;

  Future<void> init() async {
    if (_names != null) return;
    final raw = await rootBundle.loadString(
      'assets/data/exercise_ru_names.json',
    );
    _names = (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    );
  }

  String? translate(String englishName) => _names?[englishName];

  Map<String, String> get all => _names ?? const {};
}
