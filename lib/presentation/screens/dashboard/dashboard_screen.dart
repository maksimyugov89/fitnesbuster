import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';
import 'package:fitnesbuster/bloc/ai/ai_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/core/services/recovery_score_service.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/core/services/social_service.dart' show SocialService, FriendRequest;
import 'package:fitnesbuster/core/router/app_router.dart' show AppRouter;
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _headerCtrl;
  late AnimationController _ringsCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double> _ringsAnim;

  // Will be populated by HealthBloc / HealthConnect after sync
  int _steps = 0;
  final int _targetSteps = 10000;
  double _caloriesBurned = 0;
  final double _targetCalories = 680;
  double _waterMl = 0;
  final double _targetWater = 2500;
  double _weight = 0;
  int _heartRate = 0;
  int _streak = 0;
  String? _workoutPlanJson;
  String? _mealPlanJson;
  Timer? _plansTimer;
  bool _testWeekCompleted = false;
  bool _testWeekCheckDone = false;

  // Nutrition data read from SharedPreferences (written by NutritionScreen)
  int _eatenCal = 0;
  int _targetNutCal = 0;

  // Weekly workout history (Mon=0 … Sun=6), true = done
  List<bool> _weekWorkouts = List.filled(7, false);
  // Workout kcal accumulated today from WorkoutSession
  int _workoutKcalToday = 0;

  // Recovery score (computed from overnight health data)
  RecoveryScore? _recoveryScore;

  // Gamification
  UserLevel? _userLevel;
  List<_DailyTask> _dailyTasks = [];

  // Social
  int _pendingRequests = 0;
  StreamSubscription<List<FriendRequest>>? _requestsSub;

  // User identity for AppBar
  String _userName = '';
  int _avatarPresetIndex = -1;
  String _avatarCustomPath = '';

  // true when any data source (HC or SharedPrefs) has real values
  bool get _hasSyncedData =>
      _steps > 0 || _caloriesBurned > 0 || _workoutKcalToday > 0 || _waterMl > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _ringsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _cardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _ringsAnim = CurvedAnimation(parent: _ringsCtrl, curve: Curves.easeOutCubic);

    Future.delayed(const Duration(milliseconds: 300), () {
      _ringsCtrl.forward();
      _cardsCtrl.forward();
    });

    _syncHealthData();
    _calculateStreak();
    _loadPlansFromRepo();
    _loadNutritionData();
    _loadWeeklyData();
    _loadAvatarAndName();
    _loadGamificationData();
    _requestsSub = sl<SocialService>().incomingRequestsStream().listen((list) {
      if (mounted) setState(() => _pendingRequests = list.length);
    });
  }

  Future<void> _loadAvatarAndName() async {
    // Name from Firebase Auth (fastest, no Firestore round-trip)
    final fbUser = FirebaseAuth.instance.currentUser;
    final name = fbUser?.displayName ?? fbUser?.email?.split('@').first ?? '';

    final settings = sl<ISettingsRepository>();
    final mode = await settings.getAvatarMode() ?? 'initials';
    int presetIdx = -1;
    String customPath = '';
    if (mode == 'preset') {
      presetIdx = await settings.getAvatarPresetIndex() ?? -1;
    } else if (mode == 'custom') {
      final path = await settings.getAvatarCustomPath() ?? '';
      if (path.isNotEmpty && File(path).existsSync()) customPath = path;
    }

    if (mounted) {
      setState(() {
        _userName = name;
        _avatarPresetIndex = presetIdx;
        _avatarCustomPath = customPath;
      });
    }
  }

  Future<void> _loadNutritionData() async {
    try {
      final settings = sl<ISettingsRepository>();
      final k = todayKey();
      final eaten = await settings.getEatenCal(k);
      final target = await settings.getTargetCal(k);
      if (mounted) setState(() { _eatenCal = eaten; _targetNutCal = target; });
    } catch (e, st) {
      appLogger.w('Dashboard: load nutrition prefs', error: e, stackTrace: st);
    }
  }

  Future<void> _loadWeeklyData() async {
    try {
      final settings = sl<ISettingsRepository>();
      final now = DateTime.now();
      // Monday-anchored week: weekday 1=Mon … 7=Sun → index 0…6
      final todayIndex = now.weekday - 1;
      final week = List<bool>.filled(7, false);
      int kcalToday = 0;
      int trackerWater = 0;

      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: todayIndex - i));
        final k = dateKey(day);
        week[i] = await settings.getWorkoutDone(k);
        if (i == todayIndex) {
          kcalToday = await settings.getWorkoutKcal(k);
          trackerWater = await settings.getWaterMl(k);
        }
      }

      if (mounted) {
        setState(() {
          _weekWorkouts = week;
          _workoutKcalToday = kcalToday;
          // Merge tracker water with Health Connect water (take max to avoid double-counting)
          if (trackerWater > _waterMl) _waterMl = trackerWater.toDouble();
          // Add workout kcal to burned calories if health connect didn't pick it up
          if (kcalToday > 0 && _caloriesBurned < kcalToday) {
            _caloriesBurned = (_caloriesBurned + kcalToday).toDouble();
          }
        });
      }
    } catch (e, st) {
      appLogger.w('Dashboard: load weekly data', error: e, stackTrace: st);
    }
  }

  void _loadPlansFromRepo() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final repo = sl<UserRepository>();
    // Check test week completion once on load
    repo.isTestWeekCompleted(userId).then((completed) {
      if (mounted) {
        setState(() {
          _testWeekCompleted = completed;
          _testWeekCheckDone = true;
        });
      }
    }).catchError((_) {
      // При ошибке показываем баннер на всякий случай (не скрываем)
      if (mounted) {
        setState(() => _testWeekCheckDone = true);
      }
    });
    // Try immediately, then retry every 2 seconds up to 5 times
    int attempts = 0;
    _plansTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      try {
        final plans = await repo.getAiPlans(userId);
        if (plans['workoutPlan'] != null || plans['mealPlan'] != null) {
          if (mounted) {
            setState(() {
              _workoutPlanJson = plans['workoutPlan'];
              _mealPlanJson = plans['mealPlan'];
            });
          }
          timer.cancel();
          _plansTimer = null;
        }
      } catch (e, st) {
        appLogger.w('Dashboard: load AI plans (retry)', error: e, stackTrace: st);
      }
      if (attempts >= 5) {
        timer.cancel();
        _plansTimer = null;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncHealthData();
      _loadNutritionData();
      _loadWeeklyData();
      _loadAvatarAndName();
      _loadGamificationData();
    }
  }

  Future<void> _syncHealthData() async {
    try {
      final hc = sl<HealthConnectService>();
      await hc.initialize();
      final data = await hc.readAllToday();
      if (mounted) {
        setState(() {
          if (data.steps > 0) _steps = data.steps;
          if (data.caloriesBurned > 0) _caloriesBurned = data.caloriesBurned;
          if (data.heartRateAvg != null) _heartRate = data.heartRateAvg!;
          // Water: only override tracker value if HC has more
          if ((data.waterIntakeMl ?? 0) > _waterMl) _waterMl = data.waterIntakeMl!;
          if (data.weight != null && data.weight! > 0) {
            final newWeight = data.weight!;
            if ((newWeight - _weight).abs() > 1.0 && _weight > 0) {
              _triggerPlanRegeneration(weightChanged: true, newWeight: newWeight);
            }
            _weight = newWeight;
          }
          // Recovery Score from overnight sleep + HRV + resting HR
          _recoveryScore = RecoveryScoreService.calculate(
            sleepMinutes: data.sleepMinutes,
            hrv: data.heartRateVariability,
            restingHr: data.restingHeartRate,
          );
        });
      }
    } catch (e, st) {
      appLogger.w('Dashboard: sync health data', error: e, stackTrace: st);
    }
    // Fallback: load weight from user profile if HC had no data
    if (_weight == 0) _loadWeightFromProfile();
    await _loadManualData();
    // Re-evaluate daily tasks now that _steps is updated from Health Connect
    await _loadGamificationData();
  }

  Future<void> _loadWeightFromProfile() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthStateAuthenticated) {
        final w = authState.user.profile?.weight ?? 0;
        if (w > 0 && mounted) setState(() => _weight = w);
      }
    } catch (e, st) {
      appLogger.w('Dashboard: load weight from profile', error: e, stackTrace: st);
    }
  }

  Future<void> _calculateStreak() async {
    try {
      final settings = sl<ISettingsRepository>();
      final now = DateTime.now();
      int streak = 0;
      for (int i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        final k = dateKey(d);
        final done = await settings.getWorkoutDone(k);
        if (done) {
          streak++;
        } else if (i > 0) {
          // Allow one missed day today (workout not yet done)
          break;
        }
      }
      if (mounted) setState(() => _streak = streak);
    } catch (e, st) {
      appLogger.w('Dashboard: calculate streak', error: e, stackTrace: st);
    }
  }

  Future<void> _loadGamificationData() async {
    try {
      final xp = await sl<IGamificationService>().getTotalXp();
      final settings = sl<ISettingsRepository>();
      final k = todayKey();

      // Auto-check daily tasks from today's stored data
      final workoutDone   = await settings.getWorkoutDone(k);
      final waterMl       = await settings.getWaterMl(k);
      final manualSteps   = await settings.getManualSteps(k);
      final steps         = manualSteps > 0 ? manualSteps : _steps;
      final mealsRaw      = await settings.getMealsDone(k);
      final eatenCal      = await settings.getEatenCal(k);
      final allMealsDone  = mealsRaw.isNotEmpty && eatenCal > 0;

      final tasks = [
        _DailyTask(text: 'Выполни тренировку',      xp: 100, done: workoutDone),
        _DailyTask(text: 'Выпей норму воды (2 л)',  xp: 20,  done: waterMl >= 2000),
        _DailyTask(text: 'Запиши все приёмы пищи',  xp: 30,  done: allMealsDone),
        _DailyTask(text: 'Пройди 8 000 шагов',      xp: 40,  done: steps >= 8000),
      ];

      if (mounted) {
        setState(() {
          _userLevel   = GamificationService.computeLevel(xp);
          _dailyTasks  = tasks;
        });
      }
    } catch (e, st) {
      appLogger.w('Dashboard: load gamification data', error: e, stackTrace: st);
    }
  }

  void _triggerPlanRegeneration({bool weightChanged = false, double? newWeight}) {
    final userState = context.read<UserBloc>().state;
    if (userState is! UserStateLoaded || userState.user.profile == null) return;
    final profile = userState.user.profile!;
    context.read<AiBloc>().add(AiGenerateWorkoutPlan(profile: profile));
    context.read<AiBloc>().add(AiGenerateMealPlan(profile: profile));
    if (weightChanged && newWeight != null && newWeight > 0) {
      _recalculateTdee(profile: profile, newWeight: newWeight);
    }
  }

  Future<void> _recalculateTdee({
    required dynamic profile,
    required double newWeight,
  }) async {
    try {
      // Use the profile's own TDEE formula with updated weight via copyWith
      final updated = profile.copyWith(weight: newWeight);
      final target = updated.dailyCalorieTarget.round();
      await sl<ISettingsRepository>().setTargetCal(todayKey(), target);
      if (mounted) {
        setState(() => _targetNutCal = target);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Вес обновлён (${newWeight.toStringAsFixed(1)} кг) → цель: $target ккал/день',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF131619),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, st) {
      appLogger.w('Dashboard: recalculate TDEE', error: e, stackTrace: st);
    }
  }

  Future<void> _loadManualData() async {
    try {
      final settings = sl<ISettingsRepository>();
      final k = todayKey();
      if (_steps == 0) {
        final v = await settings.getManualSteps(k);
        if (v > 0 && mounted) { setState(() => _steps = v); }
      }
      if (_heartRate == 0) {
        final v = await settings.getManualHeartRate(k);
        if (v > 0 && mounted) { setState(() => _heartRate = v); }
      }
    } catch (e, st) {
      appLogger.w('Dashboard: load manual data', error: e, stackTrace: st);
    }
  }

  Future<void> _showManualInputSheet(String type) async {
    final isPulse = type == 'heartrate';
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualInputSheet(
        title: isPulse ? 'Пульс' : 'Шаги',
        unit: isPulse ? 'уд/мин' : 'шагов',
        hint: isPulse ? '72' : '8000',
        ctrl: ctrl,
      ),
    );
    if (result != null && result > 0) {
      final settings = sl<ISettingsRepository>();
      final k = todayKey();
      if (isPulse) {
        await settings.setManualHeartRate(k, result);
      } else {
        await settings.setManualSteps(k, result);
      }
      if (mounted) {
        setState(() {
          if (isPulse) { _heartRate = result; } else { _steps = result; }
        });
      }
    }
  }

  @override
  void dispose() {
    _plansTimer?.cancel();
    _requestsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _headerCtrl.dispose(); _ringsCtrl.dispose(); _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                if (_userLevel != null) ...[
                  _XpBarWidget(level: _userLevel!),
                  const SizedBox(height: 12),
                ],
                _ActivityRingsWidget(
                  animation: _ringsAnim,
                  steps: _steps,
                  targetSteps: _targetSteps,
                  caloriesBurned: _caloriesBurned,
                  targetCalories: _targetCalories,
                  waterMl: _waterMl,
                  targetWater: _targetWater,
                  hasSyncedData: _hasSyncedData,
                  onStepsTap: () => _showManualInputSheet('steps'),
                ),
                const SizedBox(height: 24),
                _QuickStatsWidget(
                  heartRate: _heartRate,
                  weight: _weight,
                  streak: _streak,
                  onHeartRateTap: () => _showManualInputSheet('heartrate'),
                ),
                if (_recoveryScore != null) ...[
                  const SizedBox(height: 16),
                  _RecoveryCardWidget(recoveryScore: _recoveryScore!),
                  if (_recoveryScore!.shouldReduceIntensity) ...[
                    const SizedBox(height: 10),
                    _AdaptationBanner(recoveryScore: _recoveryScore!),
                  ],
                ],
                if (_testWeekCheckDone && !_testWeekCompleted) ...[
                  const SizedBox(height: 24),
                  const _TestWeekBanner(),
                ],
                const SizedBox(height: 24),
                _NutritionSummaryWidget(
                  eatenCal: _eatenCal,
                  targetNutCal: _targetNutCal,
                  caloriesBurned: _caloriesBurned,
                ),
                const SizedBox(height: 24),
                _WeeklyChartWidget(
                  weekWorkouts: _weekWorkouts,
                  workoutKcalToday: _workoutKcalToday,
                  animation: _cardsCtrl,
                ),
                if (_dailyTasks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _DailyTasksWidget(tasks: _dailyTasks),
                ],
                const SizedBox(height: 24),
                const _AiChatCard(),
                const SizedBox(height: 24),
                _SocialCardWidget(pendingRequests: _pendingRequests),
                if (_workoutPlanJson != null || _mealPlanJson != null) ...[
                  const SizedBox(height: 24),
                  _AiPlansWidget(
                    workoutPlanJson: _workoutPlanJson,
                    mealPlanJson: _mealPlanJson,
                  ),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Avatar presets (mirrors profile_screen.dart)
  static const _presetEmoji = ['🏋️','🏃','🧘','🚴','🥊','🏊','🧗','🤸','⚡','🏆'];
  static const _presetColors = [
    [Color(0xFF6C63FF), Color(0xFF3D5AFE)],
    [Color(0xFF00BFA5), Color(0xFF00695C)],
    [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
    [Color(0xFFFF7043), Color(0xFFBF360C)],
    [Color(0xFFEF5350), Color(0xFFB71C1C)],
    [Color(0xFF29B6F6), Color(0xFF01579B)],
    [Color(0xFFFFCA28), Color(0xFFE65100)],
    [Color(0xFFEC407A), Color(0xFF880E4F)],
    [Color(0xFF26C6DA), Color(0xFF006064)],
    [Color(0xFF66BB6A), Color(0xFF1B5E20)],
  ];

  Widget _buildAppBarAvatar() {
    final p = AppTheme.of(context);
    const size = 42.0;

    // Custom photo
    if (_avatarCustomPath.isNotEmpty) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.primary.withValues(alpha: 0.5), width: 2),
        ),
        child: ClipOval(
          child: Image.file(
            File(_avatarCustomPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialsAvatar(size),
          ),
        ),
      );
    }

    // Preset emoji avatar
    if (_avatarPresetIndex >= 0 && _avatarPresetIndex < _presetEmoji.length) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _presetColors[_avatarPresetIndex],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: _presetColors[_avatarPresetIndex][0].withValues(alpha: 0.6), width: 2),
        ),
        child: Center(
          child: Text(_presetEmoji[_avatarPresetIndex], style: TextStyle(fontSize: 20)),
        ),
      );
    }

    // Initials fallback
    return _buildInitialsAvatar(size);
  }

  Widget _buildInitialsAvatar(double size) {
    final p = AppTheme.of(context);
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.primary, p.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Syne', fontSize: 18,
            fontWeight: FontWeight.w800, color: p.textOnPrimary,
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final p = AppTheme.of(context);
    final displayName = _userName.isNotEmpty ? _userName : 'Атлет';
    // Show only first name
    final firstName = displayName.split(' ').first;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      pinned: false,
      elevation: 0,
      expandedHeight: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: p.background),
      ),
      title: FadeTransition(
        opacity: _headerCtrl,
        child: Row(
          children: [
            // Greeting + name — left side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      fontSize: 12, color: p.textMuted, fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    firstName,
                    style: TextStyle(
                      fontFamily: 'Syne', fontSize: 20,
                      fontWeight: FontWeight.w800, color: p.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Avatar — right side
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: _buildAppBarAvatar(),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброе утро';
    if (hour < 17) return 'Добрый день';
    return 'Добрый вечер';
  }

}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

// ── Extracted StatelessWidget classes ────────────────────────────────────────

class _XpBarWidget extends StatelessWidget {
  final UserLevel level;
  const _XpBarWidget({required this.level});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final lvl = level;
    final color = p.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(child: Text(lvl.emoji, style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              'Ур. ${lvl.level} · ${lvl.name}',
              style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: p.textPrimary),
            ),
            const Spacer(),
            Text(
              lvl.isMaxLevel
                  ? '${lvl.totalXp} XP'
                  : '${lvl.xpInCurrentLevel} / ${lvl.xpNeededForNext} XP',
              style: TextStyle(fontSize: 10, color: p.textMuted),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lvl.progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ])),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.push('/achievements'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('🏅', style: TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

class _ActivityRingsWidget extends StatelessWidget {
  final Animation<double> animation;
  final int steps;
  final int targetSteps;
  final double caloriesBurned;
  final double targetCalories;
  final double waterMl;
  final double targetWater;
  final bool hasSyncedData;
  final VoidCallback onStepsTap;

  const _ActivityRingsWidget({
    required this.animation,
    required this.steps,
    required this.targetSteps,
    required this.caloriesBurned,
    required this.targetCalories,
    required this.waterMl,
    required this.targetWater,
    required this.hasSyncedData,
    required this.onStepsTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Row(children: [
          Text('Активность сегодня', style: AppTextStyles.titleM),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: p.surfaceLight, borderRadius: BorderRadius.circular(8)),
            child: Text('Сегодня', style: TextStyle(fontSize: 11, color: p.textMuted, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context2, __) => CustomPaint(
                size: const Size(160, 160),
                painter: _ActivityRingsPainter(
                  progress: animation.value,
                  steps: steps / targetSteps,
                  calories: caloriesBurned / targetCalories,
                  water: waterMl / targetWater,
                  stepsColor:    AppTheme.of(context2).accentOrange,
                  caloriesColor: AppTheme.of(context2).primary,
                  waterColor:    AppTheme.of(context2).accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: onStepsTap,
                child: _RingLegend(
                  color: p.accentOrange,
                  label: 'Шаги',
                  value: hasSyncedData ? '$steps' : '—',
                  total: '/$targetSteps',
                  unit: '',
                  editable: steps == 0,
                ),
              ),
              const SizedBox(height: 14),
              _RingLegend(color: p.primary, label: 'Калории', value: hasSyncedData ? '${caloriesBurned.toInt()}' : '—', total: '/${targetCalories.toInt()}', unit: ' ккал'),
              const SizedBox(height: 14),
              _RingLegend(color: p.accent, label: 'Вода', value: hasSyncedData ? '${waterMl.toInt()}' : '—', total: '/${targetWater.toInt()}', unit: ' мл'),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _QuickStatsWidget extends StatelessWidget {
  final int heartRate;
  final double weight;
  final int streak;
  final VoidCallback onHeartRateTap;

  const _QuickStatsWidget({
    required this.heartRate,
    required this.weight,
    required this.streak,
    required this.onHeartRateTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: onHeartRateTap,
        child: _StatCard(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFEF4444),
          label: 'Пульс',
          value: heartRate > 0 ? '$heartRate' : '—',
          unit: heartRate > 0 ? 'уд/мин' : '',
          subtitle: heartRate > 0 ? 'В норме' : '✏️ Ввести',
        ),
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
        icon: Icons.monitor_weight_outlined,
        iconColor: p.accentPurple,
        label: 'Вес',
        value: weight > 0 ? '$weight' : '—',
        unit: weight > 0 ? 'кг' : '',
        subtitle: weight > 0 ? 'Обновлено' : 'Нет данных',
        subtitleColor: p.textMuted,
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
        icon: Icons.local_fire_department_rounded,
        iconColor: p.accentOrange,
        label: 'Стрик',
        value: streak > 0 ? '$streak' : '—',
        unit: streak > 0 ? 'дней' : '',
        subtitle: streak > 0 ? '🔥 Продолжай!' : 'Нет данных',
        subtitleColor: streak > 0 ? p.accentOrange : p.textMuted,
      )),
    ]);
  }
}

class _TestWeekBanner extends StatelessWidget {
  const _TestWeekBanner();

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return GestureDetector(
      onTap: () => context.push('/test-week'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A2A3A), Color(0xFF0A1826)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.info.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: p.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('🎯', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text('Тестовая неделя', overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: p.info, borderRadius: BorderRadius.circular(6)),
                child: Text('СТАРТ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Заполни показатели для составления твоей программы', style: TextStyle(fontSize: 12, color: p.textSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              Flexible(child: _InfoPill('Индивидуально', p.info)),
              const SizedBox(width: 6),
              Flexible(child: _InfoPill('Под ваш график', p.info)),
              const SizedBox(width: 6),
              Flexible(child: _InfoPill('Без спешки', p.info)),
            ]),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, color: p.info, size: 18),
        ]),
      ),
    );
  }
}

class _NutritionSummaryWidget extends StatelessWidget {
  final int eatenCal;
  final int targetNutCal;
  final double caloriesBurned;

  const _NutritionSummaryWidget({
    required this.eatenCal,
    required this.targetNutCal,
    required this.caloriesBurned,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    int bmr = 0;
    final userState = context.read<UserBloc>().state;
    if (userState is UserStateLoaded && userState.user.profile != null) {
      bmr = DeepSeekService.calcBmr(userState.user.profile!);
    }

    final target = targetNutCal.toDouble();
    final eaten = eatenCal.toDouble();
    final activity = caloriesBurned;
    final totalBurned = bmr.toDouble() + activity;
    final hasTarget = target > 0;
    final overLimit = hasTarget && eaten > target;
    final progress = hasTarget ? (eaten / target).clamp(0.0, 1.0) : 0.0;
    final deficit = (totalBurned - eaten).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Row(children: [
          Text('Питание', style: AppTextStyles.titleM),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/nutrition'),
            child: Text('Открыть →', style: TextStyle(color: p.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CalStat(label: 'Цель', value: hasTarget ? '${target.toInt()}' : '—', color: p.textSecondary),
            _CalDivider(),
            _CalStat(label: 'Съедено', value: '${eaten.toInt()}', color: overLimit ? p.error : p.accentOrange),
            _CalDivider(),
            _CalStat(
              label: 'Сожжено',
              value: totalBurned > 0 ? '${totalBurned.toInt()}' : '—',
              color: p.primary,
              subtitle: bmr > 0 ? 'обмен + актив.' : null,
            ),
            _CalDivider(),
            _CalStat(
              label: deficit >= 0 ? 'Дефицит' : 'Профицит',
              value: totalBurned > 0 ? '${deficit.abs()}' : '—',
              color: deficit >= 0 ? p.accent : p.error,
            ),
          ],
        ),
        if (bmr > 0) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.info_outline_rounded, size: 12, color: p.textMuted),
            const SizedBox(width: 4),
            Text(
              'Базовый обмен: $bmr ккал'
              '${activity > 0 ? ' + ${activity.toInt()} актив.' : ''}',
              style: TextStyle(fontSize: 10, color: p.textMuted),
            ),
          ]),
        ],
        if (hasTarget) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: p.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(overLimit ? p.error : p.accentOrange),
              minHeight: 8,
            ),
          ),
        ],
        if (overLimit) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.warning_rounded, size: 13, color: p.error),
            const SizedBox(width: 4),
            Text('Превышение цели на ${(eaten - target).toInt()} ккал',
              style: TextStyle(fontSize: 11, color: p.error, fontWeight: FontWeight.w600)),
          ]),
        ] else if (deficit > 0 && eaten > 0) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_fire_department_rounded, size: 13, color: p.primary),
            const SizedBox(width: 4),
            Text('Дефицит калорий за день: $deficit ккал',
              style: TextStyle(fontSize: 11, color: p.primary, fontWeight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
  }
}

