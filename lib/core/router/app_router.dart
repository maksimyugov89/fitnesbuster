import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/presentation/widgets/router/main_shell.dart';
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

