part of 'health_bloc.dart';

sealed class HealthEvent extends Equatable {
  const HealthEvent();
  @override
  List<Object?> get props => [];
}

class HealthFetchRequested extends HealthEvent {
  const HealthFetchRequested();
  @override
  List<Object?> get props => [];
}

class HealthWatchRequested extends HealthEvent {
  const HealthWatchRequested();
  @override
  List<Object?> get props => [];
}
