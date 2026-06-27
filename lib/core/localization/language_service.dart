import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported language with display name, native name and flag emoji.
enum AppLanguage {
  russian('Русский', 'Русский', '🇷🇺', 'ru'),
  english('English', 'English', '🇬🇧', 'en'),
  spanish('Español', 'Spanish', '🇪🇸', 'es'),
  german('Deutsch', 'German', '🇩🇪', 'de'),
  french('Français', 'French', '🇫🇷', 'fr'),
  italian('Italiano', 'Italian', '🇮🇹', 'it'),
  portuguese('Português', 'Portuguese', '🇵🇹', 'pt'),
  turkish('Türkçe', 'Turkish', '🇹🇷', 'tr'),
  arabic('العربية', 'Arabic', '🇸🇦', 'ar'),
  chinese('中文', 'Chinese', '🇨🇳', 'zh'),
  japanese('日本語', 'Japanese', '🇯🇵', 'ja'),
  korean('한국어', 'Korean', '🇰🇷', 'ko'),
  hindi('हिन्दी', 'Hindi', '🇮🇳', 'hi'),
  ukrainian('Українська', 'Ukrainian', '🇺🇦', 'uk'),
  belarusian('Беларуская', 'Belarusian', '🇧🇾', 'be'),
  ;

  final String nativeName;
  final String englishName;
  final String flag;
  final String code;

  const AppLanguage(this.nativeName, this.englishName, this.flag, this.code);

  Locale get locale => Locale(code);

  bool get isRtl => code == 'ar';

  static AppLanguage fromCode(String code) => AppLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.russian,
      );
}

/// Manages app language preference. Exposes [localeNotifier] for reactive
/// MaterialApp.locale binding and triggers full UI rebuild on change.
class LanguageService {
  static const String _key = 'app_language';

  static AppLanguage _current = AppLanguage.russian;
  static AppLanguage get current => _current;

  /// Reactive locale — bind to MaterialApp.locale.
  static final localeNotifier = ValueNotifier<Locale>(AppLanguage.russian.locale);

  /// Load saved language from SharedPreferences.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? AppLanguage.russian.code;
    _current = AppLanguage.fromCode(code);
    localeNotifier.value = _current.locale;
  }

  /// Save selected language and trigger UI rebuild across the app.
  static Future<void> setLanguage(AppLanguage language) async {
    _current = language;
    localeNotifier.value = language.locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.code);
  }
}
