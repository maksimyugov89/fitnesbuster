import 'package:fitnesbuster/domain/entities/entities.dart';

/// Persisted progress for the seven-day fitness assessment.
///
/// The four assessment workouts are scheduled on days 1, 3, 5 and 7. Draft
/// results are persisted as well, so leaving the screen never discards work.
class TestWeekProgress {
  static const scheduleDayOffsets = <int>[0, 2, 4, 6];

  final DateTime startedAt;
  final String workoutLocation;
  final List<TestWeekCompletedDay> completedDays;
  final int? draftDayIndex;
  final List<TestExerciseResult> draftExercises;
  final DateTime? updatedAt;

  const TestWeekProgress({
    required this.startedAt,
    required this.workoutLocation,
    this.completedDays = const [],
    this.draftDayIndex,
    this.draftExercises = const [],
    this.updatedAt,
  });

  int get nextDayIndex => completedDays.length;

  List<TestExerciseResult> get allCompletedExercises =>
      completedDays.expand((day) => day.exercises).toList(growable: false);

  int get averageRpe {
    if (completedDays.isEmpty) return 5;
    final total = completedDays.fold<int>(0, (sum, day) => sum + day.rpe);
    return (total / completedDays.length).round().clamp(1, 10);
  }

  DateTime availableAtForDay(int dayIndex) {
    final safeIndex = dayIndex.clamp(0, scheduleDayOffsets.length - 1);
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    return start.add(Duration(days: scheduleDayOffsets[safeIndex]));
  }

  bool isDayAvailable(int dayIndex, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(availableAtForDay(dayIndex));
  }

  TestWeekProgress copyWith({
    List<TestWeekCompletedDay>? completedDays,
    int? draftDayIndex,
    bool clearDraftDayIndex = false,
    List<TestExerciseResult>? draftExercises,
    DateTime? updatedAt,
  }) => TestWeekProgress(
    startedAt: startedAt,
    workoutLocation: workoutLocation,
    completedDays: completedDays ?? this.completedDays,
    draftDayIndex: clearDraftDayIndex
        ? null
        : (draftDayIndex ?? this.draftDayIndex),
    draftExercises: draftExercises ?? this.draftExercises,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'startedAt': startedAt.toIso8601String(),
    'workoutLocation': workoutLocation,
    'completedDays': completedDays.map((day) => day.toJson()).toList(),
    if (draftDayIndex != null) 'draftDayIndex': draftDayIndex,
    'draftExercises': draftExercises.map((e) => e.toJson()).toList(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory TestWeekProgress.fromJson(Map<String, dynamic> json) =>
      TestWeekProgress(
        startedAt: DateTime.parse(json['startedAt'] as String),
        workoutLocation: json['workoutLocation'] as String? ?? 'home',
        completedDays: (json['completedDays'] as List? ?? const [])
            .map(
              (item) => TestWeekCompletedDay.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        draftDayIndex: (json['draftDayIndex'] as num?)?.toInt(),
        draftExercises: (json['draftExercises'] as List? ?? const [])
            .map(
              (item) => TestExerciseResult.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}

class TestWeekCompletedDay {
  final int dayIndex;
  final DateTime completedAt;
  final int rpe;
  final List<TestExerciseResult> exercises;

  const TestWeekCompletedDay({
    required this.dayIndex,
    required this.completedAt,
    required this.rpe,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'dayIndex': dayIndex,
    'completedAt': completedAt.toIso8601String(),
    'rpe': rpe,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory TestWeekCompletedDay.fromJson(Map<String, dynamic> json) =>
      TestWeekCompletedDay(
        dayIndex: (json['dayIndex'] as num).toInt(),
        completedAt: DateTime.parse(json['completedAt'] as String),
        rpe: ((json['rpe'] as num?)?.toInt() ?? 5).clamp(1, 10),
        exercises: (json['exercises'] as List? ?? const [])
            .map(
              (item) => TestExerciseResult.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );
}
