import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/common/permission_rationale_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('camera rationale continues only after explicit confirmation', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showPermissionRationaleDialog(
                context,
                PermissionRationaleKind.camera,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(AppLocalizations.tl('permissionCameraTitle')), findsOne);

    await tester.tap(find.text(AppLocalizations.tl('continueLabel')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('rationale cancellation returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showPermissionRationaleDialog(
                context,
                PermissionRationaleKind.photos,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppLocalizations.tl('cancel')));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
