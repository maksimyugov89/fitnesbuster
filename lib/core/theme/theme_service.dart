import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' as app_theme;
import 'package:fitnesbuster/core/localization/app_localizations.dart';

/// Available app themes.
enum AppThemeMode {
  neonDark,
  oceanBlue,
  sunsetWarm,
  forestGreen,
  midnightPurple,
  cyberPunk;

  String get displayName => switch (this) {
    AppThemeMode.neonDark => AppLocalizations.tl('themeNeonName'),
    AppThemeMode.oceanBlue => AppLocalizations.tl('themeOceanName'),
    AppThemeMode.sunsetWarm => AppLocalizations.tl('themeSunsetName'),
    AppThemeMode.forestGreen => AppLocalizations.tl('themeForestName'),
    AppThemeMode.midnightPurple => AppLocalizations.tl('themePurpleName'),
    AppThemeMode.cyberPunk => AppLocalizations.tl('themeCyberName'),
  };

  String get emoji => switch (this) {
    AppThemeMode.neonDark => '⚡',
    AppThemeMode.oceanBlue => '🌊',
    AppThemeMode.sunsetWarm => '🌅',
    AppThemeMode.forestGreen => '🌿',
    AppThemeMode.midnightPurple => '🌙',
    AppThemeMode.cyberPunk => '🤖',
  };

  String get description => switch (this) {
    AppThemeMode.neonDark => AppLocalizations.tl('themeNeonDesc'),
    AppThemeMode.oceanBlue => AppLocalizations.tl('themeOceanDesc'),
    AppThemeMode.sunsetWarm => AppLocalizations.tl('themeSunsetDesc'),
    AppThemeMode.forestGreen => AppLocalizations.tl('themeForestDesc'),
    AppThemeMode.midnightPurple => AppLocalizations.tl('themePurpleDesc'),
    AppThemeMode.cyberPunk => AppLocalizations.tl('themeCyberDesc'),
  };
}

/// Manages app theme preference.
class ThemeService {
  static const String _key = 'app_theme';
  static const AppThemeMode _default = AppThemeMode.neonDark;

  static AppThemeMode _current = _default;
  static final ValueNotifier<AppThemeMode> notifier = ValueNotifier(_default);

  static AppThemeMode get current => _current;

  /// Load saved theme from SharedPreferences.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? _default.index;
    _current = AppThemeMode.values[index.clamp(0, AppThemeMode.values.length - 1)];
    notifier.value = _current;
  }

  /// Save selected theme to SharedPreferences.
  static Future<void> setTheme(AppThemeMode mode) async {
    _current = mode;
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  /// Get the ThemeData for the given mode (legacy — not used since dynamic theme switch).
  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.neonDark:
        return app_theme.AppTheme.darkTheme;
      case AppThemeMode.oceanBlue:
        return _oceanBlue;
      case AppThemeMode.sunsetWarm:
        return _sunsetWarm;
      case AppThemeMode.forestGreen:
        return _forestGreen;
      case AppThemeMode.midnightPurple:
        return _midnightPurple;
      case AppThemeMode.cyberPunk:
        return _cyberPunk;
    }
  }

  // ─── Deep Horizon (Ocean Blue) ─────────────────────────────────

  static final ThemeData _oceanBlue = app_theme.AppTheme.darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00CFFF),
      secondary: Color(0xFF67E8F9),
      surface: Color(0xFF061B2B),
      error: Color(0xFFF87171),
      onPrimary: Color(0xFF020C16),
      onSecondary: Color(0xFF020C16),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF020C16),
    cardTheme: CardThemeData(
      color: const Color(0xFF0A2035),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ─── Aurora Flame (Sunset Warm) ─────────────────────────────────

  static final ThemeData _sunsetWarm = app_theme.AppTheme.darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF4D1A),
      secondary: Color(0xFFFFB020),
      surface: Color(0xFF180906),
      error: Color(0xFFFF1744),
      onPrimary: Color(0xFF0C0403),
      onSecondary: Color(0xFF0C0403),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0C0403),
    cardTheme: CardThemeData(
      color: const Color(0xFF200C07),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ─── Jade Matrix (Forest Green) ─────────────────────────────────

  static final ThemeData _forestGreen = app_theme.AppTheme.darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00D46A),
      secondary: Color(0xFF00F5C8),
      surface: Color(0xFF061408),
      error: Color(0xFFEF4444),
      onPrimary: Color(0xFF020A03),
      onSecondary: Color(0xFF020A03),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF020A03),
    cardTheme: CardThemeData(
      color: const Color(0xFF091A0B),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ─── Nebula (Midnight Purple) ───────────────────────────────────

  static final ThemeData _midnightPurple = app_theme.AppTheme.darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFA855F7),
      secondary: Color(0xFFF472B6),
      surface: Color(0xFF0C0620),
      error: Color(0xFFF87171),
      onPrimary: Color(0xFF04020A),
      onSecondary: Color(0xFF04020A),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF04020A),
    cardTheme: CardThemeData(
      color: const Color(0xFF110828),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ─── Neon Tokyo (CyberPunk) ─────────────────────────────────────

  static final ThemeData _cyberPunk = app_theme.AppTheme.darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00F5FF),
      secondary: Color(0xFFFF0080),
      surface: Color(0xFF07071A),
      error: Color(0xFFFF004D),
      onPrimary: Color(0xFF02020A),
      onSecondary: Color(0xFF02020A),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF02020A),
    cardTheme: CardThemeData(
      color: const Color(0xFF0C0C24),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
