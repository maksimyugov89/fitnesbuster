import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/theme_service.dart';
import 'package:fitnesbuster/core/initialization/init_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _textController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
    _progressController.forward();

    const minDisplay = Duration(milliseconds: 1500);
    final startedAt = DateTime.now();

    if (initializationComplete.value) {
      final remaining = minDisplay - DateTime.now().difference(startedAt);
      if (remaining > Duration.zero) await Future.delayed(remaining);
    } else {
      await Future.any([
        Future.delayed(const Duration(seconds: 15)),
        () async {
          await _waitForInit();
          final remaining = minDisplay - DateTime.now().difference(startedAt);
          if (remaining > Duration.zero) await Future.delayed(remaining);
        }(),
      ]);
    }

    if (mounted) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthStateAuthenticated) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    }
  }

  Future<void> _waitForInit() async {
    if (initializationComplete.value) return;
    while (!initializationComplete.value && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _splashBgFor(ThemeService.current),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.65, 1.0],
                colors: [
                  Color(0x29000000),
                  Color(0x4D000000),
                  Color(0x99000000),
                  Color(0xE6000000),
                ],
              ),
            ),
          ),

          // App name + tagline
          Align(
            alignment: const Alignment(0, 0.15),
            child: SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: _buildTextBlock(colors),
              ),
            ),
          ),

          // Loading bar
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: _buildLoadingSection(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(ThemePalette colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          softWrap: false,
          overflow: TextOverflow.visible,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Fitnes',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'Buster',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: -1,
                  shadows: [
                    Shadow(
                      color: colors.primary.withValues(alpha: 0.75),
                      blurRadius: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: 56,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, colors.primary, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'ТВОЙ ПЕРСОНАЛЬНЫЙ ТРЕНЕР',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection(ThemePalette colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Column(
        children: [
          Text(
            'З А Г Р У З К А',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors.textMuted.withValues(alpha: 0.65),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (_, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Fill + glowing dot
                  FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        if (_progressAnimation.value > 0.02)
                          Positioned(
                            right: -5,
                            top: -3.5,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary,
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String _splashBgFor(AppThemeMode mode) => switch (mode) {
  AppThemeMode.neonDark => 'assets/images/splash_bg_neon.png',
  AppThemeMode.cyberPunk => 'assets/images/splash_bg_cyberpunk.png',
  AppThemeMode.oceanBlue => 'assets/images/splash_bg_ocean.png',
  AppThemeMode.sunsetWarm => 'assets/images/splash_bg_sunset.png',
  AppThemeMode.forestGreen => 'assets/images/splash_bg_forest.png',
  AppThemeMode.midnightPurple => 'assets/images/splash_bg_violet.png',
};
