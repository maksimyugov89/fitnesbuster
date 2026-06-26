import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/services/workout_session.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_execution_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/splash_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/login_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/register_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/goal_selection_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/intensity_selection_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/workout_location_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/profile_setup_screen.dart';
import 'package:fitnesbuster/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_plan_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_session_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_log_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/test_week_screen.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/nutrition_screen.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/food_diary_screen.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/meal_plan_screen.dart';
import 'package:fitnesbuster/presentation/screens/progress/progress_screen.dart';
import 'package:fitnesbuster/presentation/screens/profile/profile_screen.dart';
import 'package:fitnesbuster/presentation/screens/profile/health_sync_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/pr_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/exercise_browser_screen.dart';
import 'package:fitnesbuster/presentation/screens/ai_chat/ai_chat_screen.dart';
import 'package:fitnesbuster/presentation/screens/progress/weekly_debrief_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/exercise_detail_screen.dart';
import 'package:fitnesbuster/presentation/screens/gamification/achievements_screen.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/shopping_list_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_calendar_screen.dart';
import 'package:fitnesbuster/presentation/screens/social/feed_screen.dart';
import 'package:fitnesbuster/presentation/screens/social/friends_screen.dart';
import 'package:fitnesbuster/presentation/screens/social/challenges_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String goalSelection = '/onboarding/goal';
  static const String intensitySelection = '/onboarding/intensity';
  static const String workoutLocation = '/onboarding/location';
  static const String profileSetup = '/onboarding/profile';
  static const String dashboard = '/dashboard';
  static const String workoutPlan = '/workout';
  static const String workoutSession = '/workout/session/:id';
  static const String workoutLog = '/workout/log/:id';
  static const String nutrition = '/nutrition';
  static const String foodDiary = '/nutrition/diary';
  static const String mealPlan = '/nutrition/meal-plan';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String healthSync = '/health-sync';
  static const String testWeek = '/test-week';
  static const String prTracker = '/pr';
  static const String exerciseBrowser = '/exercises';
  static const String aiChat = '/chat';
  static const String weeklyDebrief = '/debrief';
  static const String exerciseDetail   = '/exercises/:id';
  static const String achievements      = '/achievements';
  static const String shoppingList       = '/shopping-list';
  static const String workoutCalendar    = '/workout/calendar';
  static const String workoutExecution   = '/workout/execution';
  static const String feed              = '/social/feed';
  static const String friends           = '/social/friends';
  static const String challenges        = '/social/challenges';

  static late GoRouter router;

  static void init() {
    router = GoRouter(
      initialLocation: splash,
      debugLogDiagnostics: false,
      refreshListenable: _AuthRouterNotifier(),
      redirect: _redirect,
      routes: [
      GoRoute(path: splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: onboarding,
        builder: (_, __) => const OnboardingScreen(),
        routes: [
          GoRoute(path: 'goal', builder: (_, __) => const GoalSelectionScreen()),
          GoRoute(path: 'intensity', builder: (_, __) => const IntensitySelectionScreen()),
          GoRoute(path: 'location', builder: (_, __) => const WorkoutLocationScreen()),
          GoRoute(path: 'profile', builder: (_, __) => const ProfileSetupScreen()),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: dashboard, builder: (_, __) => const DashboardScreen()),
          GoRoute(path: workoutPlan, builder: (_, __) => const WorkoutPlanScreen()),
          GoRoute(path: nutrition, builder: (_, __) => const NutritionScreen()),
          GoRoute(path: progress, builder: (_, __) => const ProgressScreen()),
          GoRoute(path: profile, builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: workoutSession,
        builder: (context, state) =>
            WorkoutSessionScreen(sessionId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: workoutLog,
        builder: (context, state) =>
            WorkoutLogScreen(logId: state.pathParameters['id']!),
      ),
      GoRoute(path: testWeek, builder: (_, __) => const TestWeekScreen()),
      GoRoute(path: foodDiary, builder: (_, __) => const FoodDiaryScreen()),
      GoRoute(path: mealPlan, builder: (_, __) => const MealPlanScreen()),
      GoRoute(path: healthSync, builder: (_, __) => const HealthSyncScreen()),
      GoRoute(path: prTracker, builder: (_, __) => const PrScreen()),
      GoRoute(path: exerciseBrowser, builder: (_, __) => const ExerciseBrowserScreen()),
      GoRoute(
        path: exerciseDetail,
        builder: (context, state) =>
            ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
      ),
      GoRoute(path: aiChat, builder: (_, __) => const AiChatScreen()),
      GoRoute(path: weeklyDebrief, builder: (_, __) => const WeeklyDebriefScreen()),
      GoRoute(path: achievements, builder: (_, __) => const AchievementsScreen()),
      GoRoute(path: shoppingList, builder: (_, __) => const ShoppingListScreen()),
      GoRoute(path: workoutCalendar, builder: (_, __) => const WorkoutCalendarScreen()),
      GoRoute(
        path: workoutExecution,
        builder: (context, state) =>
            WorkoutExecutionScreen(workout: state.extra as WorkoutDay),
      ),
      GoRoute(path: feed, builder: (_, __) => const FeedScreen()),
      GoRoute(path: friends, builder: (_, __) => const FriendsScreen()),
      GoRoute(path: challenges, builder: (_, __) => const ChallengesScreen()),
    ],
    );
  }

  static String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;

    if (loc == splash) return null;

    final isOnboarding = loc.startsWith(onboarding);
    final isPublic = loc == login || loc == register || isOnboarding;

    if (!isAuthenticated && !isPublic) return login;

    if (isAuthenticated && isPublic) {
      final authState = context.read<AuthBloc>().state;

      // AuthBloc ещё не подтвердил аутентификацию — ждём, не редиректим на онбординг
      if (authState is! AuthStateAuthenticated) return null;

      final hasProfile = authState.user.profile != null;
      if (isOnboarding) return hasProfile ? dashboard : null;
      return hasProfile ? dashboard : onboarding;
    }

    return null;
  }
}

