import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

part 'workout_event.dart';
part 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  WorkoutBloc() : super(const WorkoutStateInitial()) {
    on<WorkoutStartRequested>(_onStart);
    on<WorkoutPauseRequested>(_onPause);
    on<WorkoutResumeRequested>(_onResume);
    on<WorkoutStopRequested>(_onStop);
    on<WorkoutSetCompleted>(_onSetCompleted);
    on<WorkoutExerciseChanged>(_onExerciseChanged);
    on<WorkoutTick>(_onTick);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void _onStart(WorkoutStartRequested event, Emitter<WorkoutState> emit) {
    _elapsedSeconds = 0;
    _startTimer();
    emit(WorkoutStateInProgress(
      session: event.session,
      currentExerciseIndex: 0,
      completedSets: [],
      elapsedSeconds: 0,
    ));
  }

  void _onPause(WorkoutPauseRequested event, Emitter<WorkoutState> emit) {
    _timer?.cancel();
    if (state is WorkoutStateInProgress) {
      final current = state as WorkoutStateInProgress;
      emit(current.copyWith(isPaused: true));
    }
  }

  void _onResume(WorkoutResumeRequested event, Emitter<WorkoutState> emit) {
    _startTimer();
    if (state is WorkoutStateInProgress) {
      final current = state as WorkoutStateInProgress;
      emit(current.copyWith(isPaused: false));
    }
  }

  void _onStop(WorkoutStopRequested event, Emitter<WorkoutState> emit) {
    _timer?.cancel();
    final current = state;
    if (current is! WorkoutStateInProgress) {
      emit(const WorkoutStateInitial());
      return;
    }
    if (current.session == null) {
      emit(const WorkoutStateError(message: 'Не удалось завершить тренировку: данные сессии отсутствуют'));
      return;
    }
    emit(WorkoutStateCompleted(
      sessionId: current.session!.id,
      elapsedSeconds: _elapsedSeconds,
      completedSets: List<SetLog>.from(current.completedSets),
    ));
  }

  void _onSetCompleted(WorkoutSetCompleted event, Emitter<WorkoutState> emit) {
    if (state is WorkoutStateInProgress) {
      final current = state as WorkoutStateInProgress;
      final updated = [...current.completedSets, event.setLog];
      emit(current.copyWith(completedSets: updated));
    }
  }

  void _onExerciseChanged(WorkoutExerciseChanged event, Emitter<WorkoutState> emit) {
    if (state is WorkoutStateInProgress) {
      final current = state as WorkoutStateInProgress;
      emit(current.copyWith(currentExerciseIndex: event.index));
    }
  }

  void _onTick(WorkoutTick event, Emitter<WorkoutState> emit) {
    if (state is WorkoutStateInProgress) {
      final current = state as WorkoutStateInProgress;
      emit(current.copyWith(elapsedSeconds: _elapsedSeconds));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (_elapsedSeconds == 1 || _elapsedSeconds % 5 == 0) {
        if (!isClosed) add(const WorkoutTick());
      }
    });
  }
}
