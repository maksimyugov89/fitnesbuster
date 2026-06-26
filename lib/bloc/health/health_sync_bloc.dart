import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';

part 'health_sync_event.dart';
part 'health_sync_state.dart';

/// Manages Health Connect sync for fitness data.
class HealthSyncBloc extends Bloc<HealthSyncEvent, HealthSyncState> {
  final HealthConnectService _hcService;

  HealthSyncBloc({required HealthConnectService hcService})
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
          emit(const HealthSyncStateError(
            message: 'Health Connect не установлен. Установите из Google Play.',
          ));
        } else {
          emit(const HealthSyncStateError(
            message: 'Не удалось получить доступ к Health Connect. Проверьте разрешения.',
          ));
        }
      }
    } catch (e) {
      emit(HealthSyncStateError(
        message: 'Ошибка инициализации Health Connect: $e',
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
    } catch (e) {
      emit(HealthSyncStateError(message: 'Ошибка чтения данных: $e'));
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
    } catch (e) {
      emit(HealthSyncStateError(message: 'Ошибка: $e'));
    }
  }
}
