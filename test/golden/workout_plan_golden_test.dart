// Golden test for WorkoutPlanScreen (P2-06)
// Run: flutter test --update-goldens test/golden/workout_plan_golden_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';

import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_plan_screen.dart';

import 'workout_plan_golden_test.mocks.dart';

@GenerateMocks([
  IAuthRepository,
  IUserRepository,
  ISettingsRepository,
  IExerciseService,
])
void main() {
  late MockIAuthRepository mockAuthRepo;
  late MockIUserRepository mockUserRepo;
  late MockISettingsRepository mockSettingsRepo;
  late MockIExerciseService mockExerciseService;

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
    mockExerciseService = MockIExerciseService();

    if (GetIt.instance.isRegistered<IAuthRepository>()) {
      GetIt.instance.unregister<IAuthRepository>();
    }
    if (GetIt.instance.isRegistered<IUserRepository>()) {
      GetIt.instance.unregister<IUserRepository>();
    }
    if (GetIt.instance.isRegistered<ISettingsRepository>()) {
      GetIt.instance.unregister<ISettingsRepository>();
    }
    if (GetIt.instance.isRegistered<IExerciseService>()) {
      GetIt.instance.unregister<IExerciseService>();
    }

    GetIt.instance.registerLazySingleton<IAuthRepository>(() => mockAuthRepo);
    GetIt.instance.registerLazySingleton<IUserRepository>(() => mockUserRepo);
    GetIt.instance.registerLazySingleton<ISettingsRepository>(() => mockSettingsRepo);
    GetIt.instance.registerLazySingleton<IExerciseService>(() => mockExerciseService);

    when(mockAuthRepo.currentUser).thenReturn(testUser);
    when(mockAuthRepo.userChanges).thenAnswer((_) => Stream.value(testUser));

    when(mockUserRepo.getAiPlans(any)).thenAnswer((_) async => {});
    when(mockUserRepo.isTestWeekCompleted(any)).thenAnswer((_) async => true);

    when(mockSettingsRepo.getWorkoutDone(any)).thenAnswer((_) async => false);

    when(mockExerciseService.init()).thenAnswer((_) async {});
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('Golden: WorkoutPlanScreen', () {
    testWidgets('matches golden file — loading state', (tester) async {
      final authBloc = AuthBloc(authRepository: mockAuthRepo);

      await tester.pumpWidget(
        AppTheme(
          palette: ThemePalette.neon,
          child: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const MaterialApp(
              home: WorkoutPlanScreen(),
              localizationsDelegates: [
                AppLocalizations.delegate,
              ],
              supportedLocales: [Locale('en'), Locale('ru')],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(WorkoutPlanScreen),
        matchesGoldenFile('goldens/workout_plan.png'),
      );

      await authBloc.close();
    });
  });
}
