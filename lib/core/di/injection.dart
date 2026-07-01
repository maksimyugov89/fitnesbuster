import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';
import 'package:fitnesbuster/bloc/workout/workout_bloc.dart';
import 'package:fitnesbuster/bloc/nutrition/nutrition_bloc.dart';
import 'package:fitnesbuster/bloc/health/health_bloc.dart';
import 'package:fitnesbuster/bloc/health/health_sync_bloc.dart';
import 'package:fitnesbuster/bloc/ai/ai_bloc.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/bloc/training/test_week_bloc.dart';
import 'package:fitnesbuster/data/repositories/auth_repository.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/core/notifications/notification_service.dart';
import 'package:fitnesbuster/domain/services/i_notification_service.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/core/ai/base_client.dart';
import 'package:fitnesbuster/core/ai/services/workout_plan_service.dart';
import 'package:fitnesbuster/core/ai/services/meal_plan_service.dart';
import 'package:fitnesbuster/core/ai/services/plan_refinement_service.dart';
import 'package:fitnesbuster/core/ai/services/progress_analyzer.dart';
import 'package:fitnesbuster/core/ai/services/chat_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/analytics/analytics_service.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/core/training/adaptive_training_service.dart';
import 'package:fitnesbuster/domain/services/i_adaptive_training_service.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/core/health/health_analytics_service.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/domain/services/i_health_analytics_service.dart';
import 'package:fitnesbuster/domain/services/i_health_service.dart';
import 'package:fitnesbuster/core/health/health_service_adapter.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:fitnesbuster/core/services/onboarding_workflow_service.dart';
import 'package:fitnesbuster/core/services/test_week_workflow_service.dart';
import 'package:fitnesbuster/domain/usecases/complete_test_week_use_case.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/nutrition_service.dart';
import 'package:fitnesbuster/domain/services/i_nutrition_service.dart';
import 'package:fitnesbuster/core/services/fcm_service.dart';
import 'package:fitnesbuster/core/services/workout_session.dart';
import 'package:fitnesbuster/domain/services/i_fcm_service.dart';
import 'package:fitnesbuster/data/repositories/pr_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_pr_repository.dart';
import 'package:fitnesbuster/data/repositories/settings_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/core/services/exercise_gif_service.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';
import 'package:fitnesbuster/core/cache/offline_queue.dart';

final sl = GetIt.instance;
StreamSubscription<fb.User?>? _authFcmSub;

