import 'package:fitnesbuster/presentation/screens/nutrition/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('camera lockout offers app settings recovery', (tester) async {
    var settingsOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BarcodeScannerScreen(
          requestCameraPermission: () async =>
              PermissionStatus.permanentlyDenied,
          checkCameraPermission: () async => PermissionStatus.permanentlyDenied,
          openPermissionSettings: () async {
            settingsOpened = true;
            return true;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(settingsOpened, isTrue);
  });
}
