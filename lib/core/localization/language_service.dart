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

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.russian,
    );
  }
}

/// Manages app language preference using SharedPreferences.
class LanguageService {
  static const String _key = 'app_language';
  static final AppLanguage _default = AppLanguage.russian;

  static AppLanguage _current = _default;

  static AppLanguage get current => _current;
  static bool get isInitialized => _current != _default;

  /// Load saved language from SharedPreferences.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? _default.code;
    _current = AppLanguage.fromCode(code);
  }

  /// Save selected language to SharedPreferences.
  static Future<void> setLanguage(AppLanguage language) async {
    _current = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.code);
  }
}
