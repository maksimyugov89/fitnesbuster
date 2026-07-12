import 'package:fitnesbuster/presentation/widgets/profile/profile_edit_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProfileEditSheet renders name field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileEditSheet(
            name: 'Alice',
            email: 'alice@example.com',
            avatarPresetIndex: 0,
            avatarCustomPath: '',
            onSave: (_, _) {},
            onAvatarTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Alice'), findsOne);
  });

  testWidgets('BodyParamsSheet renders chest/waist/hips measurement fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BodyParamsSheet(
            weight: 70,
            fetchLatestMeasurement: () async => null,
            onSave: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Грудь (см)'), findsOne);
    expect(find.text('Талия (см)'), findsOne);
    expect(find.text('Бёдра (см)'), findsOne);
  });

  testWidgets(
    'NotificationsSheet keeps settings open and offers recovery when denied',
    (tester) async {
      var permissionRequests = 0;
      var settingsOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationsSheet(
              onRequestPermission: () async {
                permissionRequests++;
                return false;
              },
              onOpenSettings: () async {
                settingsOpened = true;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();

      expect(permissionRequests, 1);
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Сохранить'), findsOneWidget);

      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();
      expect(settingsOpened, isTrue);
      expect(find.text('Сохранить'), findsOneWidget);
    },
  );
}