class _WeeklyChartWidget extends StatelessWidget {
  final List<bool> weekWorkouts;
  final int workoutKcalToday;
  final Animation<double> animation;

  const _WeeklyChartWidget({
    required this.weekWorkouts,
    required this.workoutKcalToday,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final todayIndex = DateTime.now().weekday - 1;
    final doneCount = weekWorkouts.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Row(children: [
          Text('Неделя', style: AppTextStyles.titleM),
          const Spacer(),
          Text('$doneCount/7 тренировок',
              style: TextStyle(
                fontSize: 12,
                color: doneCount > 0 ? p.primary : p.textMuted,
                fontWeight: FontWeight.w600,
              )),
        ]),
        const SizedBox(height: 20),
        ClipRect(
          child: SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final done = weekWorkouts[i];
                final isToday = i == todayIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (done)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Icon(Icons.check_circle_rounded, size: 14, color: p.primary),
                          ),
                        AnimatedBuilder(
                          animation: animation,
                          builder: (_, __) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: done
                                ? (38 * animation.value).clamp(8, 38)
                                : (isToday ? 8 : 4),
                            decoration: BoxDecoration(
                              gradient: done
                                  ? (isToday
                                      ? p.primaryGradient
                                      : LinearGradient(
                                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter))
                                  : null,
                              color: done ? null : (isToday
                                  ? p.primary.withValues(alpha: 0.3)
                                  : p.surfaceLight),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(days[i], style: TextStyle(
                          fontSize: 11,
                          color: isToday ? p.primary : done ? p.textSecondary : p.textMuted,
                          fontWeight: (isToday || done) ? FontWeight.w700 : FontWeight.w400,
                        )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        if (workoutKcalToday > 0) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_fire_department_rounded, size: 13, color: p.accentOrange),
            const SizedBox(width: 4),
            Text('Сегодня сожжено за тренировку: $workoutKcalToday ккал',
                style: TextStyle(fontSize: 11, color: p.accentOrange, fontWeight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
  }
}

class _AiChatCard extends StatelessWidget {
  const _AiChatCard();

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return GestureDetector(
      onTap: () => context.push('/chat'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              p.primary.withValues(alpha: 0.12),
              p.accent.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.primary.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primary, p.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('AI', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Спроси AI-тренера', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary)),
              SizedBox(height: 4),
              Text('Вопросы о тренировках, питании и прогрессе', style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: p.primary, size: 16),
        ]),
      ),
    );
  }
}

class _SocialCardWidget extends StatelessWidget {
  final int pendingRequests;
  const _SocialCardWidget({required this.pendingRequests});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Социальное', style: AppTextStyles.titleM),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SocialBtn(emoji: '👥', label: 'Лента', onTap: () => context.push(AppRouter.feed), colors: colors)),
          const SizedBox(width: 10),
          Expanded(child: _SocialBtn(emoji: '🤝', label: 'Друзья', badge: pendingRequests, onTap: () => context.push(AppRouter.friends), colors: colors)),
          const SizedBox(width: 10),
          Expanded(child: _SocialBtn(emoji: '⚡', label: 'Челленджи', onTap: () => context.push(AppRouter.challenges), colors: colors)),
        ]),
      ]),
    );
  }
}