// ─── Auth state notifier for GoRouter refresh ────────────────────────────────
// Слушает Firebase Auth И AuthBloc — роутер переоценивает редирект
// когда любой из них меняется (исправляет гонку при старте).
class _AuthRouterNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _firebaseSub;
  late final StreamSubscription<AuthState> _blocSub;

  _AuthRouterNotifier() {
    _firebaseSub = FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => notifyListeners());
    _blocSub = sl<AuthBloc>().stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _firebaseSub.cancel();
    _blocSub.cancel();
    super.dispose();
  }
}

// ─── Main Shell with Bottom Navigation ───────────────────────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  final String currentPath;
  const MainShell({super.key, required this.child, required this.currentPath});

  static const List<String> _routes = [
    AppRouter.dashboard,
    AppRouter.workoutPlan,
    AppRouter.nutrition,
    AppRouter.progress,
    AppRouter.profile,
  ];

  int get _selectedIndex {
    for (int i = 0; i < _routes.length; i++) {
      if (currentPath.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WorkoutSession.instance,
      builder: (context, _) {
        final session = WorkoutSession.instance;
        return Scaffold(
          body: Stack(children: [
            child,
            if (session.isActive) _WorkoutMiniPlayer(session: session),
          ]),
          bottomNavigationBar: _BottomNav(
            selectedIndex: _selectedIndex,
            onTap: (i) => context.go(_routes[i]),
          ),
        );
      },
    );
  }
}

// ─── Floating workout mini-player ─────────────────────────────────────────────
class _WorkoutMiniPlayer extends StatelessWidget {
  final WorkoutSession session;
  const _WorkoutMiniPlayer({required this.session});

  Color _phaseColor(ThemePalette c) => switch (session.phase) {
        WorkoutPhase.prep     => c.accentOrange,
        WorkoutPhase.exercise => c.primary,
        WorkoutPhase.rest     => c.accentPurple,
        WorkoutPhase.done     => c.success,
      };

  String get _phaseLabel => switch (session.phase) {
        WorkoutPhase.prep     => 'ПОДГОТОВКА',
        WorkoutPhase.exercise => 'ВЫПОЛНЕНИЕ',
        WorkoutPhase.rest     => 'ОТДЫХ',
        WorkoutPhase.done     => 'ГОТОВО',
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
            context.push(AppRouter.workoutExecution, extra: workout);
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              // Animated phase dot
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]),
              ),
              const SizedBox(width: 10),
              // Exercise info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(session.exerciseName,
                    style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$_phaseLabel · ${session.progressText}',
                    style: TextStyle(fontSize: 10, color: c.textMuted)),
              ])),
              // Countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(timeLeft > 0 ? '$timeLeft с' : '—',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: c.textMuted),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Главная'),
    _NavItem(icon: Icons.fitness_center_rounded, label: 'Тренировки'),
    _NavItem(icon: Icons.restaurant_rounded, label: 'Питание'),
    _NavItem(icon: Icons.show_chart_rounded, label: 'Прогресс'),
    _NavItem(icon: Icons.person_rounded, label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: _items.asMap().entries.map((e) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? p.primary.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          e.value.icon,
                          color: isSel ? p.primary : p.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.value.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel ? p.primary : p.textMuted,
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
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
