import 'package:fitnesbuster/domain/entities/synced_health_data.dart';

abstract interface class IHealthConnectService {
  bool get isAvailable;
  Future<bool> isHealthConnectAvailable();
  Future<bool> initialize();
  Future<SyncedHealthData> readAllToday();
  Future<SyncedHealthData> readDateRange({required DateTime start, required DateTime end});
  void dispose();
}