class _DailyTasksWidget extends StatelessWidget {
  final List<_DailyTask> tasks;
  const _DailyTasksWidget({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final done = tasks.where((t) => t.done).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Задания на сегодня', style: AppTextStyles.titleM),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: done == tasks.length ? p.primary.withValues(alpha: 0.15) : p.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$done/${tasks.length}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: done == tasks.length ? p.primary : p.textMuted),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ...tasks.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: t.done ? p.primary.withValues(alpha: 0.15) : p.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: t.done ? p.primary : p.textMuted.withValues(alpha: 0.3), width: 1.5),
              ),
              child: t.done ? Icon(Icons.check_rounded, size: 13, color: p.primary) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t.text, style: TextStyle(fontSize: 13, color: t.done ? p.textMuted : p.textPrimary, decoration: t.done ? TextDecoration.lineThrough : null)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: p.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('+${t.xp} XP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.accentOrange)),
            ),
          ]),
        )),
      ]),
    );
  }
}

class _RecoveryCardWidget extends StatelessWidget {
  final RecoveryScore recoveryScore;
  const _RecoveryCardWidget({required this.recoveryScore});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final r = recoveryScore;
    final color = r.color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Восстановление', style: AppTextStyles.titleM),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(r.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(
            width: 110, height: 110,
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: r.score / 100,
                  strokeWidth: 9,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              SizedBox(
                width: 60,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${r.score}',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    '%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.75),
                      height: 1.1,
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.advice, style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4)),
              const SizedBox(height: 10),
              Row(children: [
                _RecoveryStat(icon: '😴', label: 'Сон', value: RecoveryScoreService.formatSleep(r.sleepMinutes)),
                const SizedBox(width: 14),
                _RecoveryStat(icon: '💓', label: 'HRV', value: r.hrv != null ? '${r.hrv!.toStringAsFixed(0)} мс' : '—'),
                const SizedBox(width: 14),
                _RecoveryStat(icon: '❤️', label: 'ЧСС', value: r.restingHr != null ? '${r.restingHr} уд' : '—'),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _AdaptationBanner extends StatelessWidget {
  final RecoveryScore recoveryScore;
  const _AdaptationBanner({required this.recoveryScore});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final r = recoveryScore;
    final isLow = r.level == RecoveryLevel.low;
    final bannerColor = isLow ? p.error : p.accentOrange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bannerColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
          child: Center(child: Text(isLow ? '😴' : '⚡', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isLow ? 'AI: рекомендован отдых' : 'AI: снижаем интенсивность',
            style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: bannerColor),
          ),
          const SizedBox(height: 2),
          Text(
            isLow
                ? 'Показатели восстановления низкие. Замените тренировку растяжкой или прогулкой.'
                : 'Сон или HRV ниже нормы. Сегодняшняя нагрузка снижена на 15–20%.',
            style: TextStyle(fontSize: 11, color: p.textSecondary, height: 1.4),
          ),
        ])),
      ]),
    );
  }
}

