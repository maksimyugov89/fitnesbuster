part of 'health_sync_bloc.dart';

sealed class HealthSyncState extends Equatable {
  const HealthSyncState();
  @override
  List<Object?> get props => [];
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

  const HealthSyncStateLoaded({required this.data, required this.lastSyncAt});
  @override
  List<Object?> get props => [data, lastSyncAt];
}

enum HealthSyncErrorKind { notInstalled, accessDenied, initialization, read }

class HealthSyncStateError extends HealthSyncState {
  final String message;
  final HealthSyncErrorKind kind;

  const HealthSyncStateError({required this.message, required this.kind});

  @override
  List<Object?> get props => [message, kind];
}
