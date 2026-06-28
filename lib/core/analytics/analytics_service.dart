import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';

class AnalyticsService implements IAnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  // ─── Screen tracking ─────────────────────────────────────────────

  @override
  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // ─── Authentication ───────────────────────────────────────────────

  @override
  Future<void> logLogin({required String method}) async {
    await _analytics.logEvent(name: 'login', parameters: {'method': method});
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  @override
  Future<void> logSignUp({required String method}) async {
    await _analytics.logEvent(name: 'sign_up', parameters: {'method': method});
  }

  @override
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  // ─── Workout events ───────────────────────────────────────────────

  @override
  Future<void> logWorkoutStarted({required String sessionId}) async {
    await _analytics.logEvent(
      name: 'workout_started',
      parameters: {'session_id': sessionId},
    );
  }

  @override
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

  @override
  Future<void> logWorkoutPaused({required String sessionId}) async {
    await _analytics.logEvent(
      name: 'workout_paused',
      parameters: {'session_id': sessionId},
    );
  }

  // ─── Onboarding events ────────────────────────────────────────────

  @override
  Future<void> logOnboardingStep({
    required int step,
    required String stepName,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_step',
      parameters: {'step': step, 'step_name': stepName},
    );
  }

  @override
  Future<void> logOnboardingCompleted({required String goal}) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {'goal': goal},
    );
  }

  // ─── Nutrition events ─────────────────────────────────────────────

  @override
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

  @override
  Future<void> logDeviceConnected({required String deviceName}) async {
    await _analytics.logEvent(
      name: 'device_connected',
      parameters: {'device_name': deviceName},
    );
  }

  @override
  Future<void> logHealthDataSynced({required String source}) async {
    await _analytics.logEvent(
      name: 'health_data_synced',
      parameters: {'source': source},
    );
  }

  // ─── General events ───────────────────────────────────────────────

  @override
  Future<void> logShare({required String contentType}) async {
    await _analytics.logEvent(
      name: 'share',
      parameters: {'content_type': contentType},
    );
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // ─── User properties ──────────────────────────────────────────────

  @override
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }
}