Future<void> initDependencies() async {
  // Firebase
  sl.registerLazySingleton(() => fb.FirebaseAuth.instance);
  sl.registerLazySingleton(
    () => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'fitnesbuster',
    ),
  );

  // Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleWaterReminders();
  await notificationService.scheduleSmartWorkoutReminder();
  sl.registerLazySingleton<INotificationService>(() => notificationService);
  sl.registerLazySingleton<NotificationService>(() => notificationService);

  // AI — base client + decomposed services
  final baseClient = BaseClient();
  sl.registerLazySingleton<BaseClient>(() => baseClient);

  final workoutPlanService = WorkoutPlanService(baseClient);
  sl.registerLazySingleton<WorkoutPlanService>(() => workoutPlanService);

  final mealPlanService = MealPlanService(baseClient);
  sl.registerLazySingleton<MealPlanService>(() => mealPlanService);

  final planRefinementService = PlanRefinementService(
    baseClient,
    workoutPlanService,
  );
  sl.registerLazySingleton<PlanRefinementService>(() => planRefinementService);

  final progressAnalyzer = ProgressAnalyzer(baseClient);
  sl.registerLazySingleton<ProgressAnalyzer>(() => progressAnalyzer);

  final chatService = ChatService(baseClient);
  sl.registerLazySingleton<ChatService>(() => chatService);

  // Facade preserving backward compatibility
  final deepSeek = DeepSeekService(
    workoutPlan: workoutPlanService,
    mealPlan: mealPlanService,
    refinement: planRefinementService,
    progress: progressAnalyzer,
    chat: chatService,
  );
  sl.registerLazySingleton<IDeepSeekService>(() => deepSeek);
  sl.registerLazySingleton<DeepSeekService>(() => deepSeek);

  // Analytics
  final analytics = AnalyticsService();
  sl.registerLazySingleton<IAnalyticsService>(() => analytics);
  sl.registerLazySingleton<AnalyticsService>(() => analytics);

  // Training
  final adaptiveTraining = AdaptiveTrainingService(ai: sl());
  sl.registerLazySingleton<IAdaptiveTrainingService>(() => adaptiveTraining);
  sl.registerLazySingleton<AdaptiveTrainingService>(() => adaptiveTraining);

  // Health Connect
  final healthConnect = HealthConnectService();
  sl.registerLazySingleton<IHealthConnectService>(() => healthConnect);
  sl.registerLazySingleton<HealthConnectService>(() => healthConnect);

  // Health data analytics — aggregation helpers
  final healthAnalytics = HealthAnalyticsService();
  sl.registerLazySingleton<IHealthAnalyticsService>(() => healthAnalytics);
  sl.registerLazySingleton<HealthAnalyticsService>(() => healthAnalytics);

  // Health plugin adapter
  final healthServiceAdapter = HealthServiceAdapter();
  sl.registerLazySingleton<IHealthService>(() => healthServiceAdapter);

  // Social — same instance under both types (screens use concrete, tests use interface)
  final socialService = SocialService();
  sl.registerLazySingleton<ISocialService>(() => socialService);
  sl.registerLazySingleton<SocialService>(() => socialService);

  // FCM token init on sign-in — cancelled and recreated on each call to stay idempotent
  _authFcmSub?.cancel();
  _authFcmSub = fb.FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) sl<ISocialService>().initFcm();
  });

  // FCM deeplink routing
  final fcmService = FcmService();
  sl.registerLazySingleton<IFcmService>(() => fcmService);
  sl.registerLazySingleton<FcmService>(() => fcmService);
  await sl<IFcmService>().init();

  // Nutrition
  final nutritionService = NutritionService(ai: sl());
  sl.registerLazySingleton<INutritionService>(() => nutritionService);
  sl.registerLazySingleton<NutritionService>(() => nutritionService);

  // Repositories — registered against interfaces for testability.
  // Concrete types also registered for call sites that resolve the implementation directly.
  final authRepo = AuthRepository(auth: sl(), firestore: sl());
  sl.registerLazySingleton<IAuthRepository>(() => authRepo);
  sl.registerLazySingleton<AuthRepository>(() => authRepo);

  final userRepo = UserRepository(auth: sl(), firestore: sl());
  sl.registerLazySingleton<IUserRepository>(() => userRepo);
  sl.registerLazySingleton<UserRepository>(() => userRepo);

  final prRepo = PrRepository();
  sl.registerLazySingleton<IPrRepository>(() => prRepo);
  sl.registerLazySingleton<PrRepository>(() => prRepo);

  final settingsRepo = SettingsRepository();
  sl.registerLazySingleton<ISettingsRepository>(() => settingsRepo);
  sl.registerLazySingleton<SettingsRepository>(() => settingsRepo);

  final gamification = GamificationService(settings: settingsRepo);
  sl.registerLazySingleton<IGamificationService>(() => gamification);
  sl.registerLazySingleton<GamificationService>(() => gamification);

  sl.registerLazySingleton<WorkoutSession>(() => WorkoutSession());

  final exerciseService = ExerciseGifService();
  sl.registerLazySingleton<IExerciseService>(() => exerciseService);
  sl.registerLazySingleton<ExerciseGifService>(() => exerciseService);

  // Offline queue
  final offlineQueue = OfflineQueue();
  await offlineQueue.init();
  sl.registerLazySingleton<OfflineQueue>(() => offlineQueue);

  // Onboarding workflow
  final onboardingWorkflow = OnboardingWorkflowService(
    aiService: sl(),
    userRepo: sl(),
  );
  sl.registerLazySingleton<OnboardingWorkflowService>(() => onboardingWorkflow);

  // Test week workflow
  final testWeekWorkflow = TestWeekWorkflowService(trainingService: sl());
  sl.registerLazySingleton<TestWeekWorkflowService>(() => testWeekWorkflow);

  // Use cases
  final completeTestWeekUseCase = CompleteTestWeekUseCase(
    authRepo: sl(),
    userRepo: sl(),
    aiService: sl(),
  );
  sl.registerLazySingleton<CompleteTestWeekUseCase>(
    () => completeTestWeekUseCase,
  );

  // Blocs
  // AuthBloc must be a singleton: AuthRouterNotifier, the widget-tree
  // BlocProvider, and dashboard_screen.dart all resolve it independently via
  // sl<AuthBloc>() — with registerFactory each call created a separate
  // instance, so events dispatched from one screen (e.g. email verification
  // checks) never reached the router's listener, leaving the UI stuck until
  // a full app restart re-synced everything from scratch.
  sl.registerLazySingleton(
    () => AuthBloc(authRepository: sl<IAuthRepository>()),
  );
  sl.registerFactory(() => UserBloc(userRepository: sl<IUserRepository>()));
  sl.registerFactory(() => WorkoutBloc());
  sl.registerFactory(() => NutritionBloc(nutritionService: sl()));
  sl.registerFactory(
    () => HealthBloc(
      healthService: sl<IHealthService>(),
      analytics: sl<IHealthAnalyticsService>(),
    ),
  );
  sl.registerFactory(
    () => HealthSyncBloc(hcService: sl<IHealthConnectService>()),
  );
  sl.registerFactory(() => AiBloc(aiService: sl()));
  sl.registerFactory(
    () => OnboardingBloc(
      userRepo: sl(),
      workflowService: sl<OnboardingWorkflowService>(),
      authRepo: sl<IAuthRepository>(),
    ),
  );
  sl.registerFactory(
    () => TestWeekBloc(workflowService: sl(), completeTestWeekUseCase: sl()),
  );
}

void disposeDependencies() {
  _authFcmSub?.cancel();
  _authFcmSub = null;
  sl.reset();
}
