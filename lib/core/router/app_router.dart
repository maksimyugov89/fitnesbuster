import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/router/auth_router_notifier.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/presentation/widgets/router/main_shell.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_execution_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/splash_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/login_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/register_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/verify_email_screen.dart';
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
  static const String verifyEmail = '/verify-email';
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
  static const String prTracker = '/pr-tracker';
  static const String exerciseBrowser = '/exercises';
  static const String aiChat = '/chat';
  static const String weeklyDebrief = '/weekly-debrief';
  static const String exerciseDetail = '/exercises/:id';
  static const String achievements = '/achievements';
  static const String shoppingList = '/shopping-list';
  static const String workoutCalendar = '/workout/calendar';
  static const String workoutExecution = '/workout/execution';
  static const String feed = '/social/feed';
  static const String friends = '/social/friends';
  static const String challenges = '/social/challenges';

  static late GoRouter router;

  static void init() {
    router = GoRouter(
      initialLocation: splash,
      debugLogDiagnostics: false,
      refreshListenable: AuthRouterNotifier(),
      redirect: _redirect,
      routes: [
        GoRoute(path: splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: register, builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: verifyEmail,
          builder: (_, _) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: onboarding,
          builder: (_, _) => const OnboardingScreen(),
          routes: [
            GoRoute(
              path: 'goal',
              builder: (_, _) => const GoalSelectionScreen(),
            ),
            GoRoute(
              path: 'intensity',
              builder: (_, _) => const IntensitySelectionScreen(),
            ),
            GoRoute(
              path: 'location',
              builder: (_, _) => const WorkoutLocationScreen(),
            ),
            GoRoute(
              path: 'profile',
              builder: (_, _) => const ProfileSetupScreen(),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) =>
              MainShell(currentPath: state.matchedLocation, child: child),
          routes: [
            GoRoute(
              path: dashboard,
              builder: (_, _) => const DashboardScreen(),
            ),
            GoRoute(
              path: workoutPlan,
              builder: (_, _) => const WorkoutPlanScreen(),
            ),
            GoRoute(
              path: nutrition,
              builder: (_, _) => const NutritionScreen(),
            ),
            GoRoute(path: progress, builder: (_, _) => const ProgressScreen()),
            GoRoute(path: profile, builder: (_, _) => const ProfileScreen()),
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
        GoRoute(path: testWeek, builder: (_, _) => const TestWeekScreen()),
        GoRoute(path: foodDiary, builder: (_, _) => const FoodDiaryScreen()),
        GoRoute(path: mealPlan, builder: (_, _) => const MealPlanScreen()),
        GoRoute(path: healthSync, builder: (_, _) => const HealthSyncScreen()),
        GoRoute(path: prTracker, builder: (_, _) => const PrScreen()),
        GoRoute(
          path: exerciseBrowser,
          builder: (_, _) => const ExerciseBrowserScreen(),
        ),
        GoRoute(
          path: exerciseDetail,
          builder: (context, state) =>
              ExerciseDetailScreen(exerciseId: state.pathParameters['id']!),
        ),
        GoRoute(path: aiChat, builder: (_, _) => const AiChatScreen()),
        GoRoute(
          path: weeklyDebrief,
          builder: (_, _) => const WeeklyDebriefScreen(),
        ),
        GoRoute(
          path: achievements,
          builder: (_, _) => const AchievementsScreen(),
        ),
        GoRoute(
          path: shoppingList,
          builder: (_, _) => const ShoppingListScreen(),
        ),
        GoRoute(
          path: workoutCalendar,
          builder: (_, _) => const WorkoutCalendarScreen(),
        ),
        GoRoute(
          path: workoutExecution,
          builder: (context, state) =>
              WorkoutExecutionScreen(workout: state.extra as WorkoutDay),
        ),
        GoRoute(path: feed, builder: (_, _) => const FeedScreen()),
        GoRoute(path: friends, builder: (_, _) => const FriendsScreen()),
        GoRoute(path: challenges, builder: (_, _) => const ChallengesScreen()),
      ],
    );
  }

  static String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;
    final authState = context.read<AuthBloc>().state;
    final isAuthStateAuthenticated = authState is AuthStateAuthenticated;

    return resolveAuthRedirect(
      loc: loc,
      isAuthenticated: isAuthenticated,
      isAuthStateAuthenticated: isAuthStateAuthenticated,
      emailVerified: isAuthStateAuthenticated ? authState.emailVerified : false,
      hasProfile: isAuthStateAuthenticated
          ? authState.user.profile != null
          : false,
    );
  }
}

String? resolveAuthRedirect({
  required String loc,
  required bool isAuthenticated,
  required bool isAuthStateAuthenticated,
  required bool emailVerified,
  required bool hasProfile,
}) {
  if (loc == AppRouter.splash) return null;

  final isOnboarding = loc.startsWith(AppRouter.onboarding);
  final isVerifyEmail = loc == AppRouter.verifyEmail;
  final isPublic =
      loc == AppRouter.login || loc == AppRouter.register || isOnboarding;

  if (!isAuthenticated && !isPublic) return AppRouter.login;

  if (isAuthenticated) {
    if (!isAuthStateAuthenticated) return null;

    if (!emailVerified) {
      return isVerifyEmail ? null : AppRouter.verifyEmail;
    }

    if (isPublic || isVerifyEmail) {
      if (isOnboarding) return hasProfile ? AppRouter.dashboard : null;
      return hasProfile ? AppRouter.dashboard : AppRouter.onboarding;
    }
  }

  return null;
}
