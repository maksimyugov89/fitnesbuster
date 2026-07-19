import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/presentation/widgets/common/permission_rationale_dialog.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/entities/body_measurement.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart' hide WorkoutDay;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/progress/weight_chart.dart';
import 'package:fitnesbuster/presentation/widgets/progress/body_measurements_dialog.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_cards.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_measurement_card.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_period_selector.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_stats_panel.dart';
import 'package:fitnesbuster/presentation/widgets/segmented_tab_bar.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_workout_log.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_photo_section.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_ai_analysis_section.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_weight_section.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_health_list.dart';

class _DayStats {
  final DateTime date;
  final bool workoutDone;
  final int workoutKcal;
  final int waterMl;
  final int eatenCal;
  const _DayStats({
    required this.date,
    required this.workoutDone,
    required this.workoutKcal,
    required this.waterMl,
    required this.eatenCal,
  });
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _picker = ImagePicker();

  int _steps = 0;
  double _caloriesBurned = 0;
  int? _heartRateAvg;
  int? _restingHeartRate;
  double? _heartRateVariability;
  double? _respiratoryRate;
  double? _weight;
  double? _height;
  int? _sleepMinutes;
  double? _waterIntakeMl;
  bool _healthLoaded = false;

  List<bool> _weekWorkouts = List.filled(7, false);
  int _workoutKcalToday = 0;
  int _waterMlToday = 0;

  int _currentStreak = 0;

  StatPeriod _selectedPeriod = StatPeriod.week;
  List<_DayStats> _yearlyStats = [];

  List<double> _weightData = [0];
  List<String> _weightLabels = ['\u2014'];

  List<BodyMeasurement> _measurements = [];
  bool _measurementsLoaded = false;

  final Map<PhotoAngle, File?> _photos = {
    PhotoAngle.front: null,
    PhotoAngle.side: null,
    PhotoAngle.back: null,
  };

  String? _aiAnalysis;
  bool _aiAnalyzing = false;

  StreamSubscription<AuthState>? _authSub;

