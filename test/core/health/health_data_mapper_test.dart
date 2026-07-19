import 'package:fitnesbuster/core/health/health_data_mapper.dart';
import 'package:fitnesbuster/domain/entities/synced_health_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('healthDataFromSynced maps positive metrics to AI DTO', () {
    final result = healthDataFromSynced(
      SyncedHealthData(
        steps: 1200,
        caloriesBurned: 320,
        heartRateAvg: 72,
        restingHeartRate: 58,
        heartRateVariability: 45,
        weight: 80.5,
        sleepMinutes: 430,
        waterIntakeMl: 1500,
        distanceKm: 4.2,
      ),
    );

    expect(result.userId, 'ephemeral');
    expect(result.steps, 1200);
    expect(result.caloriesBurned, 320);
    expect(result.heartRateAvg, 72);
    expect(result.heartRateResting, 58);
    expect(result.heartRateVariability, 45);
    expect(result.weight, 80.5);
    expect(result.sleepMinutes, 430);
    expect(result.waterIntakeMl, 1500);
    expect(result.distanceKm, 4.2);
  });

  test('healthDataFromSynced omits zero-only metrics', () {
    final result = healthDataFromSynced(SyncedHealthData());

    expect(result.steps, isNull);
    expect(result.caloriesBurned, isNull);
  });
}
