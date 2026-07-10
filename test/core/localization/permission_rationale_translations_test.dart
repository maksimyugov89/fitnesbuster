import 'package:fitnesbuster/core/localization/translations/all_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every supported locale has all permission rationale strings', () {
    const keys = {
      'permissionCameraTitle',
      'permissionCameraBody',
      'permissionPhotosTitle',
      'permissionPhotosBody',
      'permissionNotificationsTitle',
      'permissionNotificationsBody',
    };

    for (final locale in allTranslations.entries) {
      for (final key in keys) {
        expect(
          locale.value[key],
          isNotEmpty,
          reason: 'Missing $key for ${locale.key}',
        );
      }
    }
  });
}
