part of 'ai_bloc.dart';

sealed class AiState extends Equatable {
  const AiState();
  @override
  List<Object?> get props => [];
}

class AiStateInitial extends AiState {
  const AiStateInitial();
}

class AiStateLoading extends AiState {
  const AiStateLoading();
}

class AiStateLoaded extends AiState {
  final String result;
  final AiResultType type;
  const AiStateLoaded({required this.result, required this.type});
  @override
  List<Object?> get props => [result, type];
}

class AiStateError extends AiState {
  final String message;
  const AiStateError({required this.message});
  @override
  List<Object?> get props => [message];
}
