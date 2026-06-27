import 'package:firebase_analytics/firebase_analytics.dart';

abstract interface class IAnalyticsService {
  FirebaseAnalyticsObserver get observer;

  Future<void> logScreenView({required String screenName});
  Future<void> logLogin({required String method});
  Future<void> logSignUp({required String method});
  Future<void> setUserId(String? userId);
  Future<void> logWorkoutStarted({required String sessionId});
  Future<void> logWorkoutCompleted({
    required String sessionId,
    required int durationSeconds,
    required int exercisesCompleted,
  });
  Future<void> logWorkoutPaused({required String sessionId});
  Future<void> logOnboardingStep({required int step, required String stepName});
  Future<void> logOnboardingCompleted({required String goal});
  Future<void> logFoodLogged({
    required String foodName,
    required double calories,
    required String mealType,
  });
  Future<void> logDeviceConnected({required String deviceName});
  Future<void> logHealthDataSynced({required String source});
  Future<void> logShare({required String contentType});
  Future<void> logEvent({required String name, Map<String, Object>? parameters});
  Future<void> setUserProperty({required String name, required String value});
  Future<void> setAnalyticsEnabled(bool enabled);
}
