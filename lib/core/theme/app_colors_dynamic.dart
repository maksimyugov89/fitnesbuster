import 'package:flutter/material.dart';

extension ThemeColorsX on BuildContext {
  AppColors get colors => AppColors.of(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get scheme => theme.colorScheme;
}

/// Dynamic color palette that switches with theme.
/// Mirrors ThemePalette exactly — kept for legacy screen compatibility.
class AppColors {
  final Color primary, primaryDark, primaryLight;
  final Color accent, accentOrange, accentPurple;
  final Color background, surface, surfaceLight, surfaceCard, elevated;
  final Color textPrimary, textSecondary, textMuted, textOnPrimary;
  final Color success, warning, error, info;

  const AppColors._({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.accentOrange,
    required this.accentPurple,
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceCard,
    required this.elevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  // Electric Volt (neon dark default)
  static const neon = AppColors._(
    primary: Color(0xFFC8FF00),
    primaryDark: Color(0xFF96CC00),
    primaryLight: Color(0xFFDCFF4D),
    accent: Color(0xFF00E5CC),
    accentOrange: Color(0xFFFF5500),
    accentPurple: Color(0xFF8B5CF6),
    background: Color(0xFF070809),
    surface: Color(0xFF0E1012),
    surfaceLight: Color(0xFF1C2025),
    surfaceCard: Color(0xFF131619),
    elevated: Color(0xFF242A30),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B8C1),
    textMuted: Color(0xFF5A6370),
    textOnPrimary: Color(0xFF080808),
    success: Color(0xFF22D3A5),
    warning: Color(0xFFF5A623),
    error: Color(0xFFFF4466),
    info: Color(0xFF38BDF8),
  );

  // Deep Horizon (ocean blue)
  static const ocean = AppColors._(
    primary: Color(0xFF00CFFF),
    primaryDark: Color(0xFF009ABB),
    primaryLight: Color(0xFF4DDCFF),
    accent: Color(0xFF67E8F9),
    accentOrange: Color(0xFFFF7043),
    accentPurple: Color(0xFF818CF8),
    background: Color(0xFF020C16),
    surface: Color(0xFF061B2B),
    surfaceLight: Color(0xFF0F2B43),
    surfaceCard: Color(0xFF0A2035),
    elevated: Color(0xFF153250),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF90B4CE),
    textMuted: Color(0xFF4A6B84),
    textOnPrimary: Color(0xFF020C16),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
  );

  // Aurora Flame (sunset)
  static const sunset = AppColors._(
    primary: Color(0xFFFF4D1A),
    primaryDark: Color(0xFFCC2900),
    primaryLight: Color(0xFFFF7040),
    accent: Color(0xFFFFB020),
    accentOrange: Color(0xFFFF4D1A),
    accentPurple: Color(0xFFD946EF),
    background: Color(0xFF0C0403),
    surface: Color(0xFF180906),
    surfaceLight: Color(0xFF2C120C),
    surfaceCard: Color(0xFF200C07),
    elevated: Color(0xFF391813),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC4907A),
    textMuted: Color(0xFF6B3A2A),
    textOnPrimary: Color(0xFF0C0403),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFF1744),
    info: Color(0xFF60A5FA),
  );

  // Jade Matrix (forest)
  static const forest = AppColors._(
    primary: Color(0xFF00D46A),
    primaryDark: Color(0xFF009E50),
    primaryLight: Color(0xFF4DDF95),
    accent: Color(0xFF00F5C8),
    accentOrange: Color(0xFFFF8C00),
    accentPurple: Color(0xFFA78BFA),
    background: Color(0xFF020A03),
    surface: Color(0xFF061408),
    surfaceLight: Color(0xFF0E2410),
    surfaceCard: Color(0xFF091A0B),
    elevated: Color(0xFF132D15),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF7DB88E),
    textMuted: Color(0xFF3A6645),
    textOnPrimary: Color(0xFF020A03),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFEF4444),
    info: Color(0xFF60A5FA),
  );

  // Nebula (purple)
  static const purple = AppColors._(
    primary: Color(0xFFA855F7),
    primaryDark: Color(0xFF7C3AED),
    primaryLight: Color(0xFFC084FC),
    accent: Color(0xFFF472B6),
    accentOrange: Color(0xFFFB923C),
    accentPurple: Color(0xFFA855F7),
    background: Color(0xFF04020A),
    surface: Color(0xFF0C0620),
    surfaceLight: Color(0xFF1A0E38),
    surfaceCard: Color(0xFF110828),
    elevated: Color(0xFF221445),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA89BC4),
    textMuted: Color(0xFF5C4878),
    textOnPrimary: Color(0xFF04020A),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
  );

  // Neon Tokyo (cyberpunk)
  static const cyber = AppColors._(
    primary: Color(0xFF00F5FF),
    primaryDark: Color(0xFF00B0C8),
    primaryLight: Color(0xFF66F8FF),
    accent: Color(0xFFFF0080),
    accentOrange: Color(0xFFFF4500),
    accentPurple: Color(0xFFFF0080),
    background: Color(0xFF02020A),
    surface: Color(0xFF07071A),
    surfaceLight: Color(0xFF12122E),
    surfaceCard: Color(0xFF0C0C24),
    elevated: Color(0xFF19193C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8FA8CC),
    textMuted: Color(0xFF404868),
    textOnPrimary: Color(0xFF02020A),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFF004D),
    info: Color(0xFF38BDF8),
  );

  static AppColors of(BuildContext context) {
    final palette = context
        .dependOnInheritedWidgetOfExactType<_AppColorsScope>();
    return palette?.colors ?? neon;
  }
}

class _AppColorsScope extends InheritedWidget {
  final AppColors colors;
  const _AppColorsScope({required this.colors, required super.child});

  @override
  bool updateShouldNotify(_AppColorsScope old) => colors != old.colors;
}

class AppColorsNotifier extends ValueNotifier<AppColors> {
  AppColorsNotifier() : super(AppColors.neon);
}
