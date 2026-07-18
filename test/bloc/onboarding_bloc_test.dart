import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/core/services/onboarding_workflow_service.dart';

import 'onboarding_bloc_test.mocks.dart';

@GenerateMocks([IUserRepository, IAuthRepository, OnboardingWorkflowService])
void main() {
  late MockIUserRepository mockUserRepo;
  late MockOnboardingWorkflowService mockWorkflowService;
  late MockIAuthRepository mockAuthRepo;
  late OnboardingBloc bloc;

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
    bloc = OnboardingBloc(
      userRepo: mockUserRepo,
      workflowService: mockWorkflowService,
      authRepo: mockAuthRepo,
    );
    // OnboardingBloc syncs the freshly-saved user into AuthBloc via GetIt
    // (`sl<AuthBloc>().add(AuthUserChanged(...))`) — register a real AuthBloc
    // backed by the same mock repo so that call doesn't throw.
    if (GetIt.instance.isRegistered<AuthBloc>()) {
      GetIt.instance.unregister<AuthBloc>();
    }
    GetIt.instance.registerLazySingleton<AuthBloc>(
      () => AuthBloc(authRepository: mockAuthRepo),
    );
  });

  tearDown(() {
    bloc.close();
    if (GetIt.instance.isRegistered<AuthBloc>()) {
      GetIt.instance.unregister<AuthBloc>();
    }
  });

  test('initial state is OnboardingCollecting', () {
    expect(bloc.state, const OnboardingCollecting());
  });

  group('OnboardingSetGoal', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'updates goal in collecting state',
      build: () => bloc,
      act: (b) => b.add(const OnboardingSetGoal(FitnessGoal.loseWeight)),
      expect: () => [
        isA<OnboardingCollecting>().having(
          (s) => s.goal,
          'goal',
          FitnessGoal.loseWeight,
        ),
      ],
    );
  });

  group('OnboardingSetIntensity', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'updates intensity in collecting state',
      build: () => bloc,
      act: (b) => b.add(const OnboardingSetIntensity(IntensityLevel.balanced)),
      expect: () => [
        isA<OnboardingCollecting>().having(
          (s) => s.intensity,
          'intensity',
          IntensityLevel.balanced,
        ),
      ],
    );
  });

  group('OnboardingSetLocation', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'updates location and running preference',
      build: () => bloc,
      act: (b) => b.add(
        const OnboardingSetLocation(location: 'gym', running: 'treadmill'),
      ),
      expect: () => [
        isA<OnboardingCollecting>()
            .having((s) => s.location, 'location', 'gym')
            .having((s) => s.running, 'running', 'treadmill'),
      ],
    );

    test('location and running are copied into the AI profile', () {
      final profile = const OnboardingCollecting(
        location: 'outdoor',
        running: 'withRunning',
      ).toUserProfile();
      expect(profile.workoutLocation, 'outdoor');
      expect(profile.runningPreference, 'withRunning');
    });
  });

  group('OnboardingFinalize', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emits error when data is incomplete',
      build: () => bloc,
      act: (b) => b.add(const OnboardingFinalize()),
      expect: () => [isA<OnboardingError>()],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emits Saving then Complete on success',
      build: () {
        when(mockAuthRepo.currentUser).thenReturn(tUser);
        when(mockAuthRepo.userChanges).thenAnswer((_) => Stream.value(tUser));
        when(mockAuthRepo.isEmailVerified).thenReturn(true);
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
            workoutPlanJson: '{"title":"test"}',
            mealPlanJson: '{"meals":[]}',
          ),
        );

        final bloc = OnboardingBloc(
          userRepo: mockUserRepo,
          workflowService: mockWorkflowService,
          authRepo: mockAuthRepo,
        );
        bloc.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
        bloc.add(const OnboardingSetIntensity(IntensityLevel.balanced));
        bloc.add(
          const OnboardingSetLocation(location: 'gym', running: 'treadmill'),
        );
        bloc.add(
          OnboardingSetProfile(
            name: 'Test',
            dateOfBirth: DateTime(1994, 1, 1),
            weight: 80,
            height: 180,
            gender: Gender.male,
            activity: ActivityLevel.moderatelyActive,
          ),
        );
        return bloc;
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
      'emits error when save fails',
      build: () {
        when(mockAuthRepo.currentUser).thenReturn(tUser);
        when(mockAuthRepo.userChanges).thenAnswer((_) => Stream.value(tUser));
        when(mockAuthRepo.isEmailVerified).thenReturn(true);
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
        ).thenThrow(Exception('Firestore error'));

        final bloc = OnboardingBloc(
          userRepo: mockUserRepo,
          workflowService: mockWorkflowService,
          authRepo: mockAuthRepo,
        );
        bloc.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
        bloc.add(const OnboardingSetIntensity(IntensityLevel.balanced));
        bloc.add(
          const OnboardingSetLocation(location: 'gym', running: 'treadmill'),
        );
        bloc.add(
          OnboardingSetProfile(
            name: 'Test',
            dateOfBirth: DateTime(1994, 1, 1),
            weight: 80,
            height: 180,
            gender: Gender.male,
            activity: ActivityLevel.moderatelyActive,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const OnboardingFinalize()),
      skip: 4,
      expect: () => [const OnboardingSaving(), isA<OnboardingError>()],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emits error when plan generation fails',
      build: () {
        when(mockAuthRepo.currentUser).thenReturn(tUser);
        when(mockAuthRepo.userChanges).thenAnswer((_) => Stream.value(tUser));
        when(mockAuthRepo.isEmailVerified).thenReturn(true);
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
        ).thenThrow(Exception('AI error'));

        final bloc = OnboardingBloc(
          userRepo: mockUserRepo,
          workflowService: mockWorkflowService,
          authRepo: mockAuthRepo,
        );
        bloc.add(const OnboardingSetGoal(FitnessGoal.loseWeight));
        bloc.add(const OnboardingSetIntensity(IntensityLevel.balanced));
        bloc.add(
          const OnboardingSetLocation(location: 'gym', running: 'treadmill'),
        );
        bloc.add(
          OnboardingSetProfile(
            name: 'Test',
            dateOfBirth: DateTime(1994, 1, 1),
            weight: 80,
            height: 180,
            gender: Gender.male,
            activity: ActivityLevel.moderatelyActive,
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const OnboardingFinalize()),
      skip: 4,
      expect: () => [
        const OnboardingSaving(),
        const OnboardingGeneratingPlan(),
        isA<OnboardingError>(),
      ],
    );
  });
}
