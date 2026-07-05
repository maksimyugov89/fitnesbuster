import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/services/workout_session.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String currentPath;
  const MainShell({super.key, required this.child, required this.currentPath});

  static const List<String> _routes = [
    '/dashboard',
    '/workout',
    '/nutrition',
    '/progress',
    '/profile',
  ];

  int get _selectedIndex {
    for (int i = 0; i < _routes.length; i++) {
      if (currentPath.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          ListenableBuilder(
            listenable: sl<WorkoutSession>(),
            builder: (context, _) {
              final session = sl<WorkoutSession>();
              if (!session.isActive) return const SizedBox.shrink();
              return RouterWorkoutMiniPlayer(session: session);
            },
          ),
        ],
      ),
      bottomNavigationBar: RouterBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }
}

class RouterWorkoutMiniPlayer extends StatelessWidget {
  final WorkoutSession session;
  const RouterWorkoutMiniPlayer({super.key, required this.session});

  Color _phaseColor(ThemePalette c) => switch (session.phase) {
    WorkoutPhase.prep => c.accentOrange,
    WorkoutPhase.exercise => c.primary,
    WorkoutPhase.rest => c.accentPurple,
    WorkoutPhase.done => c.success,
  };

  String get _phaseLabel => switch (session.phase) {
    WorkoutPhase.prep => AppLocalizations.tl('phasePrep'),
    WorkoutPhase.exercise => AppLocalizations.tl('phaseExercise'),
    WorkoutPhase.rest => AppLocalizations.tl('phaseRest'),
    WorkoutPhase.done => AppLocalizations.tl('phaseDone'),
  };

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final color = _phaseColor(c);
    final timeLeft = session.computedTimeLeft;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () {
            final workout = session.workout;
            if (workout == null) return;
            context.push('/workout/execution', extra: workout);
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.exerciseName,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$_phaseLabel · ${session.progressText}',
                        style: TextStyle(fontSize: 10, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timeLeft > 0
                        ? '$timeLeft ${AppLocalizations.tl("seconds")}'
                        : '—',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: c.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RouterBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const RouterBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = AppTheme.of(context);
    final items = [
      _NavItem(icon: AppImages.home, label: l10n.navHome),
      _NavItem(icon: AppImages.workoutsTab, label: l10n.navWorkout),
      _NavItem(icon: AppImages.nutritionTab, label: l10n.navNutrition),
      _NavItem(icon: AppImages.progressTab, label: l10n.navProgress),
      _NavItem(icon: AppImages.profileTab, label: l10n.navProfile),
    ];
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((e) {
              final isSel = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? p.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Opacity(
                          opacity: isSel ? 1 : 0.45,
                          child: AppIcon(
                            asset: e.value.icon,
                            glowColor: isSel ? p.primary : null,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          e.value.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSel ? p.primary : p.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
