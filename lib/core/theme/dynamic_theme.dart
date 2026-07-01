import 'package:flutter/material.dart';

/// Dynamic theme palette. Use `AppTheme.of(context).primary` instead of `AppColors.primary`.
class AppTheme extends InheritedWidget {
  final ThemePalette palette;

  const AppTheme({super.key, required this.palette, required super.child});

  static ThemePalette of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTheme>()?.palette ??
        ThemePalette.neon;
  }

  @override
  bool updateShouldNotify(AppTheme old) => palette != old.palette;
}

/// Holds all theme design tokens as const values for each mode.
/// Access via AppTheme.of(context) — never instantiate directly in widgets.
class ThemePalette {
  // Brand colors
  final Color primary, primaryDark, primaryLight;

  // Accent family
  final Color accent, accentOrange, accentPurple;

  // Surface hierarchy (4 levels + elevated)
  final Color background, surface, surfaceLight, surfaceCard, elevated;

  // Typography
  final Color textPrimary, textSecondary, textMuted, textOnPrimary;

  // Semantic
  final Color success, warning, error, info;

  // Gradients
  final LinearGradient
  primaryGradient; // 3-stop aurora — main CTA, avatar, buttons
  final LinearGradient accentGradient; // 2-stop — secondary elements, badges
  final RadialGradient glowPrimary; // radial glow behind highlighted elements

  // Legacy aliases (same as background / surfaceCard)
  final Color scaffoldBg, cardBg;

  const ThemePalette({
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
    required this.primaryGradient,
    required this.accentGradient,
    required this.glowPrimary,
    required this.scaffoldBg,
    required this.cardBg,
  });

  // ─── NEON DARK: Electric Volt ────────────────────────────────────────────────
  // Concept: Premium deep-space fitness — near-black with electric acid-lime.
  // Inspired by Nike Training Club × Apple Fitness+.
  // Primary: #C8FF00 (maximum-luminance volt)  Accent: #00E5CC (electric teal)
  static const neon = ThemePalette(
    primary: Color(0xFFC8FF00),
    primaryDark: Color(0xFF96CC00),
    primaryLight: Color(0xFFDCFF4D),
    accent: Color(0xFF00E5CC),
    accentOrange: Color(0xFFFF5500),
    accentPurple: Color(0xFF8B5CF6),

    background: Color(0xFF070809),
    surface: Color(0xFF0E1012),
    surfaceCard: Color(0xFF131619),
    surfaceLight: Color(0xFF1C2025),
    elevated: Color(0xFF242A30),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B8C1),
    textMuted: Color(0xFF5A6370),
    textOnPrimary: Color(0xFF080808),

    success: Color(0xFF22D3A5),
    warning: Color(0xFFF5A623),
    error: Color(0xFFFF4466),
    info: Color(0xFF38BDF8),

    // Lime → lime-green → electric teal sweep
    primaryGradient: LinearGradient(
      colors: [Color(0xFFC8FF00), Color(0xFF7EF561), Color(0xFF00E5CC)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Purple → teal — for secondary actions
    accentGradient: LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF00E5CC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: RadialGradient(
      colors: [Color(0x55C8FF00), Color(0x00C8FF00)],
      radius: 1.4,
    ),
    scaffoldBg: Color(0xFF070809),
    cardBg: Color(0xFF131619),
  );

  // ─── OCEAN: Deep Horizon ─────────────────────────────────────────────────────
  // Concept: Bioluminescent deep sea — ultra-dark midnight navy + electric cyan.
  // Primary: #00CFFF (max-sat cyan)  Accent: #67E8F9 (ice blue)
  static const ocean = ThemePalette(
    primary: Color(0xFF00CFFF),
    primaryDark: Color(0xFF009ABB),
    primaryLight: Color(0xFF4DDCFF),
    accent: Color(0xFF67E8F9),
    accentOrange: Color(0xFFFF7043),
    accentPurple: Color(0xFF818CF8),

    background: Color(0xFF020C16),
    surface: Color(0xFF061B2B),
    surfaceCard: Color(0xFF0A2035),
    surfaceLight: Color(0xFF0F2B43),
    elevated: Color(0xFF153250),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF90B4CE),
    textMuted: Color(0xFF4A6B84),
    textOnPrimary: Color(0xFF020C16),

    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF38BDF8),

