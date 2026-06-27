import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart' show AiException;
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

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
      appLogger.w('[AiBloc] generateWorkoutPlan failed', error: e, stackTrace: st);
      emit(AiStateError(message: AppLocalizations.tl('aiGenerateWorkoutFailed')));
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
      appLogger.d('[AiBloc] generateMealPlan failed', error: e, stackTrace: st);
      emit(AiStateError(message: AppLocalizations.tl('aiGenerateMealFailed')));
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
      appLogger.w('[AiBloc] askQuestion failed', error: e, stackTrace: st);
      emit(AiStateError(message: AppLocalizations.tl('aiAskFailed')));
    }
  }

  void _onReset(AiReset event, Emitter<AiState> emit) {
    emit(const AiStateInitial());
  }
}
