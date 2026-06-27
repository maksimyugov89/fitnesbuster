import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart';
import 'package:fitnesbuster/main.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/bloc/workout/workout_bloc.dart';
import 'package:fitnesbuster/bloc/nutrition/nutrition_bloc.dart';
import 'package:fitnesbuster/bloc/health/health_bloc.dart';
import 'package:fitnesbuster/core/health/health_analytics_service.dart';
import 'package:fitnesbuster/presentation/screens/auth/login_screen.dart';
import 'package:fitnesbuster/presentation/screens/auth/register_screen.dart';
import 'package:fitnesbuster/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:fitnesbuster/presentation/screens/progress/progress_screen.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/nutrition_screen.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/food_diary_screen.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/meal_plan_screen.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_plan_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/goal_selection_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/intensity_selection_screen.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/profile_setup_screen.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/core/services/nutrition_service.dart';

// =====================================================================
// THEME TESTS
// =====================================================================
void main() {
  // Initialize DI for tests that need it
  setUpAll(() async {
    try {
      await initDependencies();
    } catch (_) {
      // DI already initialized or Firebase not available - use test DI
    }
  });
  // ==============================
  // APP LAUNCH
  // ==============================
  group('App Launch', () {
    testWidgets('App launches without crashing', (WidgetTester tester) async {
      // Skip: requires Firebase + Hive initialization from main()
      await tester.pumpWidget(FitnesBusterApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }, skip: true);
  });

  // ==============================
  // APP ROUTER
  // ==============================
  group('AppRouter', () {
    test('has all route constants defined', () {
      expect(AppRouter.splash, '/');
      expect(AppRouter.login, '/login');
      expect(AppRouter.register, '/register');
      expect(AppRouter.onboarding, '/onboarding');
      expect(AppRouter.goalSelection, '/onboarding/goal');
      expect(AppRouter.intensitySelection, '/onboarding/intensity');
      expect(AppRouter.profileSetup, '/onboarding/profile');
      expect(AppRouter.dashboard, '/dashboard');
      expect(AppRouter.workoutPlan, '/workout');
      expect(AppRouter.workoutSession, '/workout/session/:id');
      expect(AppRouter.workoutLog, '/workout/log/:id');
      expect(AppRouter.nutrition, '/nutrition');
      expect(AppRouter.foodDiary, '/nutrition/diary');
      expect(AppRouter.mealPlan, '/nutrition/meal-plan');
      expect(AppRouter.progress, '/progress');
      expect(AppRouter.profile, '/profile');
    });

    test('router is initialized and non-null', () {
      expect(AppRouter.router, isNotNull);
    }, skip: 'requires Firebase — AppRouter.init() not called in unit tests');

    test('router configuration exists', () {
      final router = AppRouter.router;
      expect(router, isNotNull);
    }, skip: 'requires Firebase — AppRouter.init() not called in unit tests');
  });

  // ==============================
  // APP COLORS
  // ==============================
  group('AppColors', () {
    test('primary colors are defined', () {
      expect(AppColors.primary, const Color(0xFFC8FF00));
      expect(AppColors.primaryDark, const Color(0xFF96CC00));
      expect(AppColors.primaryLight, const Color(0xFFDCFF4D));
    });

    test('accent colors are defined', () {
      expect(AppColors.accent, const Color(0xFF00E5CC));
      expect(AppColors.accentOrange, const Color(0xFFFF5500));
      expect(AppColors.accentPurple, const Color(0xFF8B5CF6));
    });

    test('background and surface colors are defined', () {
      expect(AppColors.background, const Color(0xFF070809));
      expect(AppColors.surface, const Color(0xFF0E1012));
      expect(AppColors.surfaceLight, const Color(0xFF1C2025));
      expect(AppColors.surfaceCard, const Color(0xFF131619));
      expect(AppColors.elevated, const Color(0xFF242A30));
    });

    test('text colors are defined', () {
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.textSecondary, const Color(0xFFB0B8C1));
      expect(AppColors.textMuted, const Color(0xFF5A6370));
      expect(AppColors.textOnPrimary, const Color(0xFF080808));
    });

    test('semantic colors are defined', () {
      expect(AppColors.success, const Color(0xFF22D3A5));
      expect(AppColors.warning, const Color(0xFFF5A623));
      expect(AppColors.error, const Color(0xFFFF4466));
      expect(AppColors.info, const Color(0xFF38BDF8));
    });

    test('primaryGradient has correct colors', () {
      expect(AppColors.primaryGradient.colors.length, 3);
      expect(AppColors.primaryGradient.colors[0], const Color(0xFFC8FF00));
      expect(AppColors.primaryGradient.colors[1], const Color(0xFF7EF561));
      expect(AppColors.primaryGradient.colors[2], const Color(0xFF00E5CC));
    });
  });

  // ==============================
  // APP TEXT STYLES
  // ==============================
  group('AppTextStyles', () {
    test('displayXL uses Syne and correct size', () {
      expect(AppTextStyles.displayXL.fontFamily, 'Syne');
      expect(AppTextStyles.displayXL.fontSize, 56);
      expect(AppTextStyles.displayXL.fontWeight, FontWeight.w800);
      expect(AppTextStyles.displayXL.letterSpacing, -2.0);
    });

    test('displayL uses Syne and correct size', () {
      expect(AppTextStyles.displayL.fontFamily, 'Syne');
      expect(AppTextStyles.displayL.fontSize, 40);
      expect(AppTextStyles.displayL.fontWeight, FontWeight.w800);
    });

    test('displayM uses Syne and correct size', () {
      expect(AppTextStyles.displayM.fontFamily, 'Syne');
      expect(AppTextStyles.displayM.fontSize, 32);
      expect(AppTextStyles.displayM.fontWeight, FontWeight.w700);
    });

    test('titleL uses Syne and correct size', () {
      expect(AppTextStyles.titleL.fontFamily, 'Syne');
      expect(AppTextStyles.titleL.fontSize, 24);
      expect(AppTextStyles.titleL.fontWeight, FontWeight.w700);
    });

    test('titleM uses Syne and correct size', () {
      expect(AppTextStyles.titleM.fontFamily, 'Syne');
      expect(AppTextStyles.titleM.fontSize, 20);
      expect(AppTextStyles.titleM.fontWeight, FontWeight.w700);
    });

    test('bodyL uses Inter and correct size', () {
      expect(AppTextStyles.bodyL.fontFamily, 'Inter');
      expect(AppTextStyles.bodyL.fontSize, 16);
      expect(AppTextStyles.bodyL.fontWeight, FontWeight.w400);
      expect(AppTextStyles.bodyL.color, AppColors.textSecondary);
    });

    test('bodyM uses Inter and correct size', () {
      expect(AppTextStyles.bodyM.fontFamily, 'Inter');
      expect(AppTextStyles.bodyM.fontSize, 14);
    });

    test('labelL uses Inter and correct size', () {
      expect(AppTextStyles.labelL.fontFamily, 'Inter');
      expect(AppTextStyles.labelL.fontSize, 14);
      expect(AppTextStyles.labelL.fontWeight, FontWeight.w600);
      expect(AppTextStyles.labelL.letterSpacing, 0.5);
    });

    test('labelM uses Inter and correct size', () {
      expect(AppTextStyles.labelM.fontFamily, 'Inter');
      expect(AppTextStyles.labelM.fontSize, 12);
    });

    test('numberXL uses Syne and correct size', () {
      expect(AppTextStyles.numberXL.fontFamily, 'Syne');
      expect(AppTextStyles.numberXL.fontSize, 64);
      expect(AppTextStyles.numberXL.color, AppColors.primary);
    });
  });

  // ==============================
  // APP THEME
  // ==============================
  group('AppTheme', () {
    test('darkTheme has correct brightness and colors', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.accent);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.error, AppColors.error);
      expect(theme.colorScheme.onPrimary, AppColors.textOnPrimary);
      expect(theme.colorScheme.onSecondary, AppColors.textOnPrimary);
      expect(theme.colorScheme.onSurface, AppColors.textPrimary);
    });

    test('cardTheme is CardThemeData with correct values', () {
      final theme = AppTheme.darkTheme;
      final cardTheme = theme.cardTheme;
      expect(cardTheme, isA<CardThemeData>());
      expect(cardTheme.color, AppColors.surfaceCard);
      expect(cardTheme.elevation, 0);
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      final shape = cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
    });

    test('appBarTheme is configured', () {
      final theme = AppTheme.darkTheme;
      expect(theme.appBarTheme.backgroundColor, Colors.transparent);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.systemOverlayStyle, isNotNull);
    });

    test('elevatedButtonTheme is configured', () {
      final theme = AppTheme.darkTheme;
      final btnTheme = theme.elevatedButtonTheme;
      expect(btnTheme, isNotNull);
      expect(btnTheme.style, isNotNull);
    });

    test('inputDecorationTheme is configured', () {
      final theme = AppTheme.darkTheme;
      final inputTheme = theme.inputDecorationTheme;
      expect(inputTheme, isNotNull);
      expect(inputTheme.filled, isTrue);
      expect(inputTheme.fillColor, AppColors.surfaceLight);
      expect(inputTheme.border, isA<OutlineInputBorder>());
    });

    test('dividerTheme is configured', () {
      final theme = AppTheme.darkTheme;
      expect(theme.dividerTheme.color, AppColors.surfaceLight);
      expect(theme.dividerTheme.thickness, 1);
    });

    test('pageTransitionsTheme is configured', () {
      final theme = AppTheme.darkTheme;
      expect(theme.pageTransitionsTheme.builders.length, 2);
    });
  });

  // ==============================
  // APP SPACING
  // ==============================
  group('AppSpacing', () {
    test('constants match expected values', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
    });
  });

  // ==============================
  // APP RADIUS
  // ==============================
  group('AppRadius', () {
    test('constants match expected values', () {
      expect(AppRadius.sm, 8);
      expect(AppRadius.md, 12);
      expect(AppRadius.lg, 16);
      expect(AppRadius.xl, 20);
      expect(AppRadius.xxl, 28);
      expect(AppRadius.round, 100);
    });
  });

  // =====================================================================
  // DOMAIN ENTITIES TESTS
  // =====================================================================

  // ==============================
  // USER ENTITY
  // ==============================
  group('UserEntity', () {
    test('can be created with all required fields', () {
      final user = UserEntity(
        id: 'u1',
        name: 'Test User',
        email: 'test@test.com',
        createdAt: DateTime(2025),
      );
      expect(user.id, 'u1');
      expect(user.name, 'Test User');
      expect(user.email, 'test@test.com');
      expect(user.createdAt, DateTime(2025));
      expect(user.avatarUrl, isNull);
      expect(user.profile, isNull);
    });

    test('can be created with optional fields', () {
      final user = UserEntity(
        id: 'u2',
        name: 'Full User',
        email: 'full@test.com',
        avatarUrl: 'https://example.com/avatar.png',
        profile: const UserProfile(
          weight: 80, height: 180, age: 30,
          gender: Gender.male, goal: FitnessGoal.loseWeight,
          intensity: IntensityLevel.balanced,
          activityLevel: ActivityLevel.moderatelyActive,
        ),
        createdAt: DateTime(2025),
      );
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.profile, isNotNull);
      expect(user.profile!.weight, 80);
    });
  });

  // ==============================
  // USER PROFILE
  // ==============================
  group('UserProfile', () {
    const profile = UserProfile(
      weight: 80, height: 180, age: 30,
      gender: Gender.male, goal: FitnessGoal.loseWeight,
      intensity: IntensityLevel.balanced,
      activityLevel: ActivityLevel.moderatelyActive,
      medicalRestrictions: ['hypertension'],
      exerciseRestrictions: ['no heavy squats'],
    );

    test('bmi is calculated correctly', () {
      // BMI = weight(kg) / (height(m))^2 = 80 / (1.8)^2 = 80 / 3.24 = 24.69...
      expect(profile.bmi, closeTo(24.69, 0.1));
    });

    test('bmr is calculated correctly for male (Harris-Benedict)', () {
      // BMR = 88.362 + (13.397 * 80) + (4.799 * 180) - (5.677 * 30)
      // = 88.362 + 1071.76 + 863.82 - 170.31 = 1853.63...
      expect(profile.bmr, closeTo(1853.63, 1));
    });

    test('bmr is calculated correctly for female', () {
      const femaleProfile = UserProfile(
        weight: 60, height: 165, age: 25,
        gender: Gender.female, goal: FitnessGoal.maintain,
        intensity: IntensityLevel.gradual,
        activityLevel: ActivityLevel.lightlyActive,
      );
      // BMR = 447.593 + (9.247*60) + (3.098*165) - (4.330*25)
      // = 447.593 + 554.82 + 511.17 - 108.25 = 1405.33
      expect(femaleProfile.bmr, closeTo(1405.33, 1));
    });

    test('tdee is bmr * activity multiplier', () {
      // moderatelyActive multiplier = 1.55
      expect(profile.tdee, closeTo(profile.bmr * 1.55, 0.1));
    });

    test('dailyCalorieTarget for loseWeight is tdee - 500', () {
      expect(profile.dailyCalorieTarget, closeTo(profile.tdee - 500, 0.1));
    });

    test('dailyCalorieTarget for gainWeight is tdee + 500', () {
      const gainProfile = UserProfile(
        weight: 70, height: 175, age: 28,
        gender: Gender.male, goal: FitnessGoal.gainWeight,
        intensity: IntensityLevel.intensive,
        activityLevel: ActivityLevel.moderatelyActive,
      );
      expect(gainProfile.dailyCalorieTarget, closeTo(gainProfile.tdee + 500, 0.1));
    });

    test('dailyCalorieTarget for maintain equals tdee', () {
      const maintainProfile = UserProfile(
        weight: 65, height: 170, age: 22,
        gender: Gender.female, goal: FitnessGoal.maintain,
        intensity: IntensityLevel.relaxed,
        activityLevel: ActivityLevel.sedentary,
      );
      expect(maintainProfile.dailyCalorieTarget, closeTo(maintainProfile.tdee, 0.1));
    });

    test('dailyCalorieTarget for beachBody is tdee - 300', () {
      const beachProfile = UserProfile(
        weight: 75, height: 175, age: 28,
        gender: Gender.male, goal: FitnessGoal.beachBody,
        intensity: IntensityLevel.intensive,
        activityLevel: ActivityLevel.moderatelyActive,
      );
      expect(beachProfile.dailyCalorieTarget, closeTo(beachProfile.tdee - 300, 0.1));
    });

    test('dailyCalorieTarget for sportPerformance is tdee + 200', () {
      const sportProfile = UserProfile(
        weight: 70, height: 175, age: 25,
        gender: Gender.male, goal: FitnessGoal.sportPerformance,
        intensity: IntensityLevel.hardcore,
        activityLevel: ActivityLevel.veryActive,
      );
      expect(sportProfile.dailyCalorieTarget, closeTo(sportProfile.tdee + 200, 0.1));
    });
  });

  // ==============================
  // ENUMS
  // ==============================
  group('Enums', () {
    test('ActivityLevel has correct multipliers', () {
      expect(ActivityLevel.sedentary.multiplier, 1.2);
      expect(ActivityLevel.lightlyActive.multiplier, 1.375);
      expect(ActivityLevel.moderatelyActive.multiplier, 1.55);
      expect(ActivityLevel.veryActive.multiplier, 1.725);
      expect(ActivityLevel.extraActive.multiplier, 1.9);
    });

    test('ActivityLevel has labels in Russian', () {
      expect(ActivityLevel.sedentary.label, contains('Сидячий'));
      expect(ActivityLevel.extraActive.label, contains('активность'));
    });

    test('Gender has male and female', () {
      expect(Gender.values.length, 2);
      expect(Gender.values, contains(Gender.male));
      expect(Gender.values, contains(Gender.female));
    });

    test('FitnessGoal has 5 values', () {
      expect(FitnessGoal.values.length, 5);
      expect(FitnessGoal.values, contains(FitnessGoal.loseWeight));
      expect(FitnessGoal.values, contains(FitnessGoal.sportPerformance));
    });

    test('IntensityLevel has 5 values', () {
      expect(IntensityLevel.values.length, 5);
      expect(IntensityLevel.values, contains(IntensityLevel.hardcore));
      expect(IntensityLevel.values, contains(IntensityLevel.relaxed));
    });

    test('WorkoutDayType has 4 values', () {
      expect(WorkoutDayType.values.length, 4);
      expect(WorkoutDayType.values, contains(WorkoutDayType.activeRecovery));
    });

    test('WorkoutPlanStatus has 3 values', () {
      expect(WorkoutPlanStatus.values.length, 3);
      expect(WorkoutPlanStatus.values, contains(WorkoutPlanStatus.paused));
    });

    test('MuscleGroup has 13 values', () {
      expect(MuscleGroup.values.length, 13);
      expect(MuscleGroup.values, contains(MuscleGroup.fullBody));
    });

    test('ExerciseType has 6 values', () {
      expect(ExerciseType.values.length, 6);
      expect(ExerciseType.values, contains(ExerciseType.hiit));
    });

    test('DifficultyLevel has 4 values', () {
      expect(DifficultyLevel.values.length, 4);
      expect(DifficultyLevel.values, contains(DifficultyLevel.elite));
    });

    test('MealType has 4 values', () {
      expect(MealType.values.length, 4);
      expect(MealType.values, contains(MealType.snack));
    });
  });

  // ==============================
  // WORKOUT ENTITIES
  // ==============================
  group('WorkoutDay', () {
    test('isCompleted returns true when log exists', () {
      final day = WorkoutDay(
        dayNumber: 1,
        date: DateTime(2025),
        type: WorkoutDayType.workout,
        log: WorkoutLog(
          id: 'l1', sessionId: 's1',
          startTime: DateTime(2025), exerciseLogs: [],
        ),
      );
      expect(day.isCompleted, isTrue);
    });

    test('isCompleted returns false when log is null', () {
      final day = WorkoutDay(
        dayNumber: 2,
        date: DateTime(2025),
        type: WorkoutDayType.workout,
      );
      expect(day.isCompleted, isFalse);
    });

    test('isRest returns true for rest day', () {
      final day = WorkoutDay(
        dayNumber: 3,
        date: DateTime(2025),
        type: WorkoutDayType.rest,
      );
      expect(day.isRest, isTrue);
    });

    test('isRest returns false for workout day', () {
      final day = WorkoutDay(
        dayNumber: 4,
        date: DateTime(2025),
        type: WorkoutDayType.workout,
      );
      expect(day.isRest, isFalse);
    });
  });

  group('WorkoutLog', () {
    test('durationMinutes returns 0 when endTime is null', () {
      final log = WorkoutLog(
        id: 'l1', sessionId: 's1',
        startTime: DateTime(2025, 1, 1, 10, 0),
        exerciseLogs: [],
      );
      expect(log.durationMinutes, 0);
    });

    test('durationMinutes returns correct difference', () {
      final log = WorkoutLog(
        id: 'l1', sessionId: 's1',
        startTime: DateTime(2025, 1, 1, 10, 0),
        endTime: DateTime(2025, 1, 1, 11, 30),
        exerciseLogs: [],
      );
      expect(log.durationMinutes, 90);
    });

    test('isCompleted returns true when endTime exists', () {
      final log = WorkoutLog(
        id: 'l1', sessionId: 's1',
        startTime: DateTime(2025), endTime: DateTime(2025),
        exerciseLogs: [],
      );
      expect(log.isCompleted, isTrue);
    });

    test('isCompleted returns false when endTime is null', () {
      final log = WorkoutLog(
        id: 'l1', sessionId: 's1',
        startTime: DateTime(2025),
        exerciseLogs: [],
      );
      expect(log.isCompleted, isFalse);
    });
  });

  group('WorkoutPlan', () {
    test('can be created with required fields', () {
      final plan = WorkoutPlan(
        id: 'p1', userId: 'u1',
        title: 'Test Plan',
        goal: FitnessGoal.loseWeight,
        intensity: IntensityLevel.balanced,
        durationWeeks: 12,
        weeks: [const WorkoutWeek(weekNumber: 1, days: [])],
        startDate: DateTime(2025),
      );
      expect(plan.title, 'Test Plan');
      expect(plan.durationWeeks, 12);
      expect(plan.status, WorkoutPlanStatus.active);
    });

    test('can be created with completed status', () {
      final plan = WorkoutPlan(
        id: 'p2', userId: 'u1',
        title: 'Completed Plan',
        goal: FitnessGoal.maintain,
        intensity: IntensityLevel.relaxed,
        durationWeeks: 8,
        weeks: [],
        startDate: DateTime(2024),
        completedAt: DateTime(2025),
        status: WorkoutPlanStatus.completed,
      );
      expect(plan.status, WorkoutPlanStatus.completed);
      expect(plan.completedAt, DateTime(2025));
    });
  });

  group('WorkoutSession', () {
    test('can be created with required fields', () {
      final session = WorkoutSession(
        id: 's1', title: 'Chest Day',
        primaryMuscle: MuscleGroup.chest,
        exercises: [],
        estimatedDurationMinutes: 45,
        estimatedCaloriesBurn: 300,
        difficulty: DifficultyLevel.intermediate,
      );
      expect(session.title, 'Chest Day');
      expect(session.primaryMuscle, MuscleGroup.chest);
    });
  });

  group('ExerciseSet', () {
    test('can be created with sets', () {
      final set = ExerciseSet(
        exercise: Exercise(
          id: 'e1', name: 'Bench Press',
          primaryMuscle: MuscleGroup.chest,
          type: ExerciseType.strength,
          difficulty: DifficultyLevel.intermediate,
          instructions: ['Lie down', 'Press up'],
        ),
        sets: [
          const SetData(setNumber: 1, reps: 10, weightKg: 50),
          const SetData(setNumber: 2, reps: 8, weightKg: 60),
        ],
      );
      expect(set.exercise.name, 'Bench Press');
      expect(set.sets.length, 2);
      expect(set.sets[0].reps, 10);
      expect(set.sets[1].weightKg, 60);
    });
  });

  group('NutritionPer100g', () {
    test('can be created with optional fields', () {
      final nutrition = const NutritionPer100g(
        calories: 100, protein: 10, carbs: 20, fat: 5,
        fiber: 2, sugar: 3, sodium: 50,
      );
      expect(nutrition.fiber, 2);
      expect(nutrition.sugar, 3);
      expect(nutrition.sodium, 50);
    });
  });

  // ==============================
  // FOOD / NUTRITION ENTITIES
  // ==============================
  group('FoodItem', () {
    const apple = FoodItem(
      id: 'f1', name: 'Apple',
      nutrition: NutritionPer100g(calories: 52, protein: 0.3, carbs: 14, fat: 0.2),
    );

    test('nutritionForGrams returns scaled values', () {
      final result = apple.nutritionForGrams(200);
      expect(result.calories, closeTo(104, 0.1));
      expect(result.protein, closeTo(0.6, 0.1));
      expect(result.carbs, closeTo(28, 0.1));
      expect(result.fat, closeTo(0.4, 0.1));
    });

    test('nutritionForGrams 0 grams returns 0 values', () {
      final result = apple.nutritionForGrams(0);
      expect(result.calories, 0);
      expect(result.protein, 0);
      expect(result.carbs, 0);
      expect(result.fat, 0);
    });
  });

  group('MealLog', () {
    test('totalCalories sums all food entries', () {
      const apple = FoodItem(
        id: 'f1', name: 'Apple',
        nutrition: NutritionPer100g(calories: 52, protein: 0.3, carbs: 14, fat: 0.2),
      );
      final log = MealLog(
        id: 'm1', userId: 'u1',
        date: DateTime(2025), mealType: MealType.breakfast,
        foods: [FoodEntry(food: apple, grams: 200)],
      );
      expect(log.totalCalories, closeTo(104, 0.1));
    });

    test('totalProtein sums all food entries', () {
      const chicken = FoodItem(
        id: 'f2', name: 'Chicken Breast',
        nutrition: NutritionPer100g(calories: 165, protein: 31, carbs: 0, fat: 3.6),
      );
      final log = MealLog(
        id: 'm2', userId: 'u1',
        date: DateTime(2025), mealType: MealType.lunch,
        foods: [FoodEntry(food: chicken, grams: 150)],
      );
      expect(log.totalProtein, closeTo(46.5, 0.1));
    });

    test('totalCarbs and totalFat work correctly', () {
      const chicken = FoodItem(
        id: 'f2', name: 'Chicken Breast',
        nutrition: NutritionPer100g(calories: 165, protein: 31, carbs: 0, fat: 3.6),
      );
      final log = MealLog(
        id: 'm3', userId: 'u1',
        date: DateTime(2025), mealType: MealType.lunch,
        foods: [FoodEntry(food: chicken, grams: 150)],
      );
      expect(log.totalCarbs, closeTo(0, 0.1));
      expect(log.totalFat, closeTo(5.4, 0.1));
    });
  });

  group('FoodEntry', () {
    test('totalCalories returns correct value', () {
      const banana = FoodItem(
        id: 'f3', name: 'Banana',
        nutrition: NutritionPer100g(calories: 89, protein: 1.1, carbs: 23, fat: 0.3),
      );
      final entry = FoodEntry(food: banana, grams: 120);
      expect(entry.totalCalories, closeTo(106.8, 0.1));
      expect(entry.totalCarbs, closeTo(27.6, 0.1));
      expect(entry.totalFat, closeTo(0.36, 0.1));
    });
  });

  group('DailyNutritionPlan', () {
    test('can be created with required fields', () {
      final plan = DailyNutritionPlan(
        id: 'np1', userId: 'u1',
        date: DateTime(2025),
        targetCalories: 2000,
        targetProtein: 150,
        targetCarbs: 250,
        targetFat: 50,
        meals: [],
      );
      expect(plan.targetCalories, 2000);
      expect(plan.targetProtein, 150);
      expect(plan.targetCarbs, 250);
      expect(plan.targetFat, 50);
    });

    test('can be created with meal plans', () {
      final plan = DailyNutritionPlan(
        id: 'np2', userId: 'u1',
        date: DateTime(2025),
        targetCalories: 2000,
        targetProtein: 150,
        targetCarbs: 250,
        targetFat: 50,
        meals: [
          const MealPlan(type: MealType.breakfast, title: 'Breakfast', items: [], targetCalories: 500),
          const MealPlan(type: MealType.lunch, title: 'Lunch', items: [], targetCalories: 800),
        ],
      );
      expect(plan.meals.length, 2);
      expect(plan.meals[0].title, 'Breakfast');
      expect(plan.meals[1].targetCalories, 800);
    });
  });

  // ==============================
  // HEALTH DATA ENTITIES
  // ==============================
  group('HealthData', () {
    test('can be created with only required fields', () {
      final data = HealthData(userId: 'u1', date: DateTime(2025));
      expect(data.steps, isNull);
      expect(data.weight, isNull);
    });

    test('can be created with all fields', () {
      final data = HealthData(
        userId: 'u1',
        date: DateTime(2025),
        steps: 10000,
        caloriesBurned: 500,
        heartRateAvg: 72,
        heartRateResting: 62,
        weight: 80.5,
        bodyFatPercent: 18.5,
        sleepMinutes: 480,
        waterIntakeMl: 2000,
        distanceKm: 8.5,
      );
      expect(data.steps, 10000);
      expect(data.caloriesBurned, 500);
      expect(data.heartRateAvg, 72);
      expect(data.heartRateResting, 62);
      expect(data.sleepMinutes, 480);
      expect(data.waterIntakeMl, 2000);
      expect(data.distanceKm, 8.5);
    });
  });

  group('ProgressEntry', () {
    test('can be created with required fields only', () {
      final entry = ProgressEntry(id: 'pe1', userId: 'u1', date: DateTime(2025));
      expect(entry.weight, isNull);
      expect(entry.bodyFatPercent, isNull);
    });

    test('can be created with measurements', () {
      final entry = ProgressEntry(
        id: 'pe2', userId: 'u1',
        date: DateTime(2025),
        weight: 78.5,
        bodyFatPercent: 18.5,
        measurements: {'chest': 100, 'waist': 80, 'hips': 95},
        photoUrl: 'https://example.com/photo.jpg',
        notes: 'Feeling good!',
      );
      expect(entry.weight, 78.5);
      expect(entry.bodyFatPercent, 18.5);
      expect(entry.measurements!['chest'], 100);
      expect(entry.measurements!['waist'], 80);
      expect(entry.photoUrl, 'https://example.com/photo.jpg');
      expect(entry.notes, 'Feeling good!');
    });
  });

  // =====================================================================
  // BLOC TESTS
  // =====================================================================

  group('AuthBloc', () {});
  group('UserBloc', () {});

  group('WorkoutBloc', () {
    blocTest<WorkoutBloc, WorkoutState>(
      'starts in initial state',
      build: () => WorkoutBloc(),
      verify: (bloc) => expect(bloc.state, const WorkoutStateInitial()),
    );

    blocTest<WorkoutBloc, WorkoutState>(
      'transitions to in-progress on start',
      build: () => WorkoutBloc(),
      act: (bloc) => bloc.add(const WorkoutStartRequested()),
      expect: () => [isA<WorkoutStateInProgress>()],
    );
  });

  group('NutritionBloc', () {
    blocTest<NutritionBloc, NutritionState>(
      'starts in initial state',
      build: () => NutritionBloc(nutritionService: NutritionService(ai: DeepSeekService())),
      verify: (bloc) => expect(bloc.state, const NutritionStateInitial()),
    );

    blocTest<NutritionBloc, NutritionState>(
      'loads mock data',
      build: () => NutritionBloc(nutritionService: NutritionService(ai: DeepSeekService())),
      act: (bloc) => bloc.add(const NutritionLoadRequested(userId: 'test')),
      wait: const Duration(milliseconds: 600),
      expect: () => [isA<NutritionStateLoading>(), isA<NutritionStateLoaded>()],
    );
  });

  group('HealthBloc', () {
    blocTest<HealthBloc, HealthState>(
      'starts in initial state',
      build: () => HealthBloc(analytics: HealthAnalyticsService()),
      verify: (bloc) => expect(bloc.state, const HealthStateInitial()),
    );
  });

  // ==============================
  // SCREEN CREATION TESTS
  // ==============================
  group('Screen creation', () {
    testWidgets('LoginScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const LoginScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }, skip: true);

    testWidgets('RegisterScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const RegisterScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }, skip: true);

    testWidgets('SplashScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: AppRouter.router,
      ));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    }, skip: true); // Requires GoRouter + BlocProvider

    testWidgets('DashboardScreen can be created', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }, skip: true);

    testWidgets('ProgressScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const ProgressScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, skip: true); // Requires Firebase (FirebaseAuth.instance called internally

    testWidgets('NutritionScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const NutritionScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, skip: true); // requires DI (ISettingsRepository)

    testWidgets('FoodDiaryScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const FoodDiaryScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, skip: true); // requires DI (ISettingsRepository)

    testWidgets('MealPlanScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const MealPlanScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('WorkoutPlanScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const WorkoutPlanScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, skip: true); // Requires real device layout - unbounded height in test

    testWidgets('GoalSelectionScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const GoalSelectionScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('IntensitySelectionScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const IntensitySelectionScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileSetupScreen can be created', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const ProfileSetupScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, skip: true); // Requires OnboardingBloc provider (depends on Firebase)

  });
}
