import 'package:health/health.dart';
import 'package:fitnesbuster/domain/services/i_health_analytics_service.dart';

class HealthAnalyticsService implements IHealthAnalyticsService {
  @override
  int sumSleepMinutes(List<HealthDataPoint> data) {
    return data
        .where((p) => p.type == HealthDataType.SLEEP_SESSION)
        .fold(0, (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes);
  }

  @override
  double? sumValue(List<HealthDataPoint> data, HealthDataType type) {
    final filtered = data.where((p) => p.type == type);
    if (filtered.isEmpty) return null;
    return filtered.fold<double>(0, (sum, p) {
      final v = double.tryParse(p.value.toString());
      return sum + (v ?? 0);
    });
  }

  @override
  double? avgValue(List<HealthDataPoint> data, HealthDataType type) {
    final filtered = data.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    final sum = filtered.fold<double>(0, (s, p) {
      final v = double.tryParse(p.value.toString());
      return s + (v ?? 0);
    });
    return sum / filtered.length;
  }

  @override
  double? lastValue(List<HealthDataPoint> data, HealthDataType type) {
    final filtered = data.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    return double.tryParse(filtered.last.value.toString());
  }
}
