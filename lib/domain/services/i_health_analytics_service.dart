import 'package:health/health.dart';

abstract interface class IHealthAnalyticsService {
  int sumSleepMinutes(List<HealthDataPoint> data);
  double? sumValue(List<HealthDataPoint> data, HealthDataType type);
  double? avgValue(List<HealthDataPoint> data, HealthDataType type);
  double? lastValue(List<HealthDataPoint> data, HealthDataType type);
}
