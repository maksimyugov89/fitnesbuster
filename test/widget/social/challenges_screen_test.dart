import 'dart:async';

import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/presentation/screens/social/challenges_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'challenges_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ISocialService>(), MockSpec<AuthBloc>()])
void main() {
  late MockISocialService mockSocial;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    provideDummy<AuthState>(const AuthStateInitial());
  });

  setUp(() {
    mockSocial = MockISocialService();
    mockAuthBloc = MockAuthBloc();
    when(mockAuthBloc.state).thenReturn(const AuthStateInitial());
    when(
      mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(const AuthStateInitial()));
    if (sl.isRegistered<ISocialService>()) {
      sl.unregister<ISocialService>();
    }
    sl.registerSingleton<ISocialService>(mockSocial);
  });

  tearDown(() {
    sl.unregister<ISocialService>();
  });

  Future<void> pumpChallenges(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const ChallengesScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows empty state when my challenges are empty', (tester) async {
    when(
      mockSocial.myChallengesStream(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      mockSocial.publicChallengesStream(),
    ).thenAnswer((_) => Stream.value(const []));

    await pumpChallenges(tester);
    await tester.pumpAndSettle();

    expect(find.text('Нет активных челленджей'), findsOne);
  });

  testWidgets('renders my challenges when present', (tester) async {
    final challenge = Challenge(
      id: 'ch1',
      title: 'Monthly Run',
      description: 'Run everyday',
      goalType: 'workout_count',
      targetValue: 30,
      durationDays: 30,
      isPublic: false,
      isPredefined: false,
      createdBy: 'u1',
      creatorName: 'Me',
      participants: ['u1'],
      startDate: DateTime(2025, 7, 1),
      endDate: DateTime(2025, 7, 31),
      emoji: '\u{1F3C3}',
    );
    when(
      mockSocial.myChallengesStream(),
    ).thenAnswer((_) => Stream.value([challenge]));
    when(
      mockSocial.publicChallengesStream(),
    ).thenAnswer((_) => Stream.value(const []));

    await pumpChallenges(tester);
    await tester.pumpAndSettle();

    expect(find.text('Monthly Run'), findsOne);
  });

  testWidgets('shows empty state when public challenges are empty', (
    tester,
  ) async {
    when(
      mockSocial.myChallengesStream(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      mockSocial.publicChallengesStream(),
    ).thenAnswer((_) => Stream.value(const []));

    await pumpChallenges(tester);
    await tester.pumpAndSettle();

    // Switch to public tab
    await tester.tap(find.text('Публичные'));
    await tester.pumpAndSettle();

    // Should show empty state for public challenges
    expect(find.text('Нет публичных челленджей'), findsOne);
  });
}
