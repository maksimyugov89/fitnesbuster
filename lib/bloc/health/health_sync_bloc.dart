import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/domain/entities/synced_health_data.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

part 'health_sync_event.dart';
part 'health_sync_state.dart';

/// Manages Health Connect sync for fitness data.
class HealthSyncBloc extends Bloc<HealthSyncEvent, HealthSyncState> {
  final IHealthConnectService _hcService;

  HealthSyncBloc({required IHealthConnectService hcService})
      : _hcService = hcService,
        super(const HealthSyncStateInitial()) {
    on<HealthSyncInitializeRequested>(_onInitialize);
    on<HealthSyncReadToday>(_onReadToday);
    on<HealthSyncReadDateRange>(_onReadDateRange);
  }

  Future<void> _onInitialize(
    HealthSyncInitializeRequested event,
    Emitter<HealthSyncState> emit,
  ) async {
    emit(const HealthSyncStateLoading());
    try {
      final initialized = await _hcService.initialize();
      if (initialized) {
        add(const HealthSyncReadToday());
      } else {
        final installed = await _hcService.isHealthConnectAvailable();
        if (!installed) {
          emit(HealthSyncStateError(
            message: AppLocalizations.tl('healthConnectNotInstalled'),
          ));
        } else {
          emit(HealthSyncStateError(
            message: AppLocalizations.tl('healthConnectAccessDenied'),
          ));
        }
      }
    } catch (e, st) {
      appLogger.w('[HealthSyncBloc] init failed', error: e, stackTrace: st);
      emit(HealthSyncStateError(
        message: AppLocalizations.tl('healthConnectInitError'),
      ));
    }
  }

  Future<void> _onReadToday(
    HealthSyncReadToday event,
    Emitter<HealthSyncState> emit,
  ) async {
    emit(const HealthSyncStateLoading());
    try {
      final data = await _hcService.readAllToday();
      emit(HealthSyncStateLoaded(
        data: data,
        lastSyncAt: DateTime.now(),
      ));
    } catch (e, st) {
      appLogger.w('[HealthSyncBloc] read today failed', error: e, stackTrace: st);
      emit(HealthSyncStateError(message: AppLocalizations.tl('healthSyncReadError')));
    }
  }

  Future<void> _onReadDateRange(
    HealthSyncReadDateRange event,
    Emitter<HealthSyncState> emit,
  ) async {
    emit(const HealthSyncStateLoading());
    try {
      final data = await _hcService.readDateRange(
        start: event.start,
        end: event.end,
      );
      emit(HealthSyncStateLoaded(
        data: data,
        lastSyncAt: DateTime.now(),
      ));
    } catch (e, st) {
      appLogger.w('[HealthSyncBloc] read range failed', error: e, stackTrace: st);
      emit(HealthSyncStateError(message: AppLocalizations.tl('healthSyncRangeError')));
    }
  }
}
