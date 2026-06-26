import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:health/health.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final Health _health;

  HealthBloc({Health? health})
      : _health = health ?? Health(),
        super(const HealthStateInitial()) {
    on<HealthFetchRequested>(_onFetchRequested);
    on<HealthWatchRequested>(_onWatchRequested);
  }

  Future<void> _onFetchRequested(HealthFetchRequested event, Emitter<HealthState> emit) async {
    emit(const HealthStateLoading());
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.WATER,
        HealthDataType.DISTANCE_DELTA,
      ];

      final granted = await _health.requestAuthorization(types);
      if (!granted) {
        emit(const HealthStateError(message: 'Нет доступа к данным здоровья. Предоставьте разрешения в настройках.'));
        return;
      }

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      final steps = _sumValue(data, HealthDataType.STEPS)?.toInt();
      final calories = _sumValue(data, HealthDataType.ACTIVE_ENERGY_BURNED);
      final heartRate = _avgValue(data, HealthDataType.HEART_RATE)?.toInt();
      final weight = _lastValue(data, HealthDataType.WEIGHT);
      final sleepMinutes = _sumSleepMinutes(data);
      final water = _sumValue(data, HealthDataType.WATER);
      final distance = _sumValue(data, HealthDataType.DISTANCE_DELTA);

      emit(HealthStateLoaded(
        steps: steps ?? 0,
        caloriesBurned: calories ?? 0,
        heartRate: heartRate ?? 72,
        weight: weight,
        sleepMinutes: sleepMinutes,
        waterIntakeMl: (water ?? 0) * 1000,
        distanceKm: distance ?? 0,
      ));
    } catch (e) {
      emit(HealthStateError(message: 'Не удалось загрузить данные: $e'));
    }
  }

  Future<void> _onWatchRequested(HealthWatchRequested event, Emitter<HealthState> emit) async {
    try {
      final types = [HealthDataType.STEPS, HealthDataType.HEART_RATE, HealthDataType.DISTANCE_DELTA];
      final granted = await _health.requestAuthorization(types);
      if (!granted) {
        emit(const HealthStateError(message: 'Разрешения Health не предоставлены'));
        return;
      }
      final now = DateTime.now();
      final data = await _health.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        types: types,
      );
      for (final point in data) {
        if (point.type == HealthDataType.STEPS) {
          add(HealthFetchRequested());
        }
      }
    } catch (e) {
      emit(HealthStateError(message: 'Ошибка Health: $e'));
    }
  }

  int _sumSleepMinutes(List<HealthDataPoint> data) {
    return data
        .where((p) => p.type == HealthDataType.SLEEP_SESSION)
        .fold(0, (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes);
  }

  double? _sumValue(List<HealthDataPoint> data, HealthDataType type) {
    final filtered = data.where((p) => p.type == type);
    if (filtered.isEmpty) return null;
    return filtered.fold<double>(0, (sum, p) {
      final v = double.tryParse(p.value.toString());
      return sum + (v ?? 0);
    });
  }

  double? _avgValue(List<HealthDataPoint> data, HealthDataType type) {
    final filtered = data.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    final sum = filtered.fold<double>(0, (s, p) {
      final v = double.tryParse(p.value.toString());
      return s + (v ?? 0);
    });
    return sum / filtered.length;
  }

  double? _lastValue(List<HealthDataPoint> data, HealthDataType type) {
    final filtered = data.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    return double.tryParse(filtered.last.value.toString());
  }
}
