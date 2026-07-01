part of 'ai_bloc.dart';

enum AiResultType { workoutPlan, mealPlan, answer }

sealed class AiEvent extends Equatable {
  const AiEvent();
  @override
  List<Object?> get props => [];
}

class AiGenerateWorkoutPlan extends AiEvent {
  final UserProfile profile;
  const AiGenerateWorkoutPlan({required this.profile});
  @override
  List<Object?> get props => [profile];
}

class AiGenerateMealPlan extends AiEvent {
  final UserProfile profile;
  const AiGenerateMealPlan({required this.profile});
  @override
  List<Object?> get props => [profile];
}

class AiAskQuestion extends AiEvent {
  final String question;
  final UserProfile? profile;
  const AiAskQuestion({required this.question, this.profile});
  @override
  List<Object?> get props => [question, profile ?? ''];
}

class AiReset extends AiEvent {
  const AiReset();
}
