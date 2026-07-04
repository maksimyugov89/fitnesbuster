// Golden test for DashboardScreen (P2-06)
// Run: flutter test --update-goldens test/golden/dashboard_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';

import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';
import 'package:fitnesbuster/bloc/ai/ai_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/synced_health_data.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/presentation/screens/dashboard/dashboard_screen.dart';

import 'dashboard_golden_test.mocks.dart';

@GenerateMocks([
  IAuthRepository,
  IUserRepository,
  ISettingsRepository,
  IHealthConnectService,
  ISocialService,
  IGamificationService,
  IDeepSeekService,
])
void main() {
  late MockIAuthRepository mockAuthRepo;
  late MockIUserRepository mockUserRepo;
  late MockISettingsRepository mockSettingsRepo;
  late MockIHealthConnectService mockHealthConnect;
  late MockISocialService mockSocial;
  late MockIGamificationService mockGamification;

  late MockIDeepSeekService mockDeepSeek;

  final testUser = UserEntity(
    id: 'golden-uid',
    name: 'Golden User',
    email: 'golden@test.com',
    createdAt: DateTime(2024),
  );

  setUpAll(() async {
    mockAuthRepo = MockIAuthRepository();
    mockUserRepo = MockIUserRepository();
    mockSettingsRepo = MockISettingsRepository();
    mockHealthConnect = MockIHealthConnectService();
    mockSocial = MockISocialService();
    mockGamification = MockIGamificationService();
    mockDeepSeek = MockIDeepSeekService();

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

    if (GetIt.instance.isRegistered<IDeepSeekService>()) {
      GetIt.instance.unregister<IDeepSeekService>();
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
    GetIt.instance.registerLazySingleton<IDeepSeekService>(() => mockDeepSeek);

    when(mockAuthRepo.currentUser).thenReturn(testUser);
    when(mockAuthRepo.userChanges).thenAnswer((_) => Stream.value(testUser));
    when(mockAuthRepo.isEmailVerified).thenReturn(true);

    when(mockSettingsRepo.getAvatarMode()).thenAnswer((_) async => 'initials');
    when(mockSettingsRepo.getAvatarPresetIndex()).thenAnswer((_) async => -1);
    when(mockSettingsRepo.getAvatarCustomPath()).thenAnswer((_) async => null);
    when(mockSettingsRepo.getEatenCal(any)).thenAnswer((_) async => 0);
    when(mockSettingsRepo.getTargetCal(any)).thenAnswer((_) async => 2000);
    when(mockSettingsRepo.getWaterMl(any)).thenAnswer((_) async => 0);
    when(mockSettingsRepo.getWorkoutDone(any)).thenAnswer((_) async => false);
    when(mockSettingsRepo.getWorkoutKcal(any)).thenAnswer((_) async => 0);
    when(mockSettingsRepo.getMealsDone(any)).thenAnswer((_) async => []);
    when(mockSettingsRepo.getManualSteps(any)).thenAnswer((_) async => 0);

    when(mockHealthConnect.initialize()).thenAnswer((_) async => true);
    when(mockHealthConnect.readAllToday()).thenAnswer(
      (_) async => SyncedHealthData(
        steps: 0,
        caloriesBurned: 0,
        weight: 75.0,
        waterIntakeMl: 0,
      ),
    );

    when(
      mockSocial.incomingRequestsStream(),
    ).thenAnswer((_) => const Stream.empty());

    when(mockGamification.getTotalXp()).thenAnswer((_) async => 0);
    when(mockDeepSeek.askQuestion(any)).thenAnswer((_) async => 'No response');

    when(mockUserRepo.isTestWeekCompleted(any)).thenAnswer((_) async => false);
    when(mockUserRepo.getAiPlans(any)).thenAnswer((_) async => {});
    when(mockSettingsRepo.getManualHeartRate(any)).thenAnswer((_) async => 0);

    GetIt.instance.registerLazySingleton<AuthBloc>(
      () => AuthBloc(authRepository: mockAuthRepo),
    );
    GetIt.instance.registerLazySingleton<AiBloc>(
      () => AiBloc(aiService: mockDeepSeek),
    );
    GetIt.instance.registerLazySingleton<UserBloc>(
      () => UserBloc(userRepository: mockUserRepo),
    );
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('Golden: DashboardScreen', () {
    testWidgets('matches golden file', (tester) async {
      final authBloc = sl<AuthBloc>();
      final userBloc = sl<UserBloc>();
      final aiBloc = sl<AiBloc>();

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<UserBloc>.value(value: userBloc),
              BlocProvider<AiBloc>.value(value: aiBloc),
            ],
            child: const MaterialApp(
              home: DashboardScreen(),
              localizationsDelegates: [AppLocalizations.delegate],
              supportedLocales: [Locale('en'), Locale('ru')],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));

      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('goldens/dashboard.png'),
      );

      // Do NOT call authBloc/userBloc/aiBloc.close() here: BlocProvider.value
      // keeps an internal subscription on each bloc's state stream alive for
      // as long as the widget tree above is mounted. Bloc.close() awaits that
      // stream fully closing (which needs every listener cancelled first) —
      // since the tree is never unmounted, close() never returns and the
      // test hangs until the runner's timeout. GetIt.reset() in tearDownAll
      // is enough cleanup for a single-test file; there's nothing to close.
    });
  });
}
