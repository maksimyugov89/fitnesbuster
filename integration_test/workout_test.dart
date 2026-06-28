// E2E integration tests — Workout execution flow (P2-05)
// Run with: flutter test integration_test/
// ignore_for_file: argument_type_not_assignable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';

import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/bloc/workout/workout_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart' hide WorkoutDay;
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_plan_screen.dart';

import 'workout_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockIAuthRepository mockAuthRepo;
  late MockIUserRepository mockUserRepo;
  late MockISettingsRepository mockSettingsRepo;
  late MockIExerciseService mockExerciseService;

  final testUser = UserEntity(
    id: 'test-uid',
    name: 'Test User',
    email: 'test@example.com',
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

    when(mockSettingsRepo.getWorkoutDone(any)).thenAnswer((_) async => false);
    when(mockSettingsRepo.getWorkoutKcal(any)).thenAnswer((_) async => 0);

    when(mockExerciseService.init()).thenAnswer((_) async {});
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('P2-05: Workout Execution Flow', () {
    group('WorkoutBloc state machine', () {
      testWidgets('WorkoutBloc starts in WorkoutStateInitial', (tester) async {
        final bloc = WorkoutBloc();
        expect(bloc.state, const WorkoutStateInitial());
        await bloc.close();
      });

      testWidgets('Start request transitions to WorkoutStateInProgress',
          (tester) async {
        final bloc = WorkoutBloc();
        const session = WorkoutSession(
          id: 'session-1',
          title: 'Chest Day',
          primaryMuscle: MuscleGroup.chest,
          exercises: [],
          estimatedDurationMinutes: 45,
          estimatedCaloriesBurn: 300,
          difficulty: DifficultyLevel.intermediate,
        );

        bloc.add(const WorkoutStartRequested(session: session));
        await tester.pump(Duration.zero);

        expect(bloc.state, isA<WorkoutStateInProgress>());
        final state = bloc.state as WorkoutStateInProgress;
        expect(state.currentExerciseIndex, 0);
        expect(state.session?.title, 'Chest Day');
        expect(state.isPaused, false);

        await bloc.close();
      });

      testWidgets('Pause and resume toggle isPaused correctly', (tester) async {
        final bloc = WorkoutBloc();

        bloc.add(const WorkoutStartRequested());
        await tester.pump(Duration.zero);

        bloc.add(const WorkoutPauseRequested());
        await tester.pump(Duration.zero);
        expect((bloc.state as WorkoutStateInProgress).isPaused, true);

        bloc.add(const WorkoutResumeRequested());
        await tester.pump(Duration.zero);
        expect((bloc.state as WorkoutStateInProgress).isPaused, false);

        await bloc.close();
      });

      testWidgets('Set completion appends to completedSets', (tester) async {
        final bloc = WorkoutBloc();

        bloc.add(const WorkoutStartRequested());
        await tester.pump(Duration.zero);

        bloc.add(const WorkoutSetCompleted(
          setLog: SetLog(setNumber: 1, reps: 10, completed: true),
        ));
        await tester.pump(Duration.zero);

        final state = bloc.state as WorkoutStateInProgress;
        expect(state.completedSets.length, 1);
        expect(state.completedSets.first.reps, 10);

        await bloc.close();
      });

      testWidgets('Exercise changed updates currentExerciseIndex',
          (tester) async {
        final bloc = WorkoutBloc();

        bloc.add(const WorkoutStartRequested());
        await tester.pump(Duration.zero);

        bloc.add(const WorkoutExerciseChanged(index: 2));
        await tester.pump(Duration.zero);

        expect(
          (bloc.state as WorkoutStateInProgress).currentExerciseIndex,
          2,
        );

        await bloc.close();
      });

      testWidgets('Stop with session emits WorkoutStateCompleted',
          (tester) async {
        final bloc = WorkoutBloc();
        const session = WorkoutSession(
          id: 'session-1',
          title: 'Test Session',
          primaryMuscle: MuscleGroup.chest,
          exercises: [],
          estimatedDurationMinutes: 30,
          estimatedCaloriesBurn: 200,
          difficulty: DifficultyLevel.beginner,
        );

        bloc.add(const WorkoutStartRequested(session: session));
        await tester.pump(Duration.zero);

        bloc.add(const WorkoutStopRequested());
        await tester.pump(Duration.zero);

        expect(bloc.state, isA<WorkoutStateCompleted>());
        expect(
          (bloc.state as WorkoutStateCompleted).sessionId,
          'session-1',
        );

        await bloc.close();
      });

      testWidgets('Stop without session emits WorkoutStateError',
          (tester) async {
        final bloc = WorkoutBloc();

        bloc.add(const WorkoutStartRequested());
        await tester.pump(Duration.zero);

        bloc.add(const WorkoutStopRequested());
        await tester.pump(Duration.zero);

        expect(bloc.state, isA<WorkoutStateError>());

        await bloc.close();
      });
    });

    group('WorkoutPlanScreen rendering', () {
      testWidgets('WorkoutPlanScreen renders without crashing',
          (tester) async {
        final authBloc = AuthBloc(authRepository: mockAuthRepo);
        when(mockAuthRepo.currentUser).thenReturn(testUser);

        await tester.pumpWidget(
          AppTheme(
            palette: ThemePalette.neon,
            child: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: const MaterialApp(home: WorkoutPlanScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(WorkoutPlanScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        await authBloc.close();
      });
    });
  });
}
