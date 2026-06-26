class HealthData {
  final String userId;
  final DateTime date;
  final int? steps;
  final double? caloriesBurned;
  final int? heartRateAvg;
  final int? heartRateResting;
  final double? weight;
  final double? bodyFatPercent;
  final int? sleepMinutes;
  final double? waterIntakeMl;
  final double? distanceKm;

  const HealthData({
    required this.userId,
    required this.date,
    this.steps,
    this.caloriesBurned,
    this.heartRateAvg,
    this.heartRateResting,
    this.weight,
    this.bodyFatPercent,
    this.sleepMinutes,
    this.waterIntakeMl,
    this.distanceKm,
  });
}

class ProgressEntry {
  final String id;
  final String userId;
  final DateTime date;
  final double? weight;
  final double? bodyFatPercent;
  final Map<String, double>? measurements;
  final String? photoUrl;
  final String? notes;

  const ProgressEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.bodyFatPercent,
    this.measurements,
    this.photoUrl,
    this.notes,
  });
}