  String? get _userId =>
      context.read<AuthBloc>().state is AuthStateAuthenticated
      ? (context.read<AuthBloc>().state as AuthStateAuthenticated).userId
      : null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAllActivityData();
    _syncHealthData();
    _loadMeasurements();
    _loadPhotos();
    // AuthBloc emits an initial profile-less user optimistically at launch,
    // then a corrected one once the Firestore doc fetch resolves — without
    // this listener the weight card stayed blank until something else
    // forced a re-read of AuthBloc's state.
    _authSub = sl<AuthBloc>().stream.listen((state) {
      if (state is AuthStateAuthenticated &&
          (_weight == null || _weight == 0)) {
        final w = state.user.profile?.weight ?? 0;
        if (w > 0 && mounted) {
          setState(() {
            _weight = w;
            _weightData = [w];
            _weightLabels = [context.l10n.todayShort];
          });
        }
      }
    });
  }

  Future<void> _loadAllActivityData() async {
    try {
      final settings = sl<ISettingsRepository>();
      final now = DateTime.now();
      final weekday = now.weekday;
      final weekStart = now.subtract(Duration(days: weekday - 1));

      final yearlyStats = <_DayStats>[];
      int currentStreak = 0;
      bool streakBroken = false;

      for (int i = 0; i < 365; i++) {
        final day = now.subtract(Duration(days: i));
        final k = dateKey(day);
        final done = await settings.getWorkoutDone(k);
        final kcal = await settings.getWorkoutKcal(k);
        final water = await settings.getWaterMl(k);
        final eaten = await settings.getEatenCal(k);
        yearlyStats.add(
          _DayStats(
            date: day,
            workoutDone: done,
            workoutKcal: kcal,
            waterMl: water,
            eatenCal: eaten,
          ),
        );
        if (done) {
          if (!streakBroken) currentStreak++;
        } else if (i > 0) {
          streakBroken = true;
        }
      }

      final weekWorkouts = <bool>[];
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final k = dateKey(day);
        weekWorkouts.add(await settings.getWorkoutDone(k));
      }

      if (mounted) {
        setState(() {
          _yearlyStats = yearlyStats;
          _weekWorkouts = weekWorkouts;
          _workoutKcalToday = yearlyStats.isNotEmpty
              ? yearlyStats[0].workoutKcal
              : 0;
          _waterMlToday = yearlyStats.isNotEmpty ? yearlyStats[0].waterMl : 0;
          _currentStreak = currentStreak;
        });
      }
    } catch (e, st) {
      appLogger.w('Progress: load history data', error: e, stackTrace: st);
    }
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
        'Progress: load weight from profile',
        error: e,
        stackTrace: st,
      );
    }
  }

  List<_DayStats> get _periodData {
    if (_yearlyStats.isEmpty) return [];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return switch (_selectedPeriod) {
      StatPeriod.today => _yearlyStats.take(1).toList(),
      StatPeriod.week => _yearlyStats.take(7).toList(),
      StatPeriod.month => _yearlyStats.take(daysInMonth).toList(),
      StatPeriod.year => _yearlyStats,
    };
  }

  ({int done, int total, double kcal, int waterMl, int eatenCal})
  get _periodSummary {
    final data = _periodData;
    int done = 0;
    double kcal = 0;
    int water = 0;
    int eaten = 0;
    for (final s in data) {
      if (s.workoutDone) done++;
      kcal += s.workoutKcal;
      water += s.waterMl;
      eaten += s.eatenCal;
    }
    return (
      done: done,
      total: data.length,
      kcal: kcal,
      waterMl: water,
      eatenCal: eaten,
    );
  }

  List<({String label, int done, int total, double kcal})> get _chartBars {
    if (_yearlyStats.isEmpty) return [];
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case StatPeriod.today:
        final s = _yearlyStats[0];
        return [
          (
            label: context.l10n.todayShort,
            done: s.workoutDone ? 1 : 0,
            total: 1,
            kcal: s.workoutKcal.toDouble(),
          ),
        ];

      case StatPeriod.week:
        final labels = [
          context.l10n.monShort,
          context.l10n.tueShort,
          context.l10n.wedShort,
          context.l10n.thuShort,
          context.l10n.friShort,
          context.l10n.satShort,
          context.l10n.sunShort,
        ];
        final weekday = now.weekday;
        final weekStart = now.subtract(Duration(days: weekday - 1));
        return List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final daysAgo = now.difference(day).inDays;
          if (daysAgo < 0 || daysAgo >= _yearlyStats.length) {
            return (label: labels[i], done: 0, total: 1, kcal: 0.0);
          }
          final s = _yearlyStats[daysAgo];
          return (
            label: labels[i],
            done: s.workoutDone ? 1 : 0,
            total: 1,
            kcal: s.workoutKcal.toDouble(),
          );
        });

      case StatPeriod.month:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final monthStart = DateTime(now.year, now.month, 1);
        final bars = <({String label, int done, int total, double kcal})>[];
        int weekNum = 1;
        int wStart = 0;
        while (wStart < daysInMonth) {
          final wEnd = (wStart + 7).clamp(0, daysInMonth);
          int d = 0;
          double k = 0;
          for (int di = wStart; di < wEnd; di++) {
            final day = monthStart.add(Duration(days: di));
            final daysAgo = now.difference(day).inDays;
            if (daysAgo >= 0 && daysAgo < _yearlyStats.length) {
              final s = _yearlyStats[daysAgo];
              if (s.workoutDone) d++;
              k += s.workoutKcal;
            }
          }
          bars.add((
            label: context.l10n.weekNumShort(weekNum),
            done: d,
            total: wEnd - wStart,
            kcal: k,
          ));
          wStart = wEnd;
          weekNum++;
        }
        return bars;

      case StatPeriod.year:
        final mLabels = [
          context.l10n.janShort,
          context.l10n.febShort,
          context.l10n.marShort,
          context.l10n.aprShort,
          context.l10n.mayShort,
          context.l10n.junShort,
          context.l10n.julShort,
          context.l10n.augShort,
          context.l10n.sepShort,
          context.l10n.octShort,
          context.l10n.novShort,
          context.l10n.decShort,
        ];
        return List.generate(12, (i) {
          final offset = 11 - i;
          final dt = DateTime(now.year, now.month - offset, 1);
          final yr = dt.year;
          final mo = dt.month;
          final daysInM = DateTime(yr, mo + 1, 0).day;
          int done = 0;
          double kcal = 0;
          for (final s in _yearlyStats) {
            if (s.date.year == yr && s.date.month == mo) {
              if (s.workoutDone) done++;
              kcal += s.workoutKcal;
            }
          }
          return (
            label: mLabels[mo - 1],
            done: done,
            total: daysInM,
            kcal: kcal,
          );
        });
    }
  }

  Future<void> _syncHealthData() async {
    try {
      final hcs = sl<IHealthConnectService>();
      await hcs.initialize();
      final data = await hcs.readAllToday();
      if (mounted) {
        setState(() {
          if (data.steps > 0) _steps = data.steps;
          if (data.caloriesBurned > 0) _caloriesBurned = data.caloriesBurned;
          _heartRateAvg = data.heartRateAvg;
          _restingHeartRate = data.restingHeartRate;
          _heartRateVariability = data.heartRateVariability;
          _respiratoryRate = data.respiratoryRate;
          _sleepMinutes = data.sleepMinutes;
          if ((data.waterIntakeMl ?? 0) > _waterMlToday) {
            _waterIntakeMl = data.waterIntakeMl;
          }
          _healthLoaded = true;
          if (data.weight != null && data.weight! > 0) {
            _weight = data.weight;
            _weightData = [data.weight!];
            _weightLabels = [context.l10n.todayShort];
          }
          if (data.height != null && data.height! > 0) {
            _height = data.height;
          }
        });
        if (_weight == null || _weight == 0) _loadWeightFromProfile();
      }
    } catch (_) {
      if (mounted) setState(() => _healthLoaded = true);
      _loadWeightFromProfile();
    }
  }

  Future<void> _loadMeasurements() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final list = await sl<IUserRepository>().getMeasurements(uid);
      if (mounted) {
        setState(() {
          _measurements = list;
          _measurementsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _measurementsLoaded = true);
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (final angle in PhotoAngle.values) {
        final file = File('${dir.path}/progress_${angle.name}.jpg');
        if (await file.exists()) {
          if (mounted) setState(() => _photos[angle] = file);
        }
      }
    } catch (e, st) {
      appLogger.w('Progress: load photos from disk', error: e, stackTrace: st);
    }
  }

  Future<void> _pickPhoto(PhotoAngle angle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppTheme.of(ctx);
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            ctx.l10n.photoPickTitle(angle.label(ctx.l10n)),
            style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(angle.icon, size: 48, color: colors.primary),
              const SizedBox(height: 12),
              Text(
                angle.instruction(ctx.l10n),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ctx.l10n.photoTips,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                ctx.l10n.cancel,
                style: TextStyle(color: colors.textMuted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.selectPhotoBtn),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final colors = AppTheme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: colors.primary),
                title: Text(
                  ctx.l10n.takeCameraBtn,
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: colors.primary,
                ),
                title: Text(
                  ctx.l10n.chooseGalleryBtn,
                  style: TextStyle(color: colors.textPrimary),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    if (!mounted) return;

    final accepted = await showPermissionRationaleDialog(
      context,
      source == ImageSource.camera
          ? PermissionRationaleKind.camera
          : PermissionRationaleKind.photos,
    );
    if (!accepted || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/progress_${angle.name}.jpg');
      await File(picked.path).copy(dest.path);
      if (mounted) setState(() => _photos[angle] = dest);
    } catch (e, st) {
      appLogger.w('Progress: save photo', error: e, stackTrace: st);
    }
  }

  Future<void> _runAiAnalysis() async {
    final uid = _userId;
    if (uid == null || _measurements.isEmpty) return;

    setState(() {
      _aiAnalyzing = true;
      _aiAnalysis = null;
    });

    try {
      final latest = _measurements.first;
      final previous = _measurements.length > 1 ? _measurements[1] : null;

      final blocProfile = () {
        final s = context.read<UserBloc>().state;
        return s is UserStateLoaded ? s.user.profile : null;
      }();

      UserProfile? profile;
      try {
        final userEntity = await sl<IUserRepository>().getUser(uid);
        profile = userEntity.profile;
      } catch (e, st) {
        appLogger.w('Progress: load user profile', error: e, stackTrace: st);
      }

      profile ??= blocProfile;

      if (profile == null) {
        if (mounted) setState(() => _aiAnalyzing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.fillProfileForAi)),
          );
        }
        return;
      }

      final hasPhotos = _photos.values.any((f) => f != null);

      final result = await sl<IDeepSeekService>().analyzeProgress(
        profile: profile,
        latest: {
          'chest': latest.chestCm,
          'waist': latest.waistCm,
          'hips': latest.hipsCm,
          'bodyFat': latest.bodyFatPercent,
        },
        previous: previous != null
            ? {
                'chest': previous.chestCm,
                'waist': previous.waistCm,
                'hips': previous.hipsCm,
                'bodyFat': previous.bodyFatPercent,
              }
            : null,
        hasPhotos: hasPhotos,
      );

      if (mounted) {
        setState(() {
          _aiAnalysis = result;
          _aiAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAnalysis = '${context.l10n.error}: $e';
          _aiAnalyzing = false;
        });
      }
    }
  }

  Future<void> _openMeasurementsDialog() async {
    final uid = _userId;
    if (uid == null) return;
    final userState = context.read<UserBloc>().state;
    final profile = userState is UserStateLoaded
        ? userState.user.profile
        : null;
    await showDialog(
      context: context,
      builder: (ctx) => BodyMeasurementsDialog(
        profile: profile,
        latest: _measurements.isNotEmpty ? _measurements.first : null,
        onSave: (m) async {
          await sl<IUserRepository>().saveMeasurement(
            userId: uid,
            measurement: m,
          );
          await _loadMeasurements();
        },
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const ProgressHeader(),
            const DebriefCard(),
            const SizedBox(height: 12),
            SegmentedTabBar(
              controller: _tabCtrl,
              labels: [
                context.l10n.weightBodyTab,
                context.l10n.workoutsStatTab,
                context.l10n.healthTabLabel,
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildBodyTab(),
                  _buildWorkoutsTab(),
                  _buildHealthTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyTab() {
    final l10n = context.l10n;
    final prevMeasurement = _measurements.length >= 2 ? _measurements[1] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      children: [
        ProgressWeightSection(
          weight: _weight,
          height: _height,
          caloriesBurned: _caloriesBurned,
          steps: _steps,
          weightData: _weightData,
          weightLabels: _weightLabels,
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Text(l10n.bodyMeasTitle, style: AppTextStyles.titleM),
            const Spacer(),
            GestureDetector(
              onTap: _openMeasurementsDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppTheme.of(context).primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.add,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.of(context).primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_measurementsLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              ProgressMeasurementCard(
                displayLabel: l10n.chestMeasureLabel,
                value: _measurements.isNotEmpty
                    ? _measurements.first.chestCm
                    : null,
                prevValue: prevMeasurement?.chestCm,
                unit: l10n.cmUnit,
              ),
              ProgressMeasurementCard(
                displayLabel: l10n.waistLabel,
                value: _measurements.isNotEmpty
                    ? _measurements.first.waistCm
                    : null,
                prevValue: prevMeasurement?.waistCm,
                unit: l10n.cmUnit,
              ),
              ProgressMeasurementCard(
                displayLabel: l10n.hipsLabel,
                value: _measurements.isNotEmpty
                    ? _measurements.first.hipsCm
                    : null,
                prevValue: prevMeasurement?.hipsCm,
                unit: l10n.cmUnit,
              ),
              ProgressMeasurementCard(
                displayLabel: l10n.bodyFatLabel,
                value: _measurements.isNotEmpty
                    ? _measurements.first.bodyFatPercent
                    : null,
                prevValue: prevMeasurement?.bodyFatPercent,
                unit: '%',
                isInverseGood: true,
              ),
            ],
          ),

        if (_measurements.length >= 2) ...[
          const SizedBox(height: 8),
          Text(
            l10n.prevMeasLabel(_formatDate(_measurements[1].date)),
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.of(context).textMuted,
            ),
          ),
        ],

        const SizedBox(height: 20),

        ProgressPhotoSection(
          photos: Map<PhotoAngle, File?>.from(_photos),
          onPickPhoto: _pickPhoto,
        ),

        if (_measurements.isNotEmpty) ...[
          const SizedBox(height: 20),
          ProgressAiAnalysisSection(
            aiAnalysis: _aiAnalysis,
            aiAnalyzing: _aiAnalyzing,
            measurementsCount: _measurements.length,
            hasPhotos: _photos.values.any((f) => f != null),
            onAnalyze: _runAiAnalysis,
          ),
        ],
      ],
    );
  }

  Widget _buildWorkoutsTab() {
    final colors = AppTheme.of(context);
    final now = DateTime.now();
    final weekday = now.weekday;
    final dayLabels = [
      context.l10n.monShort,
      context.l10n.tueShort,
      context.l10n.wedShort,
      context.l10n.thuShort,
      context.l10n.friShort,
      context.l10n.satShort,
      context.l10n.sunShort,
    ];
    final summary = _periodSummary;
    final bars = _chartBars;

    final todayKcal = _workoutKcalToday > 0
        ? _workoutKcalToday
        : (_caloriesBurned > 0 ? _caloriesBurned.toInt() : 0);
    final todayWater = _waterMlToday > 0
        ? _waterMlToday
        : ((_waterIntakeMl ?? 0) > 0 ? _waterIntakeMl!.toInt() : 0);
    final hasAnyActivity = todayKcal > 0 || todayWater > 0 || _steps > 0;

    final doneCount = _weekWorkouts.take(weekday).where((d) => d).length;
    final completionPct = weekday > 0 ? (doneCount / weekday * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        ProgressPeriodSelector(
          selectedPeriod: _selectedPeriod,
          onChanged: (p) => setState(() => _selectedPeriod = p),
        ),

        const SizedBox(height: 16),

        ProgressStatsPanel(
          periodTitle: _periodTitle,
          doneCount: summary.done,
          totalDays: summary.total,
          totalKcal: summary.kcal,
          totalWaterMl: summary.waterMl,
          totalEatenCal: summary.eatenCal,
        ),

        const SizedBox(height: 16),

        if (bars.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.workoutsChartTitle(_chartPeriodLabel),
                  style: AppTextStyles.titleM,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ProgressPeriodBarChart(bars: bars, colors: colors),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

        const SizedBox(height: 16),

        ProgressWorkoutLog(
          currentStreak: _currentStreak,
          hasAnyActivity: hasAnyActivity,
          todayKcal: todayKcal,
          todayWater: todayWater,
          steps: _steps,
          weekWorkouts: _weekWorkouts,
          weekday: weekday,
          dayLabels: dayLabels,
          completionPct: completionPct,
          doneCount: doneCount,
        ),
      ],
    );
  }

  String get _periodTitle => switch (_selectedPeriod) {
    StatPeriod.today => context.l10n.periodTodayLabel,
    StatPeriod.week => context.l10n.periodWeekLabel,
    StatPeriod.month => context.l10n.periodMonthLabel,
    StatPeriod.year => context.l10n.periodYearLabel,
  };

  String get _chartPeriodLabel => switch (_selectedPeriod) {
    StatPeriod.today => context.l10n.periodTodayLabel,
    StatPeriod.week => context.l10n.periodWeekLabel,
    StatPeriod.month => context.l10n.periodMonthLabel,
    StatPeriod.year => context.l10n.periodYearLabel,
  };

  Widget _buildHealthTab() {
    return ProgressHealthList(
      heartRateAvg: _heartRateAvg,
      restingHeartRate: _restingHeartRate,
      heartRateVariability: _heartRateVariability,
      respiratoryRate: _respiratoryRate,
      steps: _steps,
      sleepMinutes: _sleepMinutes,
      waterIntakeMl: _waterIntakeMl,
      healthLoaded: _healthLoaded,
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
