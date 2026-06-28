import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/core/ai/base_client.dart';
import 'package:fitnesbuster/core/ai/services/workout_plan_service.dart';
import 'package:fitnesbuster/core/ai/services/meal_plan_service.dart';
import 'package:fitnesbuster/core/ai/services/plan_refinement_service.dart';
import 'package:fitnesbuster/core/ai/services/progress_analyzer.dart';
import 'package:fitnesbuster/core/ai/services/chat_service.dart';

void main() {
  late BaseClient client;

  setUp(() {
    client = BaseClient();
  });

  DeepSeekService makeSvc() {
    final workoutPlan = WorkoutPlanService(client);
    final mealPlan = MealPlanService(client);
    final refinement = PlanRefinementService(client, workoutPlan);
    final progress = ProgressAnalyzer(client);
    final chat = ChatService(client);
    return DeepSeekService(
      workoutPlan: workoutPlan,
      mealPlan: mealPlan,
      refinement: refinement,
      progress: progress,
      chat: chat,
    );
  }

  group('constructor', () {
    test('creates a valid DeepSeekService instance', () {
      final svc = makeSvc();
      expect(svc, isNotNull);
    });
  });

  // NOTE: HTTP-based tests removed — DeepSeekService now uses Cloud Functions proxy.
  // Cloud Function callable mocking requires FirebaseFunctions mocks (out of scope for this sprint).
  // Full integration tests should be added via Firebase Emulator or widget tests with mock callable.
}
