import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/training/test_week_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/core/services/test_week_workflow_service.dart';
import 'package:fitnesbuster/domain/usecases/complete_test_week_use_case.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_test_week_progress_repository.dart';
import 'package:fitnesbuster/data/test_week_exercises.dart';
import 'package:fitnesbuster/domain/entities/test_week_progress.dart';

import 'test_week_bloc_test.mocks.dart';

class _MemoryProgressRepository implements ITestWeekProgressRepository {
  TestWeekProgress? progress;
  int loadCalls = 0;

  @override
  Future<TestWeekProgress?> load(String userId) async {
    loadCalls++;
    return progress;
  }

  @override
  Future<void> save(String userId, TestWeekProgress value) async {
    progress = value;
  }

  @override
  Future<void> clear(String userId) async {
    progress = null;
  }
}

@GenerateMocks([
  TestWeekWorkflowService,
  CompleteTestWeekUseCase,
  IAuthRepository,
  IUserRepository,
])
void main() {
  late MockTestWeekWorkflowService mockWorkflow;
  late MockCompleteTestWeekUseCase mockUseCase;
  late TestWeekBloc bloc;
  late MockIAuthRepository mockAuth;
  late MockIUserRepository mockUser;
  late _MemoryProgressRepository mockProgress;

  setUp(() {
    mockWorkflow = MockTestWeekWorkflowService();
    mockUseCase = MockCompleteTestWeekUseCase();
    mockAuth = MockIAuthRepository();
    mockUser = MockIUserRepository();
    mockProgress = _MemoryProgressRepository();
    when(mockAuth.currentUser).thenReturn(null);
    bloc = TestWeekBloc(
      workflowService: mockWorkflow,
      completeTestWeekUseCase: mockUseCase,
      authRepo: mockAuth,
      userRepo: mockUser,
      progressRepo: mockProgress,
      now: () => DateTime(2026, 7, 13),
    );
  });

  tearDown(() => bloc.close());

  test('initial state is TestWeekStateInitial', () {
    expect(bloc.state, const TestWeekStateInitial());
  });

  group('TestWeekInitialize', () {
    blocTest<TestWeekBloc, TestWeekState>(
      'does not restore the archived assessment after server completion',
      build: () {
        final user = UserEntity(
          id: 'user-1',
          name: 'Test User',
          email: 'test@example.com',
          profile: UserProfile.defaults.copyWith(testWeekCompleted: true),
          createdAt: DateTime(2026, 7, 1),
        );
        when(mockAuth.currentUser).thenReturn(user);
        when(mockUser.getUser('user-1')).thenAnswer((_) async => user);
        return bloc;
      },
      act: (b) => b.add(const TestWeekInitialize()),
      expect: () => [const TestWeekStatePlanAccepted()],
      verify: (_) => expect(mockProgress.loadCalls, 0),
    );

    blocTest<TestWeekBloc, TestWeekState>(
      'restores a completed day and keeps the next workout locked until its date',
      build: () {
        mockProgress.progress = TestWeekProgress(
          startedAt: DateTime(2026, 7, 13),
          workoutLocation: 'home',
          completedDays: [
            TestWeekCompletedDay(
              dayIndex: 0,
              completedAt: DateTime(2026, 7, 13, 18),
              rpe: 6,
              exercises: const [
                TestExerciseResult(
                  exerciseName: 'Отжимания',
                  primaryMuscle: MuscleGroup.chest,
                  comfortableWeightKg: 0,
                  comfortableSets: 4,
                  comfortableReps: 12,
                ),
              ],
            ),
          ],
        );
        return bloc;
      },
      act: (b) => b.add(const TestWeekInitialize()),
      expect: () => [
        isA<TestWeekStateDayCompleted>()
            .having((s) => s.nextDayIndex, 'nextDayIndex', 1)
            .having((s) => s.nextDayAvailable, 'nextDayAvailable', isFalse)
            .having(
              (s) => s.nextAvailableAt,
              'nextAvailableAt',
              DateTime(2026, 7, 15),
            ),
      ],
    );
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
      act: (b) async {
        b.add(const TestWeekStartDay(dayIndex: 0));
        await b.stream.firstWhere((s) => s is TestWeekStateDayInProgress);
        for (final exercise in testWeekDaysForLocation('home').first) {
          b.add(
            TestWeekRecordExercise(
              exerciseName: exercise.name,
              muscle: exercise.muscle,
              comfortableWeightKg: exercise.baseWeight,
              comfortableSets: 4,
              comfortableReps: 10,
            ),
          );
          await b.stream.firstWhere(
            (s) =>
                s is TestWeekStateDayInProgress &&
                s.completedExercises.any(
                  (result) => result.exerciseName == exercise.name,
                ),
          );
        }
        b.add(const TestWeekFinishDay(perceivedDifficulty: 6));
      },
      skip: 5,
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
        when(
          mockWorkflow.calculateResults(
            exercises: anyNamed('exercises'),
            profile: anyNamed('profile'),
          ),
        ).thenAnswer(
          (_) async => (
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
          ),
        );
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
        testResult: TestWeekResult(completedAt: DateTime(2024), exercises: []),
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
      act: (b) => b.add(
        const TestWeekAdjustGoal(
          reason: 'Goal too aggressive',
          suggestions: ['Reduce target', 'Extend timeline'],
        ),
      ),
      expect: () => [
        isA<TestWeekStateNeedsAdjustment>()
            .having((s) => s.reason, 'reason', 'Goal too aggressive')
            .having((s) => s.suggestions.length, 'suggestions count', 2),
      ],
    );
  });
}