    // Bright cyan → deep electric blue → ice blue — ocean depth effect
    primaryGradient: LinearGradient(
      colors: [Color(0xFF00CFFF), Color(0xFF006FFF), Color(0xFF67E8F9)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Indigo → cyan — for secondary elements
    accentGradient: LinearGradient(
      colors: [Color(0xFF818CF8), Color(0xFF00CFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: RadialGradient(
      colors: [Color(0x5500CFFF), Color(0x0000CFFF)],
      radius: 1.4,
    ),
    scaffoldBg: Color(0xFF020C16),
    cardBg: Color(0xFF0A2035),
  );

  // ─── SUNSET: Aurora Flame ────────────────────────────────────────────────────
  // Concept: Nordic fire aurora — deep burnt-crimson base + coral + golden amber.
  // Primary: #FF4D1A (saturated coral-red)  Accent: #FFB020 (gold amber)
  static const sunset = ThemePalette(
    primary: Color(0xFFFF4D1A),
    primaryDark: Color(0xFFCC2900),
    primaryLight: Color(0xFFFF7040),
    accent: Color(0xFFFFB020),
    accentOrange: Color(0xFFFF4D1A),
    accentPurple: Color(0xFFD946EF),

    background: Color(0xFF0C0403),
    surface: Color(0xFF180906),
    surfaceCard: Color(0xFF200C07),
    surfaceLight: Color(0xFF2C120C),
    elevated: Color(0xFF391813),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC4907A),
    textMuted: Color(0xFF6B3A2A),
    textOnPrimary: Color(0xFF0C0403),

    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFF1744),
    info: Color(0xFF60A5FA),

    // Hot crimson → coral-orange → golden amber — fire sweep
    primaryGradient: LinearGradient(
      colors: [Color(0xFFFF1C4A), Color(0xFFFF4D1A), Color(0xFFFFB020)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Magenta → coral — secondary elements
    accentGradient: LinearGradient(
      colors: [Color(0xFFD946EF), Color(0xFFFF4D1A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: RadialGradient(
      colors: [Color(0x55FF4D1A), Color(0x00FF4D1A)],
      radius: 1.4,
    ),
    scaffoldBg: Color(0xFF0C0403),
    cardBg: Color(0xFF200C07),
  );

  // ─── FOREST: Jade Matrix ─────────────────────────────────────────────────────
  // Concept: Bioluminescent jungle — near-void black + vibrant emerald + mint.
  // Primary: #00D46A (vibrant emerald)  Accent: #00F5C8 (bright mint-teal)
  static const forest = ThemePalette(
    primary: Color(0xFF00D46A),
    primaryDark: Color(0xFF009E50),
    primaryLight: Color(0xFF4DDF95),
    accent: Color(0xFF00F5C8),
    accentOrange: Color(0xFFFF8C00),
    accentPurple: Color(0xFFA78BFA),

    background: Color(0xFF020A03),
    surface: Color(0xFF061408),
    surfaceCard: Color(0xFF091A0B),
    surfaceLight: Color(0xFF0E2410),
    elevated: Color(0xFF132D15),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF7DB88E),
    textMuted: Color(0xFF3A6645),
    textOnPrimary: Color(0xFF020A03),

    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFEF4444),
    info: Color(0xFF60A5FA),

    // Emerald → jade-green → mint teal sweep
    primaryGradient: LinearGradient(
      colors: [Color(0xFF00D46A), Color(0xFF00B87A), Color(0xFF00F5C8)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Violet → emerald — for secondary elements
    accentGradient: LinearGradient(
      colors: [Color(0xFFA78BFA), Color(0xFF00D46A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: RadialGradient(
      colors: [Color(0x5500D46A), Color(0x0000D46A)],
      radius: 1.4,
    ),
    scaffoldBg: Color(0xFF020A03),
    cardBg: Color(0xFF091A0B),
  );

  // ─── PURPLE: Nebula ──────────────────────────────────────────────────────────
  // Concept: Cosmic void + aurora borealis — ultra-deep purple-black + violet + rose.
  // Primary: #A855F7 (vibrant violet)  Accent: #F472B6 (aurora rose)
  static const purple = ThemePalette(
    primary: Color(0xFFA855F7),
    primaryDark: Color(0xFF7C3AED),
    primaryLight: Color(0xFFC084FC),
    accent: Color(0xFFF472B6),
    accentOrange: Color(0xFFFB923C),
    accentPurple: Color(0xFFA855F7),

    background: Color(0xFF04020A),
    surface: Color(0xFF0C0620),
    surfaceCard: Color(0xFF110828),
    surfaceLight: Color(0xFF1A0E38),
    elevated: Color(0xFF221445),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA89BC4),
    textMuted: Color(0xFF5C4878),
    textOnPrimary: Color(0xFF04020A),

    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF38BDF8),

    // Deep violet → bright violet → aurora rose — nebula sweep
    primaryGradient: LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFF472B6)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Rose → warm amber — secondary elements
    accentGradient: LinearGradient(
      colors: [Color(0xFFF472B6), Color(0xFFFB923C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: RadialGradient(
      colors: [Color(0x55A855F7), Color(0x00A855F7)],
      radius: 1.4,
    ),
    scaffoldBg: Color(0xFF04020A),
    cardBg: Color(0xFF110828),
  );

  // ─── CYBER: Neon Tokyo ───────────────────────────────────────────────────────
  // Concept: Maximum cyberpunk contrast — absolute void black + electric cyan + hot magenta.
  // Primary: #00F5FF (peak electric cyan)  Accent: #FF0080 (neon magenta)
  static const cyber = ThemePalette(
    primary: Color(0xFF00F5FF),
    primaryDark: Color(0xFF00B0C8),
    primaryLight: Color(0xFF66F8FF),
    accent: Color(0xFFFF0080),
    accentOrange: Color(0xFFFF4500),
    accentPurple: Color(0xFFFF0080),

    background: Color(0xFF02020A),
    surface: Color(0xFF07071A),
    surfaceCard: Color(0xFF0C0C24),
    surfaceLight: Color(0xFF12122E),
    elevated: Color(0xFF19193C),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8FA8CC),
    textMuted: Color(0xFF404868),
    textOnPrimary: Color(0xFF02020A),

    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFFF004D),
    info: Color(0xFF38BDF8),

    // Electric cyan → deep electric blue → hot magenta — full cyberpunk sweep
    primaryGradient: LinearGradient(
      colors: [Color(0xFF00F5FF), Color(0xFF0055FF), Color(0xFFFF0080)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Hot magenta → hot orange — secondary elements
    accentGradient: LinearGradient(
      colors: [Color(0xFFFF0080), Color(0xFFFF4500)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowPrimary: RadialGradient(
      colors: [Color(0x5500F5FF), Color(0x0000F5FF)],
      radius: 1.4,
    ),
    scaffoldBg: Color(0xFF02020A),
    cardBg: Color(0xFF0C0C24),
  );
}
