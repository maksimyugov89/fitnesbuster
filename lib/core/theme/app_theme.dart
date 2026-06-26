import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Static neon-dark constants — for screens that don't yet use AppTheme.of(context).
/// Matches ThemePalette.neon exactly.
class AppColors {
  static const Color primary      = Color(0xFFC8FF00);
  static const Color primaryDark  = Color(0xFF96CC00);
  static const Color primaryLight = Color(0xFFDCFF4D);
  static const Color accent       = Color(0xFF00E5CC);
  static const Color accentOrange = Color(0xFFFF5500);
  static const Color accentPurple = Color(0xFF8B5CF6);

  static const Color background  = Color(0xFF070809);
  static const Color surface     = Color(0xFF0E1012);
  static const Color surfaceLight= Color(0xFF1C2025);
  static const Color surfaceCard = Color(0xFF131619);
  static const Color elevated    = Color(0xFF242A30);

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C1);
  static const Color textMuted     = Color(0xFF5A6370);
  static const Color textOnPrimary = Color(0xFF080808);

  static const Color success = Color(0xFF22D3A5);
  static const Color warning = Color(0xFFF5A623);
  static const Color error   = Color(0xFFFF4466);
  static const Color info    = Color(0xFF38BDF8);

  // Lime → lime-green → electric teal — 3-stop aurora gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFC8FF00), Color(0xFF7EF561), Color(0xFF00E5CC)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // Fire gradient for calories / burn cards
  static const LinearGradient burnGradient = LinearGradient(
    colors: [Color(0xFFFF5500), Color(0xFFFF4466)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // Subtle surface gradient
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0E1012), Color(0xFF070809)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  // Radial glow behind primary elements
  static const RadialGradient glowPrimary = RadialGradient(
    colors: [Color(0x55C8FF00), Color(0x00C8FF00)],
    radius: 1.4,
  );
}

class AppTextStyles {
  static const String fontDisplay = 'Syne';
  static const String fontBody = 'Inter';

  static const TextStyle displayXL = TextStyle(fontFamily: fontDisplay, fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.0, letterSpacing: -2.0);
  static const TextStyle displayL = TextStyle(fontFamily: fontDisplay, fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1, letterSpacing: -1.5);
  static const TextStyle displayM = TextStyle(fontFamily: fontDisplay, fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.15, letterSpacing: -1.0);
  static const TextStyle titleL = TextStyle(fontFamily: fontDisplay, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5);
  static const TextStyle titleM = TextStyle(fontFamily: fontDisplay, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.25);
  static const TextStyle bodyL = TextStyle(fontFamily: fontBody, fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.6);
  static const TextStyle bodyM = TextStyle(fontFamily: fontBody, fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static const TextStyle labelL = TextStyle(fontFamily: fontBody, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.5);
  static const TextStyle labelM = TextStyle(fontFamily: fontBody, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8);
  static const TextStyle numberXL = TextStyle(fontFamily: fontDisplay, fontSize: 64, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.0, letterSpacing: -3.0);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTextStyles.titleM,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      // ← ИСПРАВЛЕНО: CardThemeData вместо CardTheme
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.labelL,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 1)),
        hintStyle: AppTextStyles.bodyM,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.surfaceLight, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double round = 100;
}
