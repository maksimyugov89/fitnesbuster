import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/domain/services/i_health_service.dart';
import 'package:fitnesbuster/domain/services/i_health_analytics_service.dart';

part 'health_event.dart';
part 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final IHealthService _healthService;
  final IHealthAnalyticsService _analytics;

  HealthBloc({
    required IHealthService healthService,
    required IHealthAnalyticsService analytics,
  }) : _healthService = healthService,
       _analytics = analytics,
       super(const HealthStateInitial()) {
    on<HealthFetchRequested>(_onFetchRequested);
    on<HealthWatchRequested>(_onWatchRequested);
  }

  Future<void> _onFetchRequested(
    HealthFetchRequested event,
    Emitter<HealthState> emit,
  ) async {
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

      final granted = await _healthService.requestAuthorization(types);
      if (!granted) {
        emit(HealthStateError(message: AppLocalizations.tl('healthNoAccess')));
        return;
      }

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));

      final data = await _healthService.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      final steps = _analytics.sumValue(data, HealthDataType.STEPS)?.toInt();
      final calories = _analytics.sumValue(
        data,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      );
      final heartRate = _analytics
          .avgValue(data, HealthDataType.HEART_RATE)
          ?.toInt();
      final weight = _analytics.lastValue(data, HealthDataType.WEIGHT);
      final sleepMinutes = _analytics.sumSleepMinutes(data);
      final water = _analytics.sumValue(data, HealthDataType.WATER);
      final distance = _analytics.sumValue(data, HealthDataType.DISTANCE_DELTA);

      emit(
        HealthStateLoaded(
          steps: steps ?? 0,
          caloriesBurned: calories ?? 0,
          heartRate: heartRate,
          weight: weight,
          sleepMinutes: sleepMinutes,
          waterIntakeMl: (water ?? 0) * 1000,
          distanceKm: distance ?? 0,
        ),
      );
    } catch (e, st) {
      appLogger.w('[HealthBloc] fetch failed', error: e, stackTrace: st);
      emit(HealthStateError(message: AppLocalizations.tl('healthLoadFailed')));
    }
  }

  Future<void> _onWatchRequested(
    HealthWatchRequested event,
    Emitter<HealthState> emit,
  ) async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.DISTANCE_DELTA,
      ];
      final granted = await _healthService.requestAuthorization(types);
      if (!granted) {
        emit(
          HealthStateError(
            message: AppLocalizations.tl('healthPermissionsDenied'),
          ),
        );
        return;
      }
      final now = DateTime.now();
      final data = await _healthService.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        types: types,
      );
      for (final point in data) {
        if (point.type == HealthDataType.STEPS) {
          add(const HealthFetchRequested());
        }
      }
    } catch (e, st) {
      appLogger.w('[HealthBloc] watch failed', error: e, stackTrace: st);
      emit(HealthStateError(message: AppLocalizations.tl('healthWatchError')));
    }
  }
}
