import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/di/injection.dart';
import 'core/initialization/app_initializer.dart';
import 'core/initialization/init_state.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/user/user_bloc.dart';
import 'bloc/workout/workout_bloc.dart';
import 'bloc/nutrition/nutrition_bloc.dart';
import 'bloc/health/health_bloc.dart';
import 'bloc/ai/ai_bloc.dart';
import 'bloc/onboarding/onboarding_bloc.dart';
import 'bloc/training/test_week_bloc.dart';
import 'core/localization/language_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/theme_service.dart';
import 'core/theme/dynamic_theme.dart';
import 'core/theme/animated_theme_background.dart';

final _paletteNotifier = ValueNotifier<ThemePalette>(ThemePalette.neon);

ThemePalette _paletteFor(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.neonDark:
      return ThemePalette.neon;
    case AppThemeMode.oceanBlue:
      return ThemePalette.ocean;
    case AppThemeMode.sunsetWarm:
      return ThemePalette.sunset;
    case AppThemeMode.forestGreen:
      return ThemePalette.forest;
    case AppThemeMode.midnightPurple:
      return ThemePalette.purple;
    case AppThemeMode.cyberPunk:
      return ThemePalette.cyber;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(_FirebaseErrorApp(error: e.toString()));
    return;
  }

  String? initError;
  String? initStage;

  try {
    await AppInitializer().initialize(onProgress: (stage) => initStage = stage);
  } on AppInitException catch (e) {
    initError = e.message;
    initStage = e.stage;
  } catch (e) {
    initError = e.toString();
  }

  if (initError != null) {
    runApp(_InitErrorApp(stage: initStage, error: initError));
    return;
  }

  initializationComplete.value = true;

  // Sync palette with saved theme
  _paletteNotifier.value = _paletteFor(ThemeService.current);

  // Listen to theme changes and update palette
  ThemeService.notifier.addListener(() {
    _paletteNotifier.value = _paletteFor(ThemeService.current);
  });

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF070809),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FitnesBusterApp());
}

class FitnesBusterApp extends StatelessWidget {
  const FitnesBusterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider<UserBloc>(create: (_) => sl<UserBloc>()),
        BlocProvider<WorkoutBloc>(create: (_) => sl<WorkoutBloc>()),
        BlocProvider<NutritionBloc>(create: (_) => sl<NutritionBloc>()),
        BlocProvider<HealthBloc>(create: (_) => sl<HealthBloc>()),
        BlocProvider<AiBloc>(create: (_) => sl<AiBloc>()),
        BlocProvider<OnboardingBloc>(create: (_) => sl<OnboardingBloc>()),
        BlocProvider<TestWeekBloc>(create: (_) => sl<TestWeekBloc>()),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: LanguageService.localeNotifier,
        builder: (context, locale, _) {
          return ValueListenableBuilder<ThemePalette>(
            valueListenable: _paletteNotifier,
            builder: (context, palette, child) {
              return AppTheme(
                palette: palette,
                child: MaterialApp.router(
                  title: 'FitnesBuster',
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  theme: _buildTheme(palette),
                  routerConfig: AppRouter.router,
                  builder: (context, child) {
                    final isRtl = locale.languageCode == 'ar';
                    final dir = isRtl
                        ? ui.TextDirection.rtl
                        : ui.TextDirection.ltr;
                    return Directionality(
                      textDirection: dir,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: MediaQuery.textScalerOf(
                            context,
                          ).clamp(maxScaleFactor: 1.4),
                        ),
                        child: AnimatedThemeBackground(
                          palette: palette,
                          child: child!,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(ThemePalette p) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: p.primary,
        secondary: p.accent,
        surface: p.surface,
        error: p.error,
        onPrimary: p.textOnPrimary,
        onSecondary: p.textOnPrimary,
        onSurface: p.textPrimary,
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: 'Syne',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
          height: 1.25,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: p.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: p.surfaceLight, thickness: 1),
    );
  }
}

/// Notifier accessible from ThemeService to trigger palette switch.
ValueNotifier<ThemePalette> get paletteNotifier => _paletteNotifier;

class _InitErrorApp extends StatelessWidget {
  final String? stage;
  final String error;
  const _InitErrorApp({this.stage, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.orangeAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.tl('appInitError'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (stage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    stage!,
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.tl('appRestartMessage'),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FirebaseErrorApp extends StatelessWidget {
  final String error;
  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.tl('appFirebaseError'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
