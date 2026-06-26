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
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/analytics/analytics_service.dart';
import 'package:fitnesbuster/core/training/adaptive_training_service.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/nutrition_service.dart';
import 'package:fitnesbuster/core/services/fcm_service.dart';
import 'package:fitnesbuster/data/repositories/pr_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_pr_repository.dart';
import 'package:fitnesbuster/data/repositories/settings_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/core/services/exercise_gif_service.dart';

final sl = GetIt.instance;
StreamSubscription<fb.User?>? _authFcmSub;

Future<void> initDependencies() async {
  // Firebase
  sl.registerLazySingleton(() => fb.FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'fitnesbuster'));

  // Services
  final notificationService = NotificationService();
  await notificationService.initialize();
  // Water reminders at fixed hours; workout reminder auto-adjusts to usage pattern
  await notificationService.scheduleWaterReminders();
  await notificationService.scheduleSmartWorkoutReminder();
  sl.registerLazySingleton(() => notificationService);

  // AI — same instance under both the interface and concrete type.
  // Blocs/services depend on IDeepSeekService; screens use sl<DeepSeekService>().
  final deepSeek = DeepSeekService();
  sl.registerLazySingleton<IDeepSeekService>(() => deepSeek);
  sl.registerLazySingleton<DeepSeekService>(() => deepSeek);

  // Analytics
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // Training
  sl.registerLazySingleton<AdaptiveTrainingService>(
    () => AdaptiveTrainingService(ai: sl()),
  );

  // Health Connect
  sl.registerLazySingleton<HealthConnectService>(() => HealthConnectService());

  // Social — same instance under both types (screens use concrete, tests use interface)
  final socialService = SocialService();
  sl.registerLazySingleton<ISocialService>(() => socialService);
  sl.registerLazySingleton<SocialService>(() => socialService);

  // FCM token init on sign-in; subscription stored for clean disposal
  _authFcmSub = fb.FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) sl<SocialService>().initFcm();
  });

  // FCM deeplink routing
  sl.registerLazySingleton<FcmService>(() => FcmService());
  await sl<FcmService>().init();

  // Nutrition — encapsulates DeepSeekService + regeneration policy
  sl.registerLazySingleton<NutritionService>(
    () => NutritionService(ai: sl()),
  );

  // Repositories — registered against interfaces for testability.
  // Concrete types are also registered for call sites that resolve the
  // implementation directly (e.g. AuthRepository.updateProfile).
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
  sl.registerLazySingleton<ExerciseGifService>(() => ExerciseGifService());

  // Blocs
  sl.registerFactory(() => AuthBloc(authRepository: sl<IAuthRepository>()));
  sl.registerFactory(() => UserBloc(userRepository: sl<IUserRepository>()));
  sl.registerFactory(() => WorkoutBloc());
  sl.registerFactory(() => NutritionBloc(nutritionService: sl()));
  sl.registerFactory(() => HealthBloc());
  sl.registerFactory(() => HealthSyncBloc(hcService: sl()));
  sl.registerFactory(() => AiBloc(aiService: sl()));
  sl.registerFactory(() => OnboardingBloc(userRepo: sl(), aiService: sl()));
  sl.registerFactory(() => TestWeekBloc(
    trainingService: sl(),
    aiService: sl(),
    userRepo: sl(),
  ));
}

void disposeDependencies() {
  _authFcmSub?.cancel();
  _authFcmSub = null;
  sl.reset();
}
