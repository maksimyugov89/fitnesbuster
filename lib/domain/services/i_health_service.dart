import 'package:health/health.dart';

export 'package:health/health.dart' show HealthDataType, HealthDataPoint;

abstract interface class IHealthService {
  Future<bool> requestAuthorization(List<HealthDataType> types);
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required DateTime startTime,
    required DateTime endTime,
    required List<HealthDataType> types,
  });
}
