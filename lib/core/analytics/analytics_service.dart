import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized Firebase Analytics service.
/// Logs user interactions across the app for product analytics.
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  // ─── Screen tracking ─────────────────────────────────────────────

  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // ─── Authentication ───────────────────────────────────────────────

  Future<void> logLogin({required String method}) async {
    await _analytics.logEvent(name: 'login', parameters: {'method': method});
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logEvent(name: 'sign_up', parameters: {'method': method});
  }

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  // ─── Workout events ───────────────────────────────────────────────

  Future<void> logWorkoutStarted({required String sessionId}) async {
    await _analytics.logEvent(
      name: 'workout_started',
      parameters: {'session_id': sessionId},
    );
  }

  Future<void> logWorkoutCompleted({
    required String sessionId,
    required int durationSeconds,
    required int exercisesCompleted,
  }) async {
    await _analytics.logEvent(
      name: 'workout_completed',
      parameters: {
        'session_id': sessionId,
        'duration_seconds': durationSeconds,
        'exercises_completed': exercisesCompleted,
      },
    );
  }

  Future<void> logWorkoutPaused({required String sessionId}) async {
    await _analytics.logEvent(
      name: 'workout_paused',
      parameters: {'session_id': sessionId},
    );
  }

  // ─── Onboarding events ────────────────────────────────────────────

  Future<void> logOnboardingStep({
    required int step,
    required String stepName,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_step',
      parameters: {'step': step, 'step_name': stepName},
    );
  }

  Future<void> logOnboardingCompleted({required String goal}) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {'goal': goal},
    );
  }

  // ─── Nutrition events ─────────────────────────────────────────────

  Future<void> logFoodLogged({
    required String foodName,
    required double calories,
    required String mealType,
  }) async {
    await _analytics.logEvent(
      name: 'food_logged',
      parameters: {
        'food_name': foodName,
        'calories': calories,
        'meal_type': mealType,
      },
    );
  }

  // ─── Health / BLE events ──────────────────────────────────────────

  Future<void> logDeviceConnected({required String deviceName}) async {
    await _analytics.logEvent(
      name: 'device_connected',
      parameters: {'device_name': deviceName},
    );
  }

  Future<void> logHealthDataSynced({required String source}) async {
    await _analytics.logEvent(
      name: 'health_data_synced',
      parameters: {'source': source},
    );
  }

  // ─── General events ───────────────────────────────────────────────

  Future<void> logShare({required String contentType}) async {
    await _analytics.logEvent(
      name: 'share',
      parameters: {'content_type': contentType},
    );
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // ─── User properties ──────────────────────────────────────────────

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }
}
