import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/training/test_week_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/core/services/test_week_workflow_service.dart';
import 'package:fitnesbuster/domain/usecases/complete_test_week_use_case.dart';

import 'test_week_bloc_test.mocks.dart';

@GenerateMocks([TestWeekWorkflowService, CompleteTestWeekUseCase])
void main() {
  late MockTestWeekWorkflowService mockWorkflow;
  late MockCompleteTestWeekUseCase mockUseCase;
  late TestWeekBloc bloc;

  setUp(() {
    mockWorkflow = MockTestWeekWorkflowService();
    mockUseCase = MockCompleteTestWeekUseCase();
    bloc = TestWeekBloc(
      workflowService: mockWorkflow,
      completeTestWeekUseCase: mockUseCase,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is TestWeekStateInitial', () {
    expect(bloc.state, const TestWeekStateInitial());
  });

  group('TestWeekStartDay', () {
    blocTest<TestWeekBloc, TestWeekState>(
      'emits DayInProgress for day 0',
      build: () => bloc,
      act: (b) => b.add(const TestWeekStartDay(dayIndex: 0)),
      expect: () => [
        isA<TestWeekStateDayInProgress>()
            .having((s) => s.dayIndex, 'dayIndex', 0)
            .having((s) => s.completedExercises, 'completedExercises', isEmpty),
      ],
    );

    blocTest<TestWeekBloc, TestWeekState>(
      'does not emit when dayIndex is out of range',
      build: () => bloc,
      act: (b) => b.add(const TestWeekStartDay(dayIndex: 999)),
      expect: () => [],
    );
  });

  group('TestWeekFinishDay', () {
    blocTest<TestWeekBloc, TestWeekState>(
      'emits DayCompleted when more days remain',
      build: () => bloc,
      act: (b) {
        b.add(const TestWeekStartDay(dayIndex: 0));
        b.add(const TestWeekFinishDay());
      },
      skip: 1,
      expect: () => [
        isA<TestWeekStateDayCompleted>()
            .having((s) => s.dayIndex, 'dayIndex', 0)
            .having((s) => s.nextDayIndex, 'nextDayIndex', 1),
      ],
    );
  });

  group('TestWeekComplete', () {
    blocTest<TestWeekBloc, TestWeekState>(
      'emits Completed after calculating results',
      build: () {
        when(mockWorkflow.calculateResults(
          exercises: anyNamed('exercises'),
          profile: anyNamed('profile'),
        )).thenAnswer((_) async => (
          adjustment: const TrainingAdjustment(
            weightMultiplier: 0.8,
            weeklyIncreasePercent: 5,
            suggestedSetsPerExercise: 3,
            suggestedRepsPerSet: 10,
            userLevel: UserLevel.beginner,
            maxHeartRate: 180,
            adaptedIntensityLabel: 'Beginner',
          ),
          feasibility: const FeasibilityResult(
            isFeasible: true,
            reason: 'Goal is feasible',
            suggestedActions: [],
          ),
          adaptedPlan: <AdaptiveWeek>[],
          testResult: TestWeekResult(
            completedAt: DateTime(2024),
            exercises: [],
            averageHeartRate: 0,
            averageSessionDuration: 0,
            perceivedDifficulty: 5,
          ),
        ));
        return bloc;
      },
      act: (b) => b.add(const TestWeekComplete(results: [])),
      expect: () => [
        const TestWeekStateCalculating(),
        isA<TestWeekStateCompleted>(),
      ],
    );
  });

  group('TestWeekAcceptPlan', () {
    blocTest<TestWeekBloc, TestWeekState>(
      'emits PlanAccepted after accepting',
      build: () => bloc,
      act: (b) => b.add(const TestWeekAcceptPlan()),
      expect: () => [
        const TestWeekStateCalculating(),
        const TestWeekStatePlanAccepted(),
      ],
    );

    blocTest<TestWeekBloc, TestWeekState>(
      'calls useCase.execute and emits PlanAccepted',
      build: () {
        when(mockUseCase.execute(any)).thenAnswer((_) async {});
        return bloc;
      },
      seed: () => TestWeekStateCompleted(
        testResult: TestWeekResult(
          completedAt: DateTime(2024),
          exercises: [],
        ),
        adjustment: const TrainingAdjustment(
          weightMultiplier: 0.8,
          weeklyIncreasePercent: 5,
          suggestedSetsPerExercise: 3,
          suggestedRepsPerSet: 10,
          userLevel: UserLevel.beginner,
          maxHeartRate: 180,
          adaptedIntensityLabel: 'Beginner',
        ),
        feasibility: const FeasibilityResult(
          isFeasible: true,
          reason: 'Goal is feasible',
          suggestedActions: [],
        ),
        adaptedPlan: [],
      ),
      act: (b) => b.add(const TestWeekAcceptPlan()),
      expect: () => [
        const TestWeekStateCalculating(),
        const TestWeekStatePlanAccepted(),
      ],
      verify: (_) {
        verify(mockUseCase.execute(any)).called(1);
      },
    );
  });

  group('TestWeekAdjustGoal', () {
    blocTest<TestWeekBloc, TestWeekState>(
      'emits NeedsAdjustment with reason',
      build: () => bloc,
      act: (b) => b.add(const TestWeekAdjustGoal(
        reason: 'Goal too aggressive',
        suggestions: ['Reduce target', 'Extend timeline'],
      )),
      expect: () => [
        isA<TestWeekStateNeedsAdjustment>()
            .having((s) => s.reason, 'reason', 'Goal too aggressive')
            .having((s) => s.suggestions.length, 'suggestions count', 2),
      ],
    );
  });
}
