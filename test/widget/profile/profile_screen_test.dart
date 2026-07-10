import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileStatsRow', () {
    testWidgets('renders production weight, height, BMI, and age values', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileStatsRow(weight: 80, height: 175, age: 30),
          ),
        ),
      );

      expect(find.text('80.0'), findsOne);
      expect(find.text('175'), findsOne);
      expect(find.text('26.1'), findsOne);
      expect(find.text('30'), findsOne);
      expect(find.text('BMI'), findsOne);
    });

    testWidgets('shows dash for BMI when height is zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileStatsRow(weight: 70, height: 0, age: 25)),
        ),
      );

      expect(find.text('-'), findsOne);
    });
  });

  group('ProfileCurrentProgram', () {
    testWidgets('renders goal and completed profile hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCurrentProgram(goal: 'Похудение', dataLoaded: true),
          ),
        ),
      );

      expect(find.text('Похудение'), findsOne);
      expect(find.text(AppLocalizations.tl('fillProfileProgress')), findsOne);
    });

    testWidgets('hides completed profile hint while data is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCurrentProgram(goal: 'Набор массы', dataLoaded: false),
          ),
        ),
      );

      expect(find.text('Набор массы'), findsOne);
      expect(
        find.text(AppLocalizations.tl('fillProfileProgress')),
        findsNothing,
      );
    });
  });
}
