part of 'health_bloc.dart';

sealed class HealthState extends Equatable {
  const HealthState();
  @override List<Object?> get props => [];
}

class HealthStateInitial extends HealthState {
  const HealthStateInitial();
}

class HealthStateLoading extends HealthState {
  const HealthStateLoading();
}

class HealthStateLoaded extends HealthState {
  final int steps;
  final double caloriesBurned;
  final int? heartRate;
  final double? weight;
  final int? sleepMinutes;
  final double? waterIntakeMl;
  final double? distanceKm;

  const HealthStateLoaded({
    required this.steps,
    required this.caloriesBurned,
    required this.heartRate,
    this.weight,
    this.sleepMinutes,
    this.waterIntakeMl,
    this.distanceKm,
  });
  @override List<Object?> get props => [steps, caloriesBurned, heartRate, weight ?? 0, sleepMinutes ?? 0, waterIntakeMl ?? 0, distanceKm ?? 0];
}

class HealthStateError extends HealthState {
  final String message;
  const HealthStateError({required this.message});
  @override List<Object?> get props => [message];
}
