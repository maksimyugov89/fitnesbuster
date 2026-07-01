import 'package:health/health.dart' as hc;
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/domain/entities/synced_health_data.dart';

export 'package:fitnesbuster/domain/entities/synced_health_data.dart';

/// Reads health data from Google Health Connect (Android) or Apple Health (iOS).
class HealthConnectService implements IHealthConnectService {
  final hc.Health _health;
  bool _initialized = false;
  bool _available = false;

  HealthConnectService() : _health = hc.Health();

  @override
  bool get isAvailable => _available;

  static const _types = [
    hc.HealthDataType.STEPS,
    hc.HealthDataType.ACTIVE_ENERGY_BURNED,
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
  ];

  @override
  Future<bool> isHealthConnectAvailable() async {
    try {
      return await _health.isHealthConnectAvailable();
    } catch (e, st) {
      appLogger.w(
        'HealthConnect: isAvailable check failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  Future<bool> initialize() async {
    if (_initialized && _available) return true;

    try {
      final installed = await isHealthConnectAvailable();
      if (!installed) {
        _available = false;
        _initialized = true;
        return false;
      }

      final granted = await _health.requestAuthorization(_types);

      _available = granted;
      _initialized = true;
      return true;
    } catch (e, st) {
      appLogger.w('HealthConnect: initialize failed', error: e, stackTrace: st);
      _available = false;
      _initialized = true;
      return false;
    }
  }

  @override
  Future<SyncedHealthData> readAllToday() async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return SyncedHealthData();
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Читаем активность за сегодня
    final activity = await _readRange(start: todayStart, end: todayEnd);

    // Сон читаем с вечера предыдущего дня (18 ч назад), чтобы захватить ночной сеанс
    if (activity.sleepMinutes == null) {
      final sleepStart = todayStart.subtract(const Duration(hours: 18));
      final sleepMins = await _readSleepMinutes(
        start: sleepStart,
        end: todayEnd,
      );
      if (sleepMins > 0) {
        return SyncedHealthData(
          steps: activity.steps,
          caloriesBurned: activity.caloriesBurned,
          totalCaloriesBurned: activity.totalCaloriesBurned,
          heartRateAvg: activity.heartRateAvg,
          restingHeartRate: activity.restingHeartRate,
          heartRateVariability: activity.heartRateVariability,
          respiratoryRate: activity.respiratoryRate,
          weight: activity.weight,
          height: activity.height,
          distanceKm: activity.distanceKm,
          waterIntakeMl: activity.waterIntakeMl,
          sleepMinutes: sleepMins,
          workoutCount: activity.workoutCount,
        );
      }
    }
    return activity;
  }

  Future<int> _readSleepMinutes({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [hc.HealthDataType.SLEEP_SESSION],
      );
      int minutes = 0;
      for (final p in data) {
        if (p.type == hc.HealthDataType.SLEEP_SESSION) {
          minutes += p.dateTo.difference(p.dateFrom).inMinutes.toInt();
        }
      }
      return minutes;
    } catch (e, st) {
      appLogger.w(
        'HealthConnect: read metric failed',
        error: e,
        stackTrace: st,
      );
      return 0;
    }
  }

  @override
  Future<SyncedHealthData> readDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return SyncedHealthData();
    }
    return _readRange(start: start, end: end);
  }

  Future<SyncedHealthData> _readRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // getTotalStepsInInterval deduplicates across multiple sources (Zepp, realme GT 6T, etc.)
      // Raw getHealthDataFromTypes sums all records from all sources = double-counting.
      int steps = 0;
      try {
        final totalSteps = await _health.getTotalStepsInInterval(start, end);
        if (totalSteps != null) steps = totalSteps;
      } catch (e, st) {
        appLogger.w(
          'HealthConnect: read steps failed',
          error: e,
          stackTrace: st,
        );
      }

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _types,
      );

      double activeCalories = 0;
      double totalCalories = 0;
      double distance = 0;
      double water = 0;
      int sleepMinutes = 0;
      int workoutCount = 0;
      double? weight;
      double? height;
      double? restingHR;
      double? hrv;
      double? respiratoryRate;
      final heartRates = <int>[];

      for (final point in data) {
        final v = _parseValue(point);
        switch (point.type) {
          case hc.HealthDataType.STEPS:
            break; // handled above via getTotalStepsInInterval
          case hc.HealthDataType.ACTIVE_ENERGY_BURNED:
            activeCalories += v;
          case hc.HealthDataType.TOTAL_CALORIES_BURNED:
            totalCalories += v;
          case hc.HealthDataType.HEART_RATE:
            final hr = v.toInt();
            if (hr > 0 && hr < 250) heartRates.add(hr);
          case hc.HealthDataType.RESTING_HEART_RATE:
            if (v > 0) restingHR = v;
          case hc.HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
            if (v > 0) hrv = v;
          case hc.HealthDataType.RESPIRATORY_RATE:
            if (v > 0) respiratoryRate = v;
          case hc.HealthDataType.WEIGHT:
            if (v > 0) weight = v;
          case hc.HealthDataType.HEIGHT:
            // Рост в метрах (например 1.75)
            if (v > 0) height = v;
          case hc.HealthDataType.DISTANCE_DELTA:
            // Возвращается в метрах — конвертируем в км
            distance += v;
          case hc.HealthDataType.WATER:
            // Возвращается в литрах — конвертируем в мл ниже
            water += v;
          case hc.HealthDataType.SLEEP_SESSION:
            sleepMinutes += point.dateTo
                .difference(point.dateFrom)
                .inMinutes
                .toInt();
          case hc.HealthDataType.WORKOUT:
            workoutCount++;
          default:
            break;
        }
      }

      // Если HC не записал активные калории — оцениваем по шагам (~0.04 ккал/шаг)
      final effectiveActiveCalories = (activeCalories == 0 && steps > 0)
          ? steps * 0.04
          : activeCalories;

      // Если нет общих калорий — используем активные как минимум
      final effectiveTotalCalories = totalCalories > 0
          ? totalCalories
          : effectiveActiveCalories;

      return SyncedHealthData(
        steps: steps,
        caloriesBurned: effectiveActiveCalories,
        totalCaloriesBurned: effectiveTotalCalories,
        heartRateAvg: heartRates.isNotEmpty
            ? heartRates.reduce((a, b) => a + b) ~/ heartRates.length
            : null,
        restingHeartRate: restingHR?.toInt(),
        heartRateVariability: hrv,
        respiratoryRate: respiratoryRate,
        weight: weight,
        height: height,
        distanceKm: distance > 0 ? distance / 1000 : null,
        waterIntakeMl: water > 0 ? water * 1000 : null,
        sleepMinutes: sleepMinutes > 0 ? sleepMinutes : null,
        workoutCount: workoutCount,
      );
    } catch (e, st) {
      appLogger.w(
        'HealthConnect: read health data failed',
        error: e,
        stackTrace: st,
      );
      return SyncedHealthData();
    }
  }

  double _parseValue(hc.HealthDataPoint point) {
    try {
      final v = point.value;
      if (v is hc.NumericHealthValue) {
        return v.numericValue.toDouble();
      }
      return double.tryParse(v.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {}
}
