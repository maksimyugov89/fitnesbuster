part of 'health_sync_bloc.dart';

sealed class HealthSyncEvent extends Equatable {
  const HealthSyncEvent();
  @override
  List<Object?> get props => [];
}

class HealthSyncInitializeRequested extends HealthSyncEvent {
  const HealthSyncInitializeRequested();
}

class HealthSyncReadToday extends HealthSyncEvent {
  const HealthSyncReadToday();
}

class HealthSyncReadDateRange extends HealthSyncEvent {
  final DateTime start;
  final DateTime end;
  const HealthSyncReadDateRange({required this.start, required this.end});
  @override
  List<Object?> get props => [start, end];
}
