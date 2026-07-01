import 'package:health/health.dart';
import 'package:fitnesbuster/domain/services/i_health_service.dart';

class HealthServiceAdapter implements IHealthService {
  final Health _health;

  HealthServiceAdapter({Health? health}) : _health = health ?? Health();

  @override
  Future<bool> requestAuthorization(List<HealthDataType> types) =>
      _health.requestAuthorization(types);

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required DateTime startTime,
    required DateTime endTime,
    required List<HealthDataType> types,
  }) => _health.getHealthDataFromTypes(
    startTime: startTime,
    endTime: endTime,
    types: types,
  );
}
