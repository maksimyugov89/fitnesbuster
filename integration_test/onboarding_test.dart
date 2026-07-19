// E2E integration tests — Onboarding flow (P2-04)
// Run with: flutter test integration_test/
// Firebase is mocked via get_it DI overrides.
// ignore_for_file: argument_type_not_assignable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';

import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/onboarding_workflow_service.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/goal_selection_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/intensity_selection_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/workout_location_screen.dart';
import 'package:fitnesbuster/presentation/screens/dashboard/dashboard_screen.dart';

import 'onboarding_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockIAuthRepository mockAuthRepo;
  late MockIUserRepository mockUserRepo;
  late MockISettingsRepository mockSettingsRepo;
  late MockIHealthConnectService mockHealthConnect;
  late MockISocialService mockSocial;
  late MockIGamificationService mockGamification;
  late MockOnboardingWorkflowService mockWorkflowService;

  final testUser = UserEntity(
    id: 'test-uid',
    name: 'Test',
    email: 'test@example.com',
    createdAt: DateTime(2024),
  );

  setUpAll(() async {
    mockAuthRepo = MockIAuthRepository();
    mockUserRepo = MockIUserRepository();
    mockSettingsRepo = MockISettingsRepository();
    mockHealthConnect = MockIHealthConnectService();
    mockSocial = MockISocialService();
    mockGamification = MockIGamificationService();
    mockWorkflowService = MockOnboardingWorkflowService();

    if (GetIt.instance.isRegistered<IAuthRepository>()) {
      GetIt.instance.unregister<IAuthRepository>();
    }
    if (GetIt.instance.isRegistered<IUserRepository>()) {
      GetIt.instance.unregister<IUserRepository>();
    }
    if (GetIt.instance.isRegistered<ISettingsRepository>()) {
      GetIt.instance.unregister<ISettingsRepository>();
    }
    if (GetIt.instance.isRegistered<IHealthConnectService>()) {
      GetIt.instance.unregister<IHealthConnectService>();
    }
    if (GetIt.instance.isRegistered<ISocialService>()) {
      GetIt.instance.unregister<ISocialService>();
    }
    if (GetIt.instance.isRegistered<IGamificationService>()) {
      GetIt.instance.unregister<IGamificationService>();
    }
    if (GetIt.instance.isRegistered<OnboardingWorkflowService>()) {
      GetIt.instance.unregister<OnboardingWorkflowService>();
    }

    GetIt.instance.registerLazySingleton<IAuthRepository>(() => mockAuthRepo);
    GetIt.instance.registerLazySingleton<IUserRepository>(() => mockUserRepo);
    GetIt.instance.registerLazySingleton<ISettingsRepository>(
      () => mockSettingsRepo,
    );
    GetIt.instance.registerLazySingleton<IHealthConnectService>(
      () => mockHealthConnect,
    );
    GetIt.instance.registerLazySingleton<ISocialService>(() => mockSocial);
    GetIt.instance.registerLazySingleton<IGamificationService>(
      () => mockGamification,
    );
    GetIt.instance.registerLazySingleton<OnboardingWorkflowService>(
      () => mockWorkflowService,
    );

    when(mockAuthRepo.currentUser).thenReturn(testUser);

    when(mockSettingsRepo.getAvatarMode()).thenAnswer((_) async => 'initials');
    when(mockSettingsRepo.getAvatarPresetIndex()).thenAnswer((_) async => -1);
    when(
      mockSettingsRepo.getAvatarCustomPath(),
    ).thenAnswer((_) async => null as String?);
    when(mockSettingsRepo.getEatenCal(any)).thenAnswer((_) async => 0);
    when(mockSettingsRepo.getTargetCal(any)).thenAnswer((_) async => 2000);
    when(mockSettingsRepo.getWaterMl(any)).thenAnswer((_) async => 0);
    when(mockSettingsRepo.getWorkoutDone(any)).thenAnswer((_) async => false);
    when(mockSettingsRepo.getWorkoutKcal(any)).thenAnswer((_) async => 0);
    when(mockSettingsRepo.getMealsDone(any)).thenAnswer((_) async => []);
    when(mockSettingsRepo.getManualSteps(any)).thenAnswer((_) async => 0);

    when(mockHealthConnect.initialize()).thenAnswer((_) async => true);
    when(
      mockHealthConnect.readAllToday(),
    ).thenThrow(Exception('Not available'));

    when(
      mockSocial.incomingRequestsStream(),
    ).thenAnswer((_) => const Stream.empty());

    when(mockGamification.getTotalXp()).thenAnswer((_) async => 0);
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('P2-04: Full Onboarding Flow', () {
    testWidgets('Step 1: Goal selection screen renders and allows selection', (
      tester,
    ) async {
      final onboardingBloc = OnboardingBloc(
        userRepo: sl(),
        workflowService: sl(),
        authRepo: mockAuthRepo,
      );

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: BlocProvider<OnboardingBloc>.value(
            value: onboardingBloc,
            child: const MaterialApp(home: GoalSelectionScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Похудеть'), findsOneWidget);
      expect(find.text('Набрать\nмассу'), findsOneWidget);

      await tester.tap(find.text('Похудеть'));
      await tester.pumpAndSettle();

      expect(onboardingBloc.state, isA<OnboardingCollecting>());
      expect(
        (onboardingBloc.state as OnboardingCollecting).goal,
        FitnessGoal.loseWeight,
      );

      await onboardingBloc.close();
    });

    testWidgets('Step 2: Intensity selection screen renders', (tester) async {
      final onboardingBloc = OnboardingBloc(
        userRepo: sl(),
        workflowService: sl(),
        authRepo: mockAuthRepo,
      );
      onboardingBloc.add(const OnboardingSetGoal(FitnessGoal.loseWeight));

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: BlocProvider<OnboardingBloc>.value(
            value: onboardingBloc,
            child: const MaterialApp(home: IntensitySelectionScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ХАРДКОР'), findsOneWidget);
      expect(find.text('Продолжить'), findsOneWidget);

      await onboardingBloc.close();
    });

    testWidgets('Step 3: Workout location screen renders', (tester) async {
      final onboardingBloc = OnboardingBloc(
        userRepo: sl(),
        workflowService: sl(),
        authRepo: mockAuthRepo,
      );
      onboardingBloc
        ..add(const OnboardingSetGoal(FitnessGoal.loseWeight))
        ..add(const OnboardingSetIntensity(IntensityLevel.balanced));

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: BlocProvider<OnboardingBloc>.value(
            value: onboardingBloc,
            child: const MaterialApp(home: WorkoutLocationScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Фитнес\nклуб'), findsOneWidget);
      expect(find.text('Уличный\nворкаут'), findsOneWidget);
      expect(find.text('Дом'), findsOneWidget);

      await onboardingBloc.close();
    });

    testWidgets('Full flow: all onboarding screens render without crashing', (
      tester,
    ) async {
      final onboardingBloc = OnboardingBloc(
        userRepo: sl(),
        workflowService: sl(),
        authRepo: mockAuthRepo,
      );
      onboardingBloc
        ..add(const OnboardingSetGoal(FitnessGoal.loseWeight))
        ..add(const OnboardingSetIntensity(IntensityLevel.balanced))
        ..add(
          const OnboardingSetLocation(location: 'gym', running: 'treadmill'),
        );

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: BlocProvider<OnboardingBloc>.value(
            value: onboardingBloc,
            child: const MaterialApp(home: GoalSelectionScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: BlocProvider<OnboardingBloc>.value(
            value: onboardingBloc,
            child: const MaterialApp(home: IntensitySelectionScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: BlocProvider<OnboardingBloc>.value(
            value: onboardingBloc,
            child: const MaterialApp(home: WorkoutLocationScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await onboardingBloc.close();
    });

    testWidgets('Navigate to dashboard after onboarding — screen renders', (
      tester,
    ) async {
      final authBloc = AuthBloc(authRepository: mockAuthRepo);
      when(mockAuthRepo.userChanges).thenAnswer((_) => Stream.value(testUser));
      when(mockAuthRepo.currentUser).thenReturn(testUser);

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: MultiBlocProvider(
            providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
            child: const MaterialApp(home: DashboardScreen()),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await authBloc.close();
    });
  });
}