class _AiPlansWidget extends StatelessWidget {
  final String? workoutPlanJson;
  final String? mealPlanJson;
  const _AiPlansWidget({this.workoutPlanJson, this.mealPlanJson});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ваш AI-план', style: AppTextStyles.titleM),
      const SizedBox(height: 12),
      if (workoutPlanJson != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: p.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.fitness_center_rounded, color: p.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('План тренировок', style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/workout'),
              child: Text('Открыть →', style: TextStyle(fontSize: 12, color: p.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      if (mealPlanJson != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.accentOrange.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: p.accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.restaurant_rounded, color: p.accentOrange, size: 20),
            ),
            const SizedBox(width: 10),
            Text('План питания', style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: p.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/nutrition/meal-plan'),
              child: Text('Открыть →', style: TextStyle(fontSize: 12, color: p.accentOrange, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ],
    ]);
  }
}

// ── End extracted widgets ─────────────────────────────────────────────────────

// Simple immutable daily task (auto-checked from SharedPrefs state)
class _DailyTask {
  final String text;
  final int xp;
  final bool done;
  const _DailyTask({required this.text, required this.xp, required this.done});
}

class _RecoveryStat extends StatelessWidget {
  final String icon, label, value;
  const _RecoveryStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$icon $label', style: TextStyle(fontSize: 9, color: p.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 12, fontWeight: FontWeight.w700, color: p.textPrimary)),
    ]);
  }
}

