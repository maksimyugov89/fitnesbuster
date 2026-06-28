/// Aggregated health data from Google Health Connect / Apple Health.
class SyncedHealthData {
  final int steps;
  final double caloriesBurned;
  final double totalCaloriesBurned;
  final int? heartRateAvg;
  final int? restingHeartRate;
  final double? heartRateVariability;
  final double? respiratoryRate;
  final double? weight;
  final double? height;
  final int? sleepMinutes;
  final double? distanceKm;
  final double? waterIntakeMl;
  final int workoutCount;
  final DateTime syncedAt;

  SyncedHealthData({
    this.steps = 0,
    this.caloriesBurned = 0,
    this.totalCaloriesBurned = 0,
    this.heartRateAvg,
    this.restingHeartRate,
    this.heartRateVariability,
    this.respiratoryRate,
    this.weight,
    this.height,
    this.sleepMinutes,
    this.distanceKm,
    this.waterIntakeMl,
    this.workoutCount = 0,
    DateTime? syncedAt,
  }) : syncedAt = syncedAt ?? DateTime.now();
}
