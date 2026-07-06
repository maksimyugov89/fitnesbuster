import 'package:fitnesbuster/domain/entities/health_entities.dart';
import 'package:fitnesbuster/domain/entities/synced_health_data.dart';

/// Преобразует показания с устройства (Apple Health / Health Connect) в
/// `HealthData`, которую понимают AI-промпты (`recentHealth`). `HealthData`
/// нигде не персистится — это одноразовый DTO для конкретного вызова AI.
HealthData healthDataFromSynced(SyncedHealthData synced) => HealthData(
  userId: 'ephemeral',
  date: DateTime.now(),
  steps: synced.steps > 0 ? synced.steps : null,
  caloriesBurned: synced.caloriesBurned > 0 ? synced.caloriesBurned : null,
  heartRateAvg: synced.heartRateAvg,
  heartRateResting: synced.restingHeartRate,
  heartRateVariability: synced.heartRateVariability,
  weight: synced.weight,
  sleepMinutes: synced.sleepMinutes,
  waterIntakeMl: synced.waterIntakeMl,
  distanceKm: synced.distanceKm,
);
