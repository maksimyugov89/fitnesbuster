import 'package:fitnesbuster/core/localization/translations/all_translations.dart';
import 'package:flutter_test/flutter_test.dart';

final _placeholderPattern = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}');

Set<String> _placeholders(String value) => _placeholderPattern
    .allMatches(value)
    .map((match) => match.group(1)!)
    .toSet();

void main() {
  test('every supported locale has complete, compatible translations', () {
    final english = allTranslations['en']!;

    for (final entry in allTranslations.entries) {
      final locale = entry.key;
      final translations = entry.value;

      expect(
        translations.keys.toSet().difference(english.keys.toSet()),
        isEmpty,
        reason: '$locale has keys that are absent from the English source map',
      );
      expect(
        english.keys.toSet().difference(translations.keys.toSet()),
        isEmpty,
        reason: '$locale is missing translation keys',
      );

      for (final key in english.keys) {
        final translated = translations[key]!;
        expect(translated.trim(), isNotEmpty, reason: '$locale.$key is empty');
        expect(
          _placeholders(translated),
          _placeholders(english[key]!),
          reason: '$locale.$key has incompatible placeholders',
        );
      }
    }
  });
}
