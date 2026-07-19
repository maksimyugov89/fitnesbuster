import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'profile_setup_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<OnboardingBloc>()])
void main() {
  late MockOnboardingBloc mockBloc;

  setUpAll(() {
    provideDummy<OnboardingState>(const OnboardingCollecting());
  });

  setUp(() {
    mockBloc = MockOnboardingBloc();
    when(mockBloc.state).thenReturn(const OnboardingCollecting());
    when(
      mockBloc.stream,
    ).thenAnswer((_) => const Stream<OnboardingState>.empty());
  });

  testWidgets('renders first page without crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<OnboardingBloc>.value(
          value: mockBloc,
          child: const ProfileSetupScreen(),
        ),
      ),
    );
    // pump() is enough — AnimationController means pumpAndSettle would time out
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // First page has a name TextField and the "Далее" button
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(ElevatedButton), findsOne);
  });

  testWidgets('renders loading overlay for GeneratingPlan state', (
    tester,
  ) async {
    when(mockBloc.state).thenReturn(const OnboardingGeneratingPlan());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<OnboardingBloc>.value(
          value: mockBloc,
          child: const ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Loading overlay with CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOne);
  });
}
