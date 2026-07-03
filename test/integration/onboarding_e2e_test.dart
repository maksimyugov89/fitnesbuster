import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/core/services/onboarding_workflow_service.dart';

import 'onboarding_e2e_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<IUserRepository>(),
  MockSpec<IAuthRepository>(),
  MockSpec<OnboardingWorkflowService>(),
])
void main() {
  late MockIUserRepository mockUserRepo;
  late MockOnboardingWorkflowService mockWorkflowService;
  late MockIAuthRepository mockAuthRepo;

  final tUser = UserEntity(
    id: 'uid-1',
    name: 'Test',
    email: 'test@example.com',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockUserRepo = MockIUserRepository();
    mockWorkflowService = MockOnboardingWorkflowService();
    mockAuthRepo = MockIAuthRepository();
  });

  OnboardingBloc buildBloc() => OnboardingBloc(
    userRepo: mockUserRepo,
    workflowService: mockWorkflowService,
    authRepo: mockAuthRepo,
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'Step 1: Set goal starts collecting',
    build: buildBloc,
    act: (b) => b.add(const OnboardingSetGoal(FitnessGoal.loseWeight)),
    expect: () => [
      isA<OnboardingCollecting>().having(
        (s) => s.goal,
        'goal',
        FitnessGoal.loseWeight,
      ),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'Step 2: Set intensity accumulates state',
    build: () {
      final b = buildBloc();
      b.add(const OnboardingSetGoal(FitnessGoal.gainWeight));
      return b;
    },
    act: (b) => b.add(const OnboardingSetIntensity(IntensityLevel.balanced)),
    skip: 1,
    expect: () => [
      isA<OnboardingCollecting>()
          .having((s) => s.goal, 'goal', FitnessGoal.gainWeight)
          .having((s) => s.intensity, 'intensity', IntensityLevel.balanced),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'Step 3: Set location and running preference',
    build: () {
      final b = buildBloc();
      b.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
      b.add(const OnboardingSetIntensity(IntensityLevel.balanced));
      return b;
    },
    act: (b) => b.add(
      const OnboardingSetLocation(location: 'gym', running: 'treadmill'),
    ),
    skip: 2,
    expect: () => [
      isA<OnboardingCollecting>()
          .having((s) => s.location, 'location', 'gym')
          .having((s) => s.running, 'running', 'treadmill'),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'Step 4: Set profile details',
    build: () {
      final b = buildBloc();
      b.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
      b.add(const OnboardingSetIntensity(IntensityLevel.balanced));
      b.add(const OnboardingSetLocation(location: 'gym', running: 'treadmill'));
      return b;
    },
    act: (b) => b.add(
      OnboardingSetProfile(
        name: 'Athlete',
        dateOfBirth: DateTime(1997, 1, 1),
        weight: 75,
        height: 178,
        gender: Gender.male,
        activity: ActivityLevel.moderatelyActive,
        restrictions: const ['lactose'],
        city: 'Moscow',
      ),
    ),
    skip: 3,
    expect: () => [
      isA<OnboardingCollecting>()
          .having((s) => s.name, 'name', 'Athlete')
          .having((s) => s.dateOfBirth, 'dateOfBirth', DateTime(1997, 1, 1))
          .having((s) => s.weight, 'weight', 75)
          .having((s) => s.height, 'height', 178),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'Step 5: Finalize with full data → generates plan and completes',
    build: () {
      when(mockAuthRepo.currentUser).thenReturn(tUser);
      when(
        mockUserRepo.saveOnboardingData(
          userId: anyNamed('userId'),
          goal: anyNamed('goal'),
          intensity: anyNamed('intensity'),
          location: anyNamed('location'),
          running: anyNamed('running'),
          city: anyNamed('city'),
          profile: anyNamed('profile'),
        ),
      ).thenAnswer((_) async => tUser);
      when(mockUserRepo.getUser('uid-1')).thenAnswer((_) async => tUser);
      when(mockUserRepo.updateProfile(any)).thenAnswer((_) async => tUser);
      when(
        mockWorkflowService.generatePlans(
          userId: anyNamed('userId'),
          profile: anyNamed('profile'),
          city: anyNamed('city'),
        ),
      ).thenAnswer(
        (_) async => (
          workoutPlanJson: '{"plan":"test"}',
          mealPlanJson: '{"meals":"test"}',
        ),
      );

      final b = buildBloc();
      b.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
      b.add(const OnboardingSetIntensity(IntensityLevel.balanced));
      b.add(const OnboardingSetLocation(location: 'gym', running: 'treadmill'));
      b.add(
        OnboardingSetProfile(
          name: 'Athlete',
          dateOfBirth: DateTime(1997, 1, 1),
          weight: 75,
          height: 178,
          gender: Gender.male,
          activity: ActivityLevel.moderatelyActive,
        ),
      );
      return b;
    },
    act: (b) => b.add(const OnboardingFinalize()),
    skip: 4,
    expect: () => [
      const OnboardingSaving(),
      const OnboardingGeneratingPlan(),
      isA<OnboardingComplete>(),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'Network error: save fails emits OnboardingError',
    build: () {
      when(mockAuthRepo.currentUser).thenReturn(tUser);
      when(
        mockUserRepo.saveOnboardingData(
          userId: anyNamed('userId'),
          goal: anyNamed('goal'),
          intensity: anyNamed('intensity'),
          location: anyNamed('location'),
          running: anyNamed('running'),
          city: anyNamed('city'),
          profile: anyNamed('profile'),
        ),
      ).thenThrow(Exception('Network error'));

      final b = buildBloc();
      b.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
      b.add(const OnboardingSetIntensity(IntensityLevel.balanced));
      b.add(const OnboardingSetLocation(location: 'gym', running: 'treadmill'));
      b.add(
        OnboardingSetProfile(
          name: 'Athlete',
          dateOfBirth: DateTime(1997, 1, 1),
          weight: 75,
          height: 178,
          gender: Gender.male,
          activity: ActivityLevel.moderatelyActive,
        ),
      );
      return b;
    },
    act: (b) => b.add(const OnboardingFinalize()),
    skip: 4,
    expect: () => [const OnboardingSaving(), isA<OnboardingError>()],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'AI error: plan generation fails emits OnboardingError',
    build: () {
      when(mockAuthRepo.currentUser).thenReturn(tUser);
      when(
        mockUserRepo.saveOnboardingData(
          userId: anyNamed('userId'),
          goal: anyNamed('goal'),
          intensity: anyNamed('intensity'),
          location: anyNamed('location'),
          running: anyNamed('running'),
          city: anyNamed('city'),
          profile: anyNamed('profile'),
        ),
      ).thenAnswer((_) async => tUser);
      when(mockUserRepo.getUser('uid-1')).thenAnswer((_) async => tUser);
      when(mockUserRepo.updateProfile(any)).thenAnswer((_) async => tUser);
      when(
        mockWorkflowService.generatePlans(
          userId: anyNamed('userId'),
          profile: anyNamed('profile'),
          city: anyNamed('city'),
        ),
      ).thenThrow(Exception('AI service unavailable'));

      final b = buildBloc();
      b.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
      b.add(const OnboardingSetIntensity(IntensityLevel.balanced));
      b.add(const OnboardingSetLocation(location: 'gym', running: 'treadmill'));
      b.add(
        OnboardingSetProfile(
          name: 'Athlete',
          dateOfBirth: DateTime(1997, 1, 1),
          weight: 75,
          height: 178,
          gender: Gender.male,
          activity: ActivityLevel.moderatelyActive,
        ),
      );
      return b;
    },
    act: (b) => b.add(const OnboardingFinalize()),
    skip: 4,
    expect: () => [
      const OnboardingSaving(),
      const OnboardingGeneratingPlan(),
      isA<OnboardingError>(),
    ],
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'Incomplete data: finalize without all fields emits error',
    build: buildBloc,
    act: (b) {
      b.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
      b.add(const OnboardingFinalize());
    },
    skip: 1,
    expect: () => [isA<OnboardingError>()],
  );
}
