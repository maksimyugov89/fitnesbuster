part of 'nutrition_bloc.dart';

sealed class NutritionState extends Equatable {
  const NutritionState();
  @override
  List<Object?> get props => [];
}

class NutritionStateInitial extends NutritionState {
  const NutritionStateInitial();
}

class NutritionStateLoading extends NutritionState {
  const NutritionStateLoading();
}

class NutritionStateLoaded extends NutritionState {
  final List<MealLog> logs;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final String? mealPlanJson;
  final String? mealPlanError;

  const NutritionStateLoaded({
    required this.logs,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    this.mealPlanJson,
    this.mealPlanError,
  });

  NutritionStateLoaded copyWith({
    List<MealLog>? logs,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    String? mealPlanJson,
    String? mealPlanError,
    bool clearMealPlanError = false,
  }) {
    return NutritionStateLoaded(
      logs: logs ?? this.logs,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      mealPlanJson: mealPlanJson ?? this.mealPlanJson,
      mealPlanError: clearMealPlanError
          ? null
          : (mealPlanError ?? this.mealPlanError),
    );
  }

  double get totalCalories => logs.fold(0.0, (s, m) => s + m.totalCalories);
  double get totalProtein => logs.fold(0.0, (s, m) => s + m.totalProtein);
  double get totalCarbs => logs.fold(0.0, (s, m) => s + m.totalCarbs);
  double get totalFat => logs.fold(0.0, (s, m) => s + m.totalFat);
  double get remainingCalories => targetCalories - totalCalories;

  @override
  List<Object?> get props => [
    logs,
    targetCalories,
    targetProtein,
    targetCarbs,
    targetFat,
    mealPlanJson,
    mealPlanError,
  ];
}

class NutritionStateError extends NutritionState {
  final String message;
  const NutritionStateError({required this.message});
  @override
  List<Object?> get props => [message];
}
