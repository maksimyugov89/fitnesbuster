part of 'health_sync_bloc.dart';

sealed class HealthSyncState extends Equatable {
  const HealthSyncState();
  @override List<Object?> get props => [];
}

class HealthSyncStateInitial extends HealthSyncState {
  const HealthSyncStateInitial();
}

class HealthSyncStateLoading extends HealthSyncState {
  const HealthSyncStateLoading();
}

class HealthSyncStateLoaded extends HealthSyncState {
  final SyncedHealthData data;
  final DateTime lastSyncAt;

  const HealthSyncStateLoaded({
    required this.data,
    required this.lastSyncAt,
  });
  @override List<Object?> get props => [data, lastSyncAt];
}

class HealthSyncStateError extends HealthSyncState {
  final String message;
  const HealthSyncStateError({required this.message});
  @override List<Object?> get props => [message];
}
