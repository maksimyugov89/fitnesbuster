import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';
import 'package:fitnesbuster/bloc/ai/ai_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/core/services/recovery_score_service.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/dashboard_app_bar.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/activity_rings_card.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/quick_stats_card.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/recovery_card.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/todays_workout_card.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/ai_chat_card.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/social_card.dart';
import 'package:fitnesbuster/presentation/widgets/dashboard/daily_tasks_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _headerCtrl;
  late AnimationController _ringsCtrl;
  late Animation<double> _ringsAnim;

  int _steps = 0;
  final int _targetSteps = 10000;
  double _caloriesBurned = 0;
  final double _targetCalories = 680;
  double _waterMl = 0;
  final double _targetWater = 2500;
  double _weight = 0;
  int _heartRate = 0;
  int _streak = 0;

  RecoveryScore? _recoveryScore;
  UserLevel? _userLevel;
  List<DailyTaskItem> _dailyTasks = [];

  // DOMS check-in: null = ещё не загружено с диска; после загрузки null
  // означает "сегодня ещё не отвечал" — тогда показываем карточку.
  int? _domsLevel;
  bool _domsLoaded = false;

  int _pendingRequests = 0;
  StreamSubscription<List<FriendRequest>>? _requestsSub;
  StreamSubscription<AuthState>? _authSub;

  String _userName = '';
  int _avatarPresetIndex = -1;
  String _avatarCustomPath = '';

  bool get _hasSyncedData => _steps > 0 || _caloriesBurned > 0 || _waterMl > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _ringsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringsAnim = CurvedAnimation(
      parent: _ringsCtrl,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _ringsCtrl.forward();
    });

    _syncHealthData();
    _calculateStreak();
    _loadWeeklyData();
    _loadAvatarAndName();
    _loadGamificationData();
    _requestsSub = sl<ISocialService>().incomingRequestsStream().listen((list) {
      if (mounted) setState(() => _pendingRequests = list.length);
    });
    // AuthBloc emits an initial profile-less user optimistically at launch,
    // then a corrected one once the Firestore doc fetch resolves — without
    // this listener the weight card stayed blank until something else (e.g.
    // opening Profile) forced a re-read of AuthBloc's state.
    _authSub = sl<AuthBloc>().stream.listen((state) {
      if (state is! AuthStateAuthenticated) return;
      if (_weight == 0) {
        final w = state.user.profile?.weight ?? 0;
        if (w > 0 && mounted) setState(() => _weight = w);
      }
      final serverStreak = _effectiveServerStreak(state.user);
      if (serverStreak != null && mounted) {
        setState(() => _streak = serverStreak);
        try {
          sl<IAnalyticsService>().logStreakKept(streak: serverStreak).ignore();
        } catch (_) {}
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncHealthData();
      _loadWeeklyData();
      _loadAvatarAndName();
      _loadGamificationData();
    }
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _headerCtrl.dispose();
    _ringsCtrl.dispose();
    super.dispose();
  }

  // ─── Data Loading (kept for orchestration) ──────────────────────────────────

  Future<void> _loadAvatarAndName() async {
    final authState = sl<AuthBloc>().state;
    final name = authState is AuthStateAuthenticated ? authState.user.name : '';
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

  Future<void> _loadWeeklyData() async {
    try {
      final settings = sl<ISettingsRepository>();
      final now = DateTime.now();
      final todayIndex = now.weekday - 1;
      int trackerWater = 0;
      for (int i = 0; i < 7; i++) {
        final day = now.subtract(Duration(days: todayIndex - i));
        final k = dateKey(day);
        if (i == todayIndex) {
          trackerWater = await settings.getWaterMl(k);
        }
      }
      if (mounted) {
        setState(() {
          if (trackerWater > _waterMl) _waterMl = trackerWater.toDouble();
        });
      }
    } catch (e, st) {
      appLogger.w('Dashboard: load weekly data', error: e, stackTrace: st);
    }
  }

  Future<void> _syncHealthData() async {
    try {
      final hc = sl<IHealthConnectService>();
      await hc.initialize();
      final data = await hc.readAllToday();
      if (mounted) {
        setState(() {
          if (data.steps > 0) _steps = data.steps;
          if (data.caloriesBurned > 0) _caloriesBurned = data.caloriesBurned;
          if (data.heartRateAvg != null) _heartRate = data.heartRateAvg!;
          if ((data.waterIntakeMl ?? 0) > _waterMl) {
            _waterMl = data.waterIntakeMl!;
          }
          if (data.weight != null && data.weight! > 0) {
            final newWeight = data.weight!;
            if ((newWeight - _weight).abs() > 1.0 && _weight > 0) {
              _triggerPlanRegeneration(
                weightChanged: true,
                newWeight: newWeight,
              );
            }
            _weight = newWeight;
          }
          _recoveryScore = RecoveryScoreService.calculate(
            sleepMinutes: data.sleepMinutes,
            hrv: data.heartRateVariability,
            restingHr: data.restingHeartRate ?? data.heartRateAvg,
          );
        });
      }
    } catch (e, st) {
      appLogger.w('Dashboard: sync health data', error: e, stackTrace: st);
    }
    if (_weight == 0) _loadWeightFromProfile();
    await _loadManualData();
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
      appLogger.w(
        'Dashboard: load weight from profile',
        error: e,
        stackTrace: st,
      );
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
          break;
        }
      }
      if (mounted) setState(() => _streak = streak);
      await _syncStreakWithServer(localStreak: streak);
    } catch (e, st) {
      appLogger.w('Dashboard: calculate streak', error: e, stackTrace: st);
    }
  }

  String _utcDateKey(DateTime d) {
    final u = d.toUtc();
    final mm = u.month.toString().padLeft(2, '0');
    final dd = u.day.toString().padLeft(2, '0');
    return '${u.year}-$mm-$dd';
  }

  /// The workout streak is server-authoritative (`recordWorkout` Cloud
  /// Function updates `currentStreak`/`lastWorkoutDate` on `users/{uid}`)
  /// once an account has been bootstrapped. Returns null if the account
  /// hasn't been bootstrapped yet (caller should keep the locally-computed
  /// value), or the effective streak otherwise — 0 if the last recorded
  /// workout is older than yesterday, since that means the streak broke
  /// without the user opening the app to record a new one.
  int? _effectiveServerStreak(UserEntity user) {
    final lastDate = user.lastWorkoutDate;
    final streak = user.currentStreak;
    if (lastDate == null || streak == null) return null;
    final now = DateTime.now();
    final today = _utcDateKey(now);
    final yesterday = _utcDateKey(now.subtract(const Duration(days: 1)));
    return (lastDate == today || lastDate == yesterday) ? streak : 0;
  }

  Future<void> _syncStreakWithServer({required int localStreak}) async {
    final authState = sl<AuthBloc>().state;
    if (authState is! AuthStateAuthenticated) return;
    final user = authState.user;

    // No server-tracked streak yet: keep the locally-computed value. The
    // streak migrates to the server automatically on the next completed
    // workout — recordWorkout accepts the client's locally-computed streak as
    // a one-time seed for accounts without lastWorkoutDate.
    if (user.lastWorkoutDate == null) return;

    final serverStreak = _effectiveServerStreak(user);
    if (serverStreak != null && mounted) setState(() => _streak = serverStreak);
  }

  Future<void> _loadGamificationData() async {
    try {
      final l10n = context.l10n;
      final xp = await sl<IGamificationService>().getTotalXp();
      final settings = sl<ISettingsRepository>();
      final k = todayKey();
      final workoutDone = await settings.getWorkoutDone(k);
      final waterMl = await settings.getWaterMl(k);
      final manualSteps = await settings.getManualSteps(k);
      final steps = manualSteps > 0 ? manualSteps : _steps;
      final mealsRaw = await settings.getMealsDone(k);
      final eatenCal = await settings.getEatenCal(k);
      final allMealsDone = mealsRaw.isNotEmpty && eatenCal > 0;
      final tasks = [
        DailyTaskItem(text: l10n.taskWorkout, xp: 100, done: workoutDone),
        DailyTaskItem(text: l10n.taskWater, xp: 20, done: waterMl >= 2000),
        DailyTaskItem(text: l10n.taskMeals, xp: 30, done: allMealsDone),
        DailyTaskItem(
          text: AppLocalizations.tl('dashboardWalkSteps'),
          xp: 40,
          done: steps >= 8000,
        ),
      ];
      if (mounted) {
        setState(() {
          _userLevel = GamificationService.computeLevel(xp);
          _dailyTasks = tasks;
        });
      }
    } catch (e, st) {
      appLogger.w(
        'Dashboard: load gamification data',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _triggerPlanRegeneration({
    bool weightChanged = false,
    double? newWeight,
  }) {
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
      final updated = profile.copyWith(weight: newWeight);
      final target = updated.dailyCalorieTarget.round();
      await sl<ISettingsRepository>().setTargetCal(todayKey(), target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.dashboardWeightUpdated(
                newWeight.toStringAsFixed(1),
                '$target',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF131619),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        if (v > 0 && mounted) setState(() => _steps = v);
      }
      if (_heartRate == 0) {
        final v = await settings.getManualHeartRate(k);
        if (v > 0 && mounted) setState(() => _heartRate = v);
      }
      final doms = await settings.getDomsLevel(k);
      if (mounted) setState(() => _domsLoaded = true);
      if (doms != null && mounted) setState(() => _domsLevel = doms);
    } catch (e, st) {
      appLogger.w('Dashboard: load manual data', error: e, stackTrace: st);
    }
  }

  Future<void> _saveDoms(int level) async {
    await sl<ISettingsRepository>().setDomsLevel(todayKey(), level);
    if (mounted) setState(() => _domsLevel = level);
  }

  Future<void> _showManualInputSheet(String type) async {
    final isPulse = type == 'heartrate';
    final ctrl = TextEditingController();
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualInputSheet(
        title: isPulse ? ctx.l10n.heartRateLabel : ctx.l10n.stepsLabel,
        unit: isPulse ? ctx.l10n.dashboardBpm : '',
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
          if (isPulse) {
            _heartRate = result;
          } else {
            _steps = result;
          }
        });
      }
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          DashboardAppBar(
            userName: _userName,
            avatarPresetIndex: _avatarPresetIndex,
            avatarCustomPath: _avatarCustomPath,
            headerCtrl: _headerCtrl,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                if (_userLevel != null) ...[
                  StreakCard(level: _userLevel!),
                  const SizedBox(height: 12),
                ],
                ActivityRingsCard(
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
                QuickStatsCard(
                  heartRate: _heartRate,
                  weight: _weight,
                  streak: _streak,
                  onHeartRateTap: () => _showManualInputSheet('heartrate'),
                ),
                if (_recoveryScore != null) ...[
                  const SizedBox(height: 16),
                  RecoveryCard(recoveryScore: _recoveryScore!),
                  if (_recoveryScore!.shouldReduceIntensity) ...[
                    const SizedBox(height: 10),
                    AdaptationBanner(recoveryScore: _recoveryScore!),
                  ],
                ],
                if (_domsLoaded && _domsLevel == null) ...[
                  const SizedBox(height: 16),
                  DomsCheckInCard(onSelected: _saveDoms),
                ],
                if (_dailyTasks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  DailyTasksCard(tasks: _dailyTasks),
                ],
                const SizedBox(height: 24),
                const AiChatCard(),
                const SizedBox(height: 24),
                SocialCard(pendingRequests: _pendingRequests),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Manual input bottom sheet ────────────────────────────────────────────────

class _ManualInputSheet extends StatefulWidget {
  final String title, unit, hint;
  final TextEditingController ctrl;
  const _ManualInputSheet({
    required this.title,
    required this.unit,
    required this.hint,
    required this.ctrl,
  });

  @override
  State<_ManualInputSheet> createState() => _ManualInputSheetState();
}

class _ManualInputSheetState extends State<_ManualInputSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = AppTheme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: p.textMuted, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.enterValueManualHint(widget.unit),
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: widget.ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: p.textMuted,
              ),
              suffixText: widget.unit,
              suffixStyle: TextStyle(fontSize: 14, color: p.textMuted),
              filled: true,
              fillColor: p.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.save,
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
