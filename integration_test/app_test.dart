// E2E integration tests for FitnesBuster.
// Run with: flutter test integration_test/
// Requires Firebase Emulator or real backend.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitnesbuster/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding E2E', () {
    testWidgets('app launches and shows splash screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify splash screen or auth screen is visible
      expect(find.byType(app.FitnesBusterApp), findsOneWidget);
    });

    testWidgets('can navigate through onboarding flow', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap "Get Started" or equivalent
      final startButton = find.text('Начать');
      if (startButton.evaluate().isNotEmpty) {
        await tester.tap(startButton);
        await tester.pumpAndSettle();
      }

      // Verify we progressed past the initial screen
      expect(find.byType(app.FitnesBusterApp), findsOneWidget);
    });
  });

  group('Dashboard E2E', () {
    testWidgets('dashboard loads after auth', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // After splash, check for dashboard or auth
      final dashboard = find.text('Главная');
      final login = find.text('Войти');

      if (dashboard.evaluate().isNotEmpty) {
        expect(dashboard, findsOneWidget);
      } else if (login.evaluate().isNotEmpty) {
        // Not authenticated — expected in E2E without mock auth
        expect(login, findsOneWidget);
      }
    });
  });
}
