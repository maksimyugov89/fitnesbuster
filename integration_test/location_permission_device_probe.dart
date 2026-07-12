import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import '../test/widget/onboarding/profile_setup_screen_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real Android location permission probe', (tester) async {
    provideDummy<OnboardingState>(const OnboardingCollecting());
    final bloc = MockOnboardingBloc();
    when(bloc.state).thenReturn(const OnboardingCollecting());
    when(bloc.stream).thenAnswer((_) => const Stream<OnboardingState>.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<OnboardingBloc>.value(
          value: bloc,
          child: const ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    for (var page = 0; page < 5; page++) {
      expect(find.text('${page + 1} of 6'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
    }

    expect(find.text('6 of 6'), findsOneWidget);
    // ADB drives only Android's native permission and Settings screens.
    // ignore: avoid_print
    print('LOCATION_PROBE_READY');
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    // ignore: avoid_print
    print('LOCATION_PROMPT_1');
    await Future<void>.delayed(const Duration(seconds: 30));
    await tester.pump();

    expect(
      find.text('Доступ к геолокации запрещён. Введите город вручную.'),
      findsOneWidget,
    );
    expect(find.text('Настройки'), findsOneWidget);
    // ignore: avoid_print
    print('LOCATION_SETTINGS_READY');
    await tester.tap(find.text('Настройки'));
    await tester.pump();
    // ignore: avoid_print
    print('LOCATION_SETTINGS_OPENED');
    await Future<void>.delayed(const Duration(seconds: 60));
    await tester.pump();

    final permission = await Geolocator.checkPermission();
    expect(
      permission,
      anyOf(LocationPermission.whileInUse, LocationPermission.always),
    );
    // ignore: avoid_print
    print('LOCATION_SETTINGS_RECOVERY_PASS:$permission');
  });
}
