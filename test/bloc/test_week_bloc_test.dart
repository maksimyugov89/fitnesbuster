import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/training/test_week_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';

import 'test_week_bloc_test.mocks.dart';

@GenerateMocks([IAdaptiveTrainingService, IDeepSeekService, IUserRepository, IAuthRepository])
void main() {
  late MockIAdaptiveTrainingService mockTraining;
  late MockIDeepSeekService mockAi;
  late MockIUserRepository mockUserRepo;
  late MockIAuthRepository mockAuthRepo;
  late TestWeekBloc bloc;

  final tUser = UserEntity(
    id: 'uid-1',
    name: 'Test',
    email: 'test@example.com',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockTraining = MockIAdaptiveTrainingService();
    mockAi = MockIDeepSeekService();
    mockUserRepo = MockIUserRepository();
    mockAuthRepo = MockIAuthRepository();
    bloc = TestWeekBloc(
      trainingService: mockTraining,
      aiService: mockAi,
      userRepo: mockUserRepo,
      authRepo: mockAuthRepo,
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
        when(mockTraining.calculateAdjustment(
          testResult: anyNamed('testResult'),
          profile: anyNamed('profile'),
        )).thenReturn(const TrainingAdjustment(
          weightMultiplier: 0.8,
          weeklyIncreasePercent: 5,
          suggestedSetsPerExercise: 3,
          suggestedRepsPerSet: 10,
          userLevel: UserLevel.beginner,
          maxHeartRate: 180,
          adaptedIntensityLabel: 'Beginner',
        ));
        when(mockTraining.checkGoalFeasibility(
          profile: anyNamed('profile'),
          adjustment: anyNamed('adjustment'),
        )).thenAnswer((_) async => const FeasibilityResult(
          isFeasible: true,
          reason: 'Goal is feasible',
          suggestedActions: [],
        ));
        when(mockTraining.buildAdaptedPlan(
          testResult: anyNamed('testResult'),
          adjustment: anyNamed('adjustment'),
          durationWeeks: anyNamed('durationWeeks'),
        )).thenReturn([]);
        return bloc;
      },
      act: (b) => b.add(const TestWeekComplete(
        results: [],
        profile: UserProfile.defaults(),
      )),
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
      'saves plan and emits PlanAccepted when user exists',
      build: () {
        when(mockAuthRepo.currentUser).thenReturn(tUser);
        when(mockUserRepo.getUser('uid-1')).thenAnswer((_) async => tUser);
        when(mockAi.refineWorkoutPlan(any, any))
            .thenAnswer((_) async => '{"refined":true}');
        when(mockUserRepo.updateWorkoutPlan(
          userId: anyNamed('userId'),
          workoutPlanJson: anyNamed('workoutPlanJson'),
        )).thenAnswer((_) async {});
        when(mockUserRepo.saveTestWeekCompleted(userId: anyNamed('userId')))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(const TestWeekAcceptPlan()),
      expect: () => [
        const TestWeekStateCalculating(),
        const TestWeekStatePlanAccepted(),
      ],
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
