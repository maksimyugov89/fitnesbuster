import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/presentation/screens/workout/import_workout_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportOptionCard', () {
    testWidgets('renders production title/subtitle and handles tap', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportOptionCard(
              colors: ThemePalette.neon,
              icon: Icons.link,
              iconColor: Colors.green,
              title: 'URL',
              subtitle: 'Fetch from link',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('URL'), findsOne);
      expect(find.text('Fetch from link'), findsOne);
      await tester.tap(find.text('URL'));
      expect(tapped, isTrue);
    });

    testWidgets('renders custom trailing widget instead of arrow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportOptionCard(
              colors: ThemePalette.neon,
              icon: Icons.share,
              iconColor: Colors.blue,
              title: 'Share',
              subtitle: 'Automatic',
              trailing: const Text('AUTO'),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('AUTO'), findsOne);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
    });
  });

  group('ImportActionButton', () {
    testWidgets('calls callback when enabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportActionButton(
              colors: ThemePalette.neon,
              label: 'Save',
              icon: Icons.check,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });

    testWidgets('shows spinner and suppresses callback while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportActionButton(
              colors: ThemePalette.neon,
              label: 'Processing',
              loading: true,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOne);
      await tester.tap(find.text('Processing'));
      expect(taps, 0);
    });

    testWidgets('disabled button ignores taps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImportActionButton(
              colors: ThemePalette.neon,
              label: 'Disabled',
            ),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOne);
      expect(
        tester.widget<GestureDetector>(find.byType(GestureDetector)).onTap,
        isNull,
      );
    });
  });
}
