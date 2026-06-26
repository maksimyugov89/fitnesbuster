import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart' show AiException;
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';

part 'ai_event.dart';
part 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final IDeepSeekService _aiService;

  AiBloc({required IDeepSeekService aiService})
      : _aiService = aiService,
        super(const AiStateInitial()) {
    on<AiGenerateWorkoutPlan>(_onGenerateWorkoutPlan);
    on<AiGenerateMealPlan>(_onGenerateMealPlan);
    on<AiAskQuestion>(_onAskQuestion);
    on<AiReset>(_onReset);
  }

  Future<void> _onGenerateWorkoutPlan(
    AiGenerateWorkoutPlan event,
    Emitter<AiState> emit,
  ) async {
    emit(const AiStateLoading());
    try {
      final result = await _aiService.generateWorkoutPlan(event.profile);
      emit(AiStateLoaded(result: result, type: AiResultType.workoutPlan));
    } on AiException catch (e) {
      emit(AiStateError(message: e.message));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AiBloc] generateWorkoutPlan failed: $e\n$st');
      emit(const AiStateError(message: 'Не удалось сгенерировать программу. Попробуйте снова.'));
    }
  }

  Future<void> _onGenerateMealPlan(
    AiGenerateMealPlan event,
    Emitter<AiState> emit,
  ) async {
    emit(const AiStateLoading());
    try {
      final result = await _aiService.generateMealPlan(event.profile);
      emit(AiStateLoaded(result: result, type: AiResultType.mealPlan));
    } on AiException catch (e) {
      emit(AiStateError(message: e.message));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AiBloc] generateMealPlan failed: $e\n$st');
      emit(const AiStateError(message: 'Не удалось сгенерировать план питания. Попробуйте снова.'));
    }
  }

  Future<void> _onAskQuestion(
    AiAskQuestion event,
    Emitter<AiState> emit,
  ) async {
    emit(const AiStateLoading());
    try {
      final result = await _aiService.askQuestion(
        event.question,
        profile: event.profile,
      );
      emit(AiStateLoaded(result: result, type: AiResultType.answer));
    } on AiException catch (e) {
      emit(AiStateError(message: e.message));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AiBloc] askQuestion failed: $e\n$st');
      emit(const AiStateError(message: 'Не удалось получить ответ. Попробуйте снова.'));
    }
  }

  void _onReset(AiReset event, Emitter<AiState> emit) {
    emit(const AiStateInitial());
  }
}
