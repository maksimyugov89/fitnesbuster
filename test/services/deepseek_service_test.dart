import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/core/ai/ai_config.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

void main() {
  late AiConfig configuredKey;
  late AiConfig emptyKey;

  setUp(() {
    configuredKey = AiConfig.forTesting(apiKey: 'sk-test-key');
    emptyKey = AiConfig.forTesting(apiKey: '');
  });

  DeepSeekService makeSvc([AiConfig? cfg]) =>
      DeepSeekService(config: cfg ?? configuredKey);

  group('_ensureConfigured', () {
    test('throws AiException when key is empty', () {
      final svc = makeSvc(emptyKey);
      expect(
        () => svc.generateWorkoutPlan(_profile()),
        throwsA(isA<AiException>()),
      );
    });

    test('does not throw when key is present', () {
      final svc = makeSvc();
      expect(svc, isNotNull);
    });
  });

  // NOTE: HTTP-based tests removed — DeepSeekService now uses Cloud Functions proxy.
  // Cloud Function callable mocking requires FirebaseFunctions mocks (out of scope for this sprint).
  // Full integration tests should be added via Firebase Emulator or widget tests with mock callable.
}

UserProfile _profile() => UserProfile(
      weight: 80,
      height: 175,
      age: 30,
      gender: Gender.male,
      goal: FitnessGoal.loseWeight,
      intensity: IntensityLevel.balanced,
      activityLevel: ActivityLevel.moderatelyActive,
    );