class _ActivityRingsPainter extends CustomPainter {
  final double progress, steps, calories, water;
  final Color stepsColor, caloriesColor, waterColor;
  const _ActivityRingsPainter({
    required this.progress,
    required this.steps,
    required this.calories,
    required this.water,
    required this.stepsColor,
    required this.caloriesColor,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rings = [
      (radius: size.width * 0.42, color: stepsColor,    value: steps),
      (radius: size.width * 0.31, color: caloriesColor, value: calories),
      (radius: size.width * 0.20, color: waterColor,    value: water),
    ];

    for (final ring in rings) {
      canvas.drawCircle(center, ring.radius, Paint()
        ..color = ring.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ring.radius),
        -1.5707963,
        2 * 3.14159265 * (ring.value * progress).clamp(0, 1),
        false,
        Paint()
          ..color = ring.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ActivityRingsPainter old) => old.progress != progress;
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label, value, total, unit;
  final bool editable;
  const _RingLegend({required this.color, required this.label, required this.value, required this.total, required this.unit, this.editable = false});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: TextStyle(fontSize: 11, color: p.textMuted)),
          if (editable) ...[
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded, size: 10, color: p.textMuted),
          ],
        ]),
        RichText(text: TextSpan(children: [
          TextSpan(text: '$value$unit', style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          TextSpan(text: total, style: TextStyle(fontSize: 11, color: p.textMuted, fontFamily: 'Inter')),
        ])),
      ]),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value, unit, subtitle;
  final Color? subtitleColor;
  const _StatCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.unit, required this.subtitle, this.subtitleColor});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(fontSize: 11, color: p.textMuted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: p.textPrimary)),
        ),
        Text(unit, style: TextStyle(fontSize: 10, color: p.textMuted)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 10, color: subtitleColor ?? p.textMuted, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _CalStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final String? subtitle;
  const _CalStat({required this.label, required this.value, required this.color, this.subtitle});
  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Column(children: [
      Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: p.textMuted)),
      if (subtitle != null)
        Text(subtitle!, style: TextStyle(fontSize: 9, color: p.textMuted)),
    ]);
  }
}

