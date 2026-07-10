import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

enum PermissionRationaleKind { camera, photos, notifications }

Future<bool> showPermissionRationaleDialog(
  BuildContext context,
  PermissionRationaleKind kind,
) async {
  final colors = AppTheme.of(context);
  final (title, body) = switch (kind) {
    PermissionRationaleKind.camera => (
      AppLocalizations.tl('permissionCameraTitle'),
      AppLocalizations.tl('permissionCameraBody'),
    ),
    PermissionRationaleKind.photos => (
      AppLocalizations.tl('permissionPhotosTitle'),
      AppLocalizations.tl('permissionPhotosBody'),
    ),
    PermissionRationaleKind.notifications => (
      AppLocalizations.tl('permissionNotificationsTitle'),
      AppLocalizations.tl('permissionNotificationsBody'),
    ),
  };

  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppLocalizations.tl('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.primary),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AppLocalizations.tl('continueLabel')),
            ),
          ],
        ),
      ) ??
      false;
}
