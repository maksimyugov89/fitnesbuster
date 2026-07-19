import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:health/health.dart' as hc;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 7, 11, 8);
  final end = DateTime(2026, 7, 11, 9);

  test('does not trust a false-positive authorization callback', () async {
    final source = _FakeHealthSource(requestResult: true);
    final service = HealthConnectService(source: source, isAndroid: true);

    expect(await service.initialize(), isFalse);
    expect(source.requestCount, 1);
  });

  test(
    'reads granted metrics when an optional permission is missing',
    () async {
      final source = _FakeHealthSource(
        permissions: {
          hc.HealthDataType.STEPS,
          hc.HealthDataType.ACTIVE_ENERGY_BURNED,
        },
        steps: 6543,
        points: {
          hc.HealthDataType.ACTIVE_ENERGY_BURNED: [
            _point(hc.HealthDataType.ACTIVE_ENERGY_BURNED, 420, start, end),
          ],
        },
      );
      final service = HealthConnectService(source: source, isAndroid: true);

      expect(await service.initialize(), isTrue);
      final data = await service.readAllToday();

      expect(data.steps, 6543);
      expect(data.caloriesBurned, 420);
      expect(data.heartRateVariability, isNull);
      expect(
        source.readTypes,
        contains(hc.HealthDataType.ACTIVE_ENERGY_BURNED),
      );
      expect(
        source.readTypes,
        isNot(contains(hc.HealthDataType.HEART_RATE_VARIABILITY_RMSSD)),
      );
    },
  );

  test('one failed metric does not erase successful metrics', () async {
    final source = _FakeHealthSource(
      permissions: {
        hc.HealthDataType.ACTIVE_ENERGY_BURNED,
        hc.HealthDataType.WATER,
      },
      points: {
        hc.HealthDataType.ACTIVE_ENERGY_BURNED: [
          _point(hc.HealthDataType.ACTIVE_ENERGY_BURNED, 300, start, end),
        ],
      },
      failingTypes: {hc.HealthDataType.WATER},
    );
    final service = HealthConnectService(source: source, isAndroid: true);

    expect(await service.initialize(), isTrue);
    final data = await service.readAllToday();

    expect(data.caloriesBurned, 300);
    expect(data.waterIntakeMl, isNull);
  });

  test('converts Android Health Connect units and preserves vitals', () async {
    final permissions = {
      hc.HealthDataType.TOTAL_CALORIES_BURNED,
      hc.HealthDataType.HEART_RATE,
      hc.HealthDataType.RESTING_HEART_RATE,
      hc.HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      hc.HealthDataType.RESPIRATORY_RATE,
      hc.HealthDataType.WEIGHT,
      hc.HealthDataType.HEIGHT,
      hc.HealthDataType.DISTANCE_DELTA,
      hc.HealthDataType.SLEEP_SESSION,
      hc.HealthDataType.WATER,
      hc.HealthDataType.WORKOUT,
    };
    final source = _FakeHealthSource(
      permissions: permissions,
      points: {
        hc.HealthDataType.TOTAL_CALORIES_BURNED: [
          _point(hc.HealthDataType.TOTAL_CALORIES_BURNED, 2100, start, end),
        ],
        hc.HealthDataType.HEART_RATE: [
          _point(hc.HealthDataType.HEART_RATE, 70, start, end),
          _point(hc.HealthDataType.HEART_RATE, 74, start, end),
        ],
        hc.HealthDataType.RESTING_HEART_RATE: [
          _point(hc.HealthDataType.RESTING_HEART_RATE, 58, start, end),
        ],
        hc.HealthDataType.HEART_RATE_VARIABILITY_RMSSD: [
          _point(
            hc.HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
            45,
            start,
            end,
          ),
        ],
        hc.HealthDataType.RESPIRATORY_RATE: [
          _point(hc.HealthDataType.RESPIRATORY_RATE, 16, start, end),
        ],
        hc.HealthDataType.WEIGHT: [
          _point(hc.HealthDataType.WEIGHT, 78.5, start, end),
        ],
        hc.HealthDataType.HEIGHT: [
          _point(hc.HealthDataType.HEIGHT, 1.78, start, end),
        ],
        hc.HealthDataType.DISTANCE_DELTA: [
          _point(hc.HealthDataType.DISTANCE_DELTA, 5200, start, end),
        ],
        hc.HealthDataType.SLEEP_SESSION: [
          _point(
            hc.HealthDataType.SLEEP_SESSION,
            1,
            start,
            start.add(const Duration(minutes: 450)),
          ),
        ],
        hc.HealthDataType.WATER: [
          _point(hc.HealthDataType.WATER, 1.5, start, end),
        ],
        hc.HealthDataType.WORKOUT: [
          _point(hc.HealthDataType.WORKOUT, 1, start, end),
        ],
      },
    );
    final service = HealthConnectService(source: source, isAndroid: true);

    expect(await service.initialize(), isTrue);
    final data = await service.readDateRange(start: start, end: end);

    expect(data.totalCaloriesBurned, 2100);
    expect(data.heartRateAvg, 72);
    expect(data.restingHeartRate, 58);
    expect(data.heartRateVariability, 45);
    expect(data.respiratoryRate, 16);
    expect(data.weight, 78.5);
    expect(data.height, 1.78);
    expect(data.distanceKm, 5.2);
    expect(data.waterIntakeMl, 1500);
    expect(data.sleepMinutes, 450);
    expect(data.workoutCount, 1);
  });
}

hc.HealthDataPoint _point(
  hc.HealthDataType type,
  num value,
  DateTime from,
  DateTime to,
) {
  return hc.HealthDataPoint(
    uuid: '${type.name}-${from.microsecondsSinceEpoch}',
    value: hc.NumericHealthValue(numericValue: value),
    type: type,
    unit: hc.dataTypeToUnit[type] ?? hc.HealthDataUnit.COUNT,
    dateFrom: from,
    dateTo: to,
    sourcePlatform: hc.HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'test-device',
    sourceId: 'toolbox',
    sourceName: 'Health Connect Toolbox',
  );
}

class _FakeHealthSource implements HealthPlatformDataSource {
  _FakeHealthSource({
    this.requestResult = false,
    Set<hc.HealthDataType>? permissions,
    Map<hc.HealthDataType, List<hc.HealthDataPoint>>? points,
    Set<hc.HealthDataType>? failingTypes,
    this.steps,
  }) : permissions = permissions ?? {},
       points = points ?? {},
       failingTypes = failingTypes ?? {};

  final bool requestResult;
  final Set<hc.HealthDataType> permissions;
  final Map<hc.HealthDataType, List<hc.HealthDataPoint>> points;
  final Set<hc.HealthDataType> failingTypes;
  final int? steps;
  int requestCount = 0;
  final List<hc.HealthDataType> readTypes = [];

  @override
  Future<List<hc.HealthDataPoint>> getHealthDataFromTypes({
    required DateTime startTime,
    required DateTime endTime,
    required List<hc.HealthDataType> types,
  }) async {
    final type = types.single;
    readTypes.add(type);
    if (failingTypes.contains(type)) throw StateError('unsupported $type');
    return points[type] ?? const [];
  }

  @override
  Future<int?> getTotalStepsInInterval(DateTime start, DateTime end) async =>
      steps;

  @override
  Future<bool?> hasPermissions(List<hc.HealthDataType> types) async =>
      types.every(permissions.contains);

  @override
  Future<bool> isHealthConnectAvailable() async => true;

  @override
  Future<bool> requestAuthorization(List<hc.HealthDataType> types) async {
    requestCount++;
    return requestResult;
  }
}