class _CalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(width: 1, height: 30, color: p.surfaceLight);
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoPill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}

class _SocialBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final int badge;
  final VoidCallback onTap;
  final ThemePalette colors;
  const _SocialBtn({required this.emoji, required this.label, required this.onTap, required this.colors, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: p.surfaceLight, borderRadius: BorderRadius.circular(14)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Text(emoji, style: TextStyle(fontSize: 22)),
            if (badge > 0)
              Positioned(
                top: -4, right: -8,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: p.error, shape: BoxShape.circle),
                  child: Center(child: Text('$badge', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textSecondary)),
        ]),
      ),
    );
  }
}

// ─── Manual input bottom sheet ────────────────────────────────────────────────

class _ManualInputSheet extends StatefulWidget {
  final String title, unit, hint;
  final TextEditingController ctrl;
  const _ManualInputSheet({required this.title, required this.unit, required this.hint, required this.ctrl});

  @override
  State<_ManualInputSheet> createState() => _ManualInputSheetState();
}

class _ManualInputSheetState extends State<_ManualInputSheet> {
  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(widget.title, style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: p.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close_rounded, color: p.textMuted, size: 22),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Введите значение вручную (${widget.unit})', style: TextStyle(fontSize: 13, color: p.textMuted)),
        const SizedBox(height: 20),
        TextField(
          controller: widget.ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: TextStyle(fontFamily: 'Syne', fontSize: 28, fontWeight: FontWeight.w800, color: p.textPrimary),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(fontFamily: 'Syne', fontSize: 28, fontWeight: FontWeight.w300, color: p.textMuted),
            suffixText: widget.unit,
            suffixStyle: TextStyle(fontSize: 14, color: p.textMuted),
            filled: true,
            fillColor: p.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final v = int.tryParse(widget.ctrl.text.trim()) ?? 0;
              Navigator.pop(context, v);
            },
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Сохранить', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
