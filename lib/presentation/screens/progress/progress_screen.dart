import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/domain/entities/body_measurement.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart' hide WorkoutDay;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

// Ракурсы для фото прогресса
enum _PhotoAngle {
  front('photoFront', 'photoFrontInstr', Icons.person_rounded),
  side('photoSide', 'photoSideInstr', Icons.person_outline_rounded),
  back('photoBack', 'photoBackInstr', Icons.accessibility_new_rounded);

  final String labelKey;
  final String instrKey;
  final IconData icon;
  const _PhotoAngle(this.labelKey, this.instrKey, this.icon);
  String label(AppLocalizations l10n) => AppLocalizations.tl(labelKey);
  String instruction(AppLocalizations l10n) => AppLocalizations.tl(instrKey);
}

enum _StatPeriod { today, week, month, year }

class _DayStats {
  final DateTime date;
  final bool workoutDone;
  final int workoutKcal;
  final int waterMl;
  final int eatenCal;
  const _DayStats({required this.date, required this.workoutDone, required this.workoutKcal, required this.waterMl, required this.eatenCal});
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

  // Health Connect
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

  // SharedPreferences data
  List<bool> _weekWorkouts = List.filled(7, false);
  int _workoutKcalToday = 0;
  int _waterMlToday = 0;

  int _currentStreak = 0;

  // Period statistics
  _StatPeriod _selectedPeriod = _StatPeriod.week;
  List<_DayStats> _yearlyStats = [];

  List<double> _weightData = [0];
  List<String> _weightLabels = ['—'];

  // Замеры тела
  List<BodyMeasurement> _measurements = [];
  bool _measurementsLoaded = false;

  // Фото прогресса (локальные пути)
  final Map<_PhotoAngle, File?> _photos = {
    _PhotoAngle.front: null,
    _PhotoAngle.side: null,
    _PhotoAngle.back: null,
  };

  // AI анализ
  String? _aiAnalysis;
  bool _aiAnalyzing = false;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAllActivityData();
    _syncHealthData();
    _loadMeasurements();
    _loadPhotos();
  }

  Future<void> _loadAllActivityData() async {
    try {
      final settings = sl<ISettingsRepository>();
      final now = DateTime.now();
      final weekday = now.weekday;
      final weekStart = now.subtract(Duration(days: weekday - 1));

      // Scan last 365 days — build full year dataset
      final yearlyStats = <_DayStats>[];
      int currentStreak = 0;
      bool streakBroken = false;

      for (int i = 0; i < 365; i++) {
        final day = now.subtract(Duration(days: i));
        final k = dateKey(day);
        final done  = await settings.getWorkoutDone(k);
        final kcal  = await settings.getWorkoutKcal(k);
        final water = await settings.getWaterMl(k);
        final eaten = await settings.getEatenCal(k);
        yearlyStats.add(_DayStats(date: day, workoutDone: done, workoutKcal: kcal, waterMl: water, eatenCal: eaten));
        if (done) {
          if (!streakBroken) currentStreak++;
        } else if (i > 0) {
          streakBroken = true;
        }
      }

      // Current week Mon-Sun
      final weekWorkouts = <bool>[];
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final k = dateKey(day);
        weekWorkouts.add(await settings.getWorkoutDone(k));
      }

      if (mounted) {
        setState(() {
          _yearlyStats        = yearlyStats;
          _weekWorkouts       = weekWorkouts;
          _workoutKcalToday   = yearlyStats.isNotEmpty ? yearlyStats[0].workoutKcal : 0;
          _waterMlToday       = yearlyStats.isNotEmpty ? yearlyStats[0].waterMl     : 0;
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
      appLogger.w('Progress: load weight from profile', error: e, stackTrace: st);
    }
  }

  // ── Period stat helpers ───────────────────────────────────────────────────────

  List<_DayStats> get _periodData {
    if (_yearlyStats.isEmpty) return [];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return switch (_selectedPeriod) {
      _StatPeriod.today => _yearlyStats.take(1).toList(),
      _StatPeriod.week  => _yearlyStats.take(7).toList(),
      _StatPeriod.month => _yearlyStats.take(daysInMonth).toList(),
      _StatPeriod.year  => _yearlyStats,
    };
  }

  ({int done, int total, double kcal, int waterMl, int eatenCal}) get _periodSummary {
    final data = _periodData;
    int done = 0; double kcal = 0; int water = 0; int eaten = 0;
    for (final s in data) {
      if (s.workoutDone) done++;
      kcal  += s.workoutKcal;
      water += s.waterMl;
      eaten += s.eatenCal;
    }
    return (done: done, total: data.length, kcal: kcal, waterMl: water, eatenCal: eaten);
  }

  // Returns bars oldest→newest: (label, workouts done, days in bucket, kcal)
  List<({String label, int done, int total, double kcal})> get _chartBars {
    if (_yearlyStats.isEmpty) return [];
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case _StatPeriod.today:
        final s = _yearlyStats[0];
        return [(label: context.l10n.todayShort, done: s.workoutDone ? 1 : 0, total: 1, kcal: s.workoutKcal.toDouble())];

      case _StatPeriod.week:
        final labels = [context.l10n.monShort, context.l10n.tueShort, context.l10n.wedShort, context.l10n.thuShort, context.l10n.friShort, context.l10n.satShort, context.l10n.sunShort];
        final weekday = now.weekday;
        final weekStart = now.subtract(Duration(days: weekday - 1));
        return List.generate(7, (i) {
          final day    = weekStart.add(Duration(days: i));
          final daysAgo = now.difference(day).inDays;
          if (daysAgo < 0 || daysAgo >= _yearlyStats.length) {
            return (label: labels[i], done: 0, total: 1, kcal: 0.0);
          }
          final s = _yearlyStats[daysAgo];
          return (label: labels[i], done: s.workoutDone ? 1 : 0, total: 1, kcal: s.workoutKcal.toDouble());
        });

      case _StatPeriod.month:
        // Group into 4-5 weekly buckets, oldest first
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final monthStart  = DateTime(now.year, now.month, 1);
        final bars = <({String label, int done, int total, double kcal})>[];
        int weekNum = 1;
        int wStart  = 0;
        while (wStart < daysInMonth) {
          final wEnd = (wStart + 7).clamp(0, daysInMonth);
          int d = 0; double k = 0;
          for (int di = wStart; di < wEnd; di++) {
            final day     = monthStart.add(Duration(days: di));
            final daysAgo = now.difference(day).inDays;
            if (daysAgo >= 0 && daysAgo < _yearlyStats.length) {
              final s = _yearlyStats[daysAgo];
              if (s.workoutDone) d++;
              k += s.workoutKcal;
            }
          }
          bars.add((label: context.l10n.weekNumShort(weekNum), done: d, total: wEnd - wStart, kcal: k));
          wStart = wEnd; weekNum++;
        }
        return bars;

      case _StatPeriod.year:
        // 12 monthly bars (oldest first = 11 months ago → current)
        final mLabels = [context.l10n.janShort, context.l10n.febShort, context.l10n.marShort, context.l10n.aprShort, context.l10n.mayShort, context.l10n.junShort, context.l10n.julShort, context.l10n.augShort, context.l10n.sepShort, context.l10n.octShort, context.l10n.novShort, context.l10n.decShort];
        return List.generate(12, (i) {
          final offset = 11 - i; // 11=oldest, 0=current
          final dt = DateTime(now.year, now.month - offset, 1);
          final yr = dt.year; final mo = dt.month;
          final daysInM = DateTime(yr, mo + 1, 0).day;
          int done = 0; double kcal = 0;
          for (final s in _yearlyStats) {
            if (s.date.year == yr && s.date.month == mo) {
              if (s.workoutDone) done++;
              kcal += s.workoutKcal;
            }
          }
          return (label: mLabels[mo - 1], done: done, total: daysInM, kcal: kcal);
        });
    }
  }

  Future<void> _syncHealthData() async {
    try {
      final hcs = sl<HealthConnectService>();
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
          if ((data.waterIntakeMl ?? 0) > _waterMlToday) _waterIntakeMl = data.waterIntakeMl;
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
      final list = await sl<UserRepository>().getMeasurements(uid);
      if (mounted) setState(() { _measurements = list; _measurementsLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _measurementsLoaded = true);
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (final angle in _PhotoAngle.values) {
        final file = File('${dir.path}/progress_${angle.name}.jpg');
        if (await file.exists()) {
          if (mounted) setState(() => _photos[angle] = file);
        }
      }
    } catch (e, st) {
      appLogger.w('Progress: load photos from disk', error: e, stackTrace: st);
    }
  }

  Future<void> _pickPhoto(_PhotoAngle angle) async {
    // Показываем инструкцию перед съёмкой
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppTheme.of(ctx);
        return AlertDialog(
          backgroundColor: colors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(ctx.l10n.photoPickTitle(angle.label(ctx.l10n)), style: TextStyle(color: colors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(angle.icon, size: 48, color: colors.primary),
            const SizedBox(height: 12),
            Text(angle.instruction(ctx.l10n), style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                ctx.l10n.photoTips,
                style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.5),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel, style: TextStyle(color: colors.textMuted))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.selectPhotoBtn),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;

    // Выбор источника
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final colors = AppTheme.of(ctx);
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: colors.primary),
              title: Text(ctx.l10n.takeCameraBtn, style: TextStyle(color: colors.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: colors.primary),
              title: Text(ctx.l10n.chooseGalleryBtn, style: TextStyle(color: colors.textPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1080);
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

    setState(() { _aiAnalyzing = true; _aiAnalysis = null; });

    try {
      final latest = _measurements.first;
      final previous = _measurements.length > 1 ? _measurements[1] : null;

      // Сохраняем состояние Bloc до любого await
      final blocProfile = () {
        final s = context.read<UserBloc>().state;
        return s is UserStateLoaded ? s.user.profile : null;
      }();

      // Читаем профиль напрямую из Firestore, минуя Bloc
      UserProfile? profile;
      try {
        final userEntity = await sl<UserRepository>().getUser(uid);
        profile = userEntity.profile;
      } catch (e, st) {
        appLogger.w('Progress: load user profile', error: e, stackTrace: st);
      }

      // Fallback: берём из Bloc если Firestore не вернул
      profile ??= blocProfile;

      if (profile == null) {
        setState(() => _aiAnalyzing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.fillProfileForAi)),
          );
        }
        return;
      }

      final hasPhotos = _photos.values.any((f) => f != null);

      final result = await sl<DeepSeekService>().analyzeProgress(
        profile: profile,
        latest: {
          'chest': latest.chestCm,
          'waist': latest.waistCm,
          'hips': latest.hipsCm,
          'bodyFat': latest.bodyFatPercent,
        },
        previous: previous != null ? {
          'chest': previous.chestCm,
          'waist': previous.waistCm,
          'hips': previous.hipsCm,
          'bodyFat': previous.bodyFatPercent,
        } : null,
        hasPhotos: hasPhotos,
      );

      if (mounted) setState(() { _aiAnalysis = result; _aiAnalyzing = false; });
    } catch (e) {
      if (mounted) setState(() { _aiAnalysis = '${context.l10n.error}: $e'; _aiAnalyzing = false; });
    }
  }

  Future<void> _openMeasurementsDialog() async {
    final uid = _userId;
    if (uid == null) return;
    final userState = context.read<UserBloc>().state;
    final profile = userState is UserStateLoaded ? userState.user.profile : null;
    await showDialog(
      context: context,
      builder: (ctx) => _MeasurementsDialog(
        profile: profile,
        onSave: (m) async {
          await sl<UserRepository>().saveMeasurement(userId: uid, measurement: m);
          await _loadMeasurements();
        },
      ),
    );
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          const _ProgressHeader(),
          const _DebriefCard(),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: colors.primary,
            unselectedLabelColor: colors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter'),
            tabs: [Tab(text: context.l10n.weightBodyTab), Tab(text: context.l10n.workoutsStatTab), Tab(text: context.l10n.healthTabLabel)],
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildBodyTab(), _buildWorkoutsTab(), _buildHealthTab()],
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Вес и тело ──────────────────────────────────────────────────────────────

  Widget _buildBodyTab() {
    final colors = AppTheme.of(context);
    final l10n = context.l10n;
    final weightText = _weight != null ? '${_weight!.toStringAsFixed(1)} ${l10n.dashboardKg}' : '— ${l10n.dashboardKg}';
    final currentWeight = _weight ?? (_weightData.isNotEmpty ? _weightData.last : 0.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colors.primary, colors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(children: [
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.currentWeightTitle, style: TextStyle(fontSize: 12, color: colors.primaryDark)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(weightText, style: TextStyle(fontFamily: 'Syne', fontSize: 36, fontWeight: FontWeight.w800, color: colors.textOnPrimary)),
              ),
              if (_height != null) Text('${l10n.onbHeightTitle}: ${(_height! * 100).toInt()} ${l10n.cmUnit}', style: TextStyle(fontSize: 12, color: colors.primaryDark)),
            ])),
            const SizedBox(width: 12),
            Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l10n.burnedLabel, style: TextStyle(fontSize: 11, color: colors.primaryDark)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _caloriesBurned > 0 ? '${_caloriesBurned.toInt()} ${l10n.kcalShort}' : '— ${l10n.kcalShort}',
                  style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: colors.textOnPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Text('${l10n.stepsLabel}: ${_steps > 0 ? _steps : '—'}', style: TextStyle(fontSize: 11, color: colors.primaryDark)),
            ])),
          ]),
        ),

        const SizedBox(height: 20),

        // Weight chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.weightChartTitle, style: AppTextStyles.titleM),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: currentWeight > 0
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => CustomPaint(
                        size: const Size(double.infinity, 160),
                        painter: _LineChartPainter(data: _weightData, progress: v, colors: colors),
                      ),
                    )
                  : Center(child: Text(l10n.noWeightData, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.textMuted))),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: _weightLabels.map((l) => Text(l, style: TextStyle(fontSize: 9, color: colors.textMuted))).toList()),
          ]),
        ),

        const SizedBox(height: 20),

        // Замеры тела
        Row(children: [
          Text(l10n.bodyMeasTitle, style: AppTextStyles.titleM),
          const Spacer(),
          GestureDetector(
            onTap: _openMeasurementsDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.add_rounded, size: 16, color: colors.primary),
                const SizedBox(width: 4),
                Text(l10n.add, style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (!_measurementsLoaded)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              _buildMeasurementCard('chest', l10n.chestMeasureLabel, _measurements.isNotEmpty ? _measurements.first.chestCm : null, l10n.cmUnit, colors),
              _buildMeasurementCard('waist', l10n.waistLabel, _measurements.isNotEmpty ? _measurements.first.waistCm : null, l10n.cmUnit, colors),
              _buildMeasurementCard('hips', l10n.hipsLabel, _measurements.isNotEmpty ? _measurements.first.hipsCm : null, l10n.cmUnit, colors),
              _buildMeasurementCard('fat', l10n.bodyFatLabel, _measurements.isNotEmpty ? _measurements.first.bodyFatPercent : null, '%', colors),
            ],
          ),

        if (_measurements.length >= 2) ...[
          const SizedBox(height: 8),
          Text(
            l10n.prevMeasLabel(_formatDate(_measurements[1].date)),
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ],

        const SizedBox(height: 20),

        // Фото прогресса
        _buildPhotoSection(colors),

        // AI анализ прогресса
        if (_measurements.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildAiAnalysisSection(colors),
        ],
      ],
    );
  }

  Widget _buildMeasurementCard(String key, String displayLabel, double? value, String unit, ThemePalette colors) {
    // Разница с предыдущим замером
    double? prevValue;
    if (_measurements.length >= 2) {
      final prev = _measurements[1];
      prevValue = key == 'chest' ? prev.chestCm
          : key == 'waist' ? prev.waistCm
          : key == 'hips' ? prev.hipsCm
          : prev.bodyFatPercent;
    }
    final diff = (value != null && prevValue != null) ? value - prevValue : null;
    final diffStr = diff != null ? '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}' : '';
    final isPositiveDiff = diff != null && (key == 'fat' ? diff < 0 : diff < 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(displayLabel, style: TextStyle(fontSize: 11, color: colors.textMuted)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value != null ? '$value $unit' : '— $unit',
              style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
          )),
          if (diffStr.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (isPositiveDiff ? colors.success : colors.error).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(diffStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPositiveDiff ? colors.success : colors.error)),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildPhotoSection(ThemePalette colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(context.l10n.photoProgressTitle2, style: AppTextStyles.titleM),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: colors.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(context.l10n.anglesLabel, style: TextStyle(fontSize: 11, color: colors.info, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(context.l10n.photoNote, style: TextStyle(fontSize: 12, color: colors.textMuted)),
        const SizedBox(height: 14),
        Row(children: _PhotoAngle.values.map((angle) {
          final file = _photos[angle];
          return Expanded(
            child: GestureDetector(
              onTap: () => _pickPhoto(angle),
              child: Container(
                height: 110,
                margin: EdgeInsets.only(right: angle != _PhotoAngle.back ? 8 : 0),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: file != null ? Border.all(color: colors.primary, width: 2) : null,
                  image: file != null ? DecorationImage(image: FileImage(file), fit: BoxFit.cover) : null,
                ),
                child: file == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(angle.icon, color: colors.textMuted, size: 28),
                        const SizedBox(height: 6),
                        Text(angle.label(context.l10n), style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(context.l10n.tapHint, style: TextStyle(fontSize: 9, color: colors.textMuted)),
                      ])
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                          ),
                          child: Text(angle.label(context.l10n), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
              ),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildAiAnalysisSection(ThemePalette colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.info.withValues(alpha: 0.12), colors.accentPurple.withValues(alpha: 0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.info.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(context.l10n.aiProgressTitle, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const Spacer(),
          if (!_aiAnalyzing)
            GestureDetector(
              onTap: _runAiAnalysis,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(10)),
                child: Text(_aiAnalysis != null ? context.l10n.updateBtn : context.l10n.analyzeBtn, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          else
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
        ]),
        const SizedBox(height: 10),
        if (_aiAnalysis != null) ...[
          Text(_aiAnalysis!, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.6)),
        ] else ...[
          Text(
            context.l10n.aiAnalysisHintText(_measurements.length, _photos.values.any((f) => f != null) ? context.l10n.photoProgressTitle2 : ''),
            style: TextStyle(fontSize: 13, color: colors.textMuted, height: 1.5),
          ),
        ],
      ]),
    );
  }

  // ─── Тренировки ───────────────────────────────────────────────────────────────

  Widget _buildWorkoutsTab() {
    final colors = AppTheme.of(context);
    final now = DateTime.now();
    final weekday = now.weekday;
    final dayLabels = [context.l10n.monShort, context.l10n.tueShort, context.l10n.wedShort, context.l10n.thuShort, context.l10n.friShort, context.l10n.satShort, context.l10n.sunShort];
    final summary = _periodSummary;
    final bars = _chartBars;

    // Today's activity (SP + HC fallback)
    final todayKcal  = _workoutKcalToday > 0 ? _workoutKcalToday : (_caloriesBurned > 0 ? _caloriesBurned.toInt() : 0);
    final todayWater = _waterMlToday > 0 ? _waterMlToday : ((_waterIntakeMl ?? 0) > 0 ? _waterIntakeMl!.toInt() : 0);
    final hasAnyActivity = todayKcal > 0 || todayWater > 0 || _steps > 0;

    // Weekly grid
    final doneCount = _weekWorkouts.take(weekday).where((d) => d).length;
    final completionPct = weekday > 0 ? (doneCount / weekday * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [

        // ── Period selector ──────────────────────────────────────────────────────
        Container(
          height: 40,
          decoration: BoxDecoration(color: colors.elevated, borderRadius: BorderRadius.circular(12)),
          child: Row(children: _StatPeriod.values.map((p) {
            final sel = p == _selectedPeriod;
            final label = switch (p) {
              _StatPeriod.today => context.l10n.periodTodayLabel,
              _StatPeriod.week  => context.l10n.periodWeekLabel,
              _StatPeriod.month => context.l10n.periodMonthLabel,
              _StatPeriod.year  => context.l10n.periodYearLabel,
            };
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(label,
                    style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? colors.textOnPrimary : colors.textMuted)),
                ),
              ),
            );
          }).toList()),
        ),

        const SizedBox(height: 16),

        // ── Period stats grid ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_periodTitle, style: AppTextStyles.titleM),
              const Spacer(),
              if (summary.done > 0 || summary.total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    summary.total > 0 ? '${(summary.done / summary.total * 100).round()}%' : '0%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            Text(context.l10n.workoutsDoneCountLabel(summary.done), style: TextStyle(fontSize: 11, color: colors.textMuted)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _PeriodStatCell(icon: '💪', label: context.l10n.taskWorkout, value: '${summary.done}/${summary.total}', color: colors.primary)),
              Expanded(child: _PeriodStatCell(icon: '🔥', label: context.l10n.kcalShort, value: summary.kcal > 0 ? '${summary.kcal.toInt()}' : '0', color: colors.accent)),
              Expanded(child: _PeriodStatCell(icon: '💧', label: context.l10n.waterLabel, value: summary.waterMl > 0 ? '${(summary.waterMl / 1000).toStringAsFixed(1)}л' : '0л', color: colors.info)),
              Expanded(child: _PeriodStatCell(icon: '🍽️', label: context.l10n.eatenLabel, value: summary.eatenCal > 0 ? '${summary.eatenCal}кк' : '0', color: colors.accentOrange)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Period bar chart ─────────────────────────────────────────────────────
        if (bars.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.workoutsChartTitle(_chartPeriodLabel), style: AppTextStyles.titleM),
              const SizedBox(height: 16),
              SizedBox(height: 120, child: _PeriodBarChart(bars: bars, colors: colors)),
              const SizedBox(height: 4),
            ]),
          ),

        // ── Streak ──────────────────────────────────────────────────────────────
        if (_currentStreak > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${context.l10n.dashboardStreak}: $_currentStreak ${context.l10n.dashboardDays}',
                    style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                Text(context.l10n.noBreakStreak, style: TextStyle(fontSize: 11, color: colors.textMuted)),
              ]),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        // ── Активность сегодня (SP + HC) ────────────────────────────────────────
        if (hasAnyActivity) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.today, style: AppTextStyles.titleM),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _ActivityStat(icon: Icons.directions_walk_rounded, color: colors.accentOrange, label: context.l10n.stepsLabel, value: _steps > 0 ? '$_steps' : '—')),
                Expanded(child: _ActivityStat(icon: Icons.local_fire_department_rounded, color: colors.error, label: context.l10n.burnedLabel, value: todayKcal > 0 ? '$todayKcal ${context.l10n.kcalShort}' : '—')),
                Expanded(child: _ActivityStat(icon: Icons.water_drop_rounded, color: colors.info, label: context.l10n.waterLabel, value: todayWater > 0 ? '$todayWater мл' : '—')),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // ── Недельная сетка ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(context.l10n.thisWeekLabel, style: AppTextStyles.titleM),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('$completionPct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(context.l10n.daysCompletedOf(doneCount, weekday),
                style: TextStyle(fontSize: 11, color: colors.textMuted)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isToday  = i == weekday - 1;
                final done     = _weekWorkouts.length > i ? _weekWorkouts[i] : false;
                final isFuture = i > weekday - 1;
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: done ? colors.primary : isFuture ? colors.elevated.withValues(alpha: 0.4) : colors.elevated,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday ? Border.all(color: colors.primary, width: 2) : null,
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : isFuture ? Icons.remove_rounded : Icons.close_rounded,
                      color: done ? colors.textOnPrimary : isFuture ? colors.textMuted.withValues(alpha: 0.3) : colors.textMuted,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dayLabels[i],
                      style: TextStyle(fontSize: 9,
                          color: isToday ? colors.primary : colors.textMuted,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                ]);
              }),
            ),
          ]),
        ),
      ],
    );
  }

  String get _periodTitle => switch (_selectedPeriod) {
    _StatPeriod.today => context.l10n.periodTodayLabel,
    _StatPeriod.week  => context.l10n.periodWeekLabel,
    _StatPeriod.month => context.l10n.periodMonthLabel,
    _StatPeriod.year  => context.l10n.periodYearLabel,
  };

  String get _chartPeriodLabel => switch (_selectedPeriod) {
    _StatPeriod.today => context.l10n.periodTodayLabel,
    _StatPeriod.week  => context.l10n.periodWeekLabel,
    _StatPeriod.month => context.l10n.periodMonthLabel,
    _StatPeriod.year  => context.l10n.periodYearLabel,
  };

  // ─── Здоровье ─────────────────────────────────────────────────────────────────

  Widget _buildHealthTab() {
    final colors = AppTheme.of(context);
    final sleepHours = _sleepMinutes != null && _sleepMinutes! > 0
        ? (_sleepMinutes! / 60.0).toStringAsFixed(1) : '—';
    final hasData = _healthLoaded && (_heartRateAvg != null || _steps > 0 || _sleepMinutes != null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      children: [
        _HealthCard(label: context.l10n.avgHeartRateLabel, value: _heartRateAvg != null ? '$_heartRateAvg' : '—', unit: context.l10n.bpmUnit, icon: Icons.favorite_rounded, color: colors.error, trend: _heartRateAvg != null ? context.l10n.normalBadge : '', positive: true),
        const SizedBox(height: 12),
        _HealthCard(label: context.l10n.restingHrLabel, value: _restingHeartRate != null ? '$_restingHeartRate' : '—', unit: context.l10n.bpmUnit, icon: Icons.monitor_heart_outlined, color: colors.accentPurple,
          trend: _restingHeartRate != null ? (_restingHeartRate! <= 60 ? 'отлично' : _restingHeartRate! <= 80 ? context.l10n.normalBadge : 'высокий') : '',
          positive: _restingHeartRate != null && _restingHeartRate! <= 80),
        const SizedBox(height: 12),
        _HealthCard(label: context.l10n.hrvLabel, value: _heartRateVariability != null ? _heartRateVariability!.toStringAsFixed(1) : '—', unit: context.l10n.msUnit, icon: Icons.show_chart_rounded, color: colors.accent,
          trend: _heartRateVariability != null ? (_heartRateVariability! >= 40 ? 'хорошо' : 'низкая') : '',
          positive: _heartRateVariability != null && _heartRateVariability! >= 40),
        const SizedBox(height: 12),
        _HealthCard(label: context.l10n.respiratoryRateLabel, value: _respiratoryRate != null ? _respiratoryRate!.toStringAsFixed(1) : '—', unit: context.l10n.bpmRespUnit, icon: Icons.air_rounded, color: colors.info,
          trend: _respiratoryRate != null ? (_respiratoryRate! <= 20 ? context.l10n.normalBadge : 'высокая') : '',
          positive: _respiratoryRate != null && _respiratoryRate! <= 20),
        const SizedBox(height: 12),
        _HealthCard(label: context.l10n.stepsTodayLabel, value: _steps > 0 ? '$_steps' : '—', unit: context.l10n.stepsUnit, icon: Icons.directions_walk_rounded, color: colors.primary,
          trend: _steps >= 10000 ? 'цель!' : _steps > 0 ? '-${10000 - _steps}' : '', positive: _steps >= 10000),
        const SizedBox(height: 12),
        _HealthCard(label: context.l10n.sleepLabel2, value: sleepHours, unit: context.l10n.hoursNightUnit, icon: Icons.bedtime_outlined, color: colors.accentPurple,
          trend: (_sleepMinutes ?? 0) >= 420 ? context.l10n.normalBadge : '', positive: (_sleepMinutes ?? 0) >= 420),
        const SizedBox(height: 12),
        _HealthCard(label: context.l10n.waterHealthLabel, value: (_waterIntakeMl ?? 0) > 0 ? '${_waterIntakeMl!.toInt()}' : '—', unit: context.l10n.mlHealthUnit, icon: Icons.water_drop_rounded, color: colors.info,
          trend: (_waterIntakeMl ?? 0) >= 2000 ? context.l10n.normalBadge : '', positive: (_waterIntakeMl ?? 0) >= 2000),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.info.withValues(alpha: 0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🤖 ${context.l10n.aiAdviceLabel}', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              hasData ? _buildAiAdvice() : 'Синхронизируйте Health Connect для получения AI рекомендаций.',
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.6),
            ),
          ]),
        ),
      ],
    );
  }

  String _buildAiAdvice() {
    final parts = <String>[];
    if (_steps > 0) {
      final estKcal = (_steps * 0.04).toInt();
      parts.add('Пройдено $_steps шагов (~$estKcal ккал).');
      if (_steps < 7000) {
        parts.add('Рекомендуется ещё ${7000 - _steps} шагов до минимальной нормы.');
      } else {
        parts.add('Хороший результат по шагам!');
      }
    }
    if (_heartRateAvg != null && _heartRateAvg! > 100) {
      parts.add('Пульс повышен ($_heartRateAvg уд/мин) — уделите внимание восстановлению.');
    }
    if (_sleepMinutes != null && _sleepMinutes! > 0 && _sleepMinutes! < 420) {
      parts.add('Сон ${(_sleepMinutes! / 60).toStringAsFixed(1)} ч — меньше нормы. Старайтесь спать 7–8 часов.');
    }
    return parts.isEmpty ? 'Данные синхронизированы. Продолжайте тренироваться!' : parts.join(' ');
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ─── Extracted sub-widgets ────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(children: [
        Text(context.l10n.navProgress, style: AppTextStyles.displayM),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.sync_rounded, size: 14, color: colors.textMuted),
            const SizedBox(width: 6),
            Text(context.l10n.syncTodayBtn, style: TextStyle(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _DebriefCard extends StatelessWidget {
  const _DebriefCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: () => context.push('/debrief'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary.withValues(alpha: 0.12), colors.accent.withValues(alpha: 0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.insights_rounded, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.weeklyDebriefTitle, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 3),
            Text(context.l10n.weeklyDebriefSubtitle, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: colors.primary, size: 15),
        ]),
      ),
    );
  }
}

// ─── Диалог замеров ───────────────────────────────────────────────────────────

class _MeasurementsDialog extends StatefulWidget {
  final Future<void> Function(BodyMeasurement) onSave;
  final UserProfile? profile;
  const _MeasurementsDialog({required this.onSave, this.profile});
  @override
  State<_MeasurementsDialog> createState() => _MeasurementsDialogState();
}

class _MeasurementsDialogState extends State<_MeasurementsDialog> {
  final _form = GlobalKey<FormState>();
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _hips = TextEditingController();
  final _fat = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _chest.dispose(); _waist.dispose(); _hips.dispose(); _fat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final m = BodyMeasurement(
      date: DateTime.now(),
      chestCm: _parseField(_chest.text),
      waistCm: _parseField(_waist.text),
      hipsCm: _parseField(_hips.text),
      bodyFatPercent: _parseField(_fat.text),
    );
    await widget.onSave(m);
    if (mounted) Navigator.pop(context);
  }

  double? _parseField(String s) => s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  void _calcBodyFat() {
    final p = widget.profile;
    if (p == null) return;
    final heightM = p.height / 100;
    final bmi = p.weight / (heightM * heightM);
    final bf = p.gender == Gender.male
        ? (1.20 * bmi) + (0.23 * p.age) - 16.2
        : (1.20 * bmi) + (0.23 * p.age) - 5.4;
    setState(() => _fat.text = bf.clamp(3, 50).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return AlertDialog(
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        Icon(Icons.straighten_rounded, color: colors.primary, size: 22),
        const SizedBox(width: 8),
        Text('Замеры тела', style: TextStyle(color: colors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 18)),
      ]),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Введите актуальные значения.\nПустые поля будут пропущены.', style: TextStyle(fontSize: 12, color: colors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _buildField('Грудь', 'см', _chest, colors, Icons.circle_outlined),
            const SizedBox(height: 12),
            _buildField('Талия', 'см', _waist, colors, Icons.circle_outlined),
            const SizedBox(height: 12),
            _buildField('Бёдра', 'см', _hips, colors, Icons.circle_outlined),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildField('Жир тела', '%', _fat, colors, Icons.percent_rounded)),
              if (widget.profile != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _calcBodyFat,
                    child: const Text('Рассчитать', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            if (widget.profile != null)
              Text('Расчёт по BMI (вес/рост/возраст/пол)', style: TextStyle(fontSize: 10, color: colors.textMuted)),
            const SizedBox(height: 8),
            Text(
              '💡 Измеряйте сантиметровой лентой утром натощак в одних и тех же условиях',
              style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: colors.textMuted))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Сохранить'),
        ),
      ],
    );
  }

  Widget _buildField(String label, String unit, TextEditingController ctrl, ThemePalette colors, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: '$label ($unit)',
        labelStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        suffixText: unit,
        suffixStyle: TextStyle(color: colors.textMuted),
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          final d = double.tryParse(v.trim().replaceAll(',', '.'));
          if (d == null || d <= 0) return 'Введите корректное значение';
        }
        return null;
      },
    );
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────


// ── Period stat cell ──────────────────────────────────────────────────────────
class _PeriodStatCell extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _PeriodStatCell({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 9, color: c.textMuted), textAlign: TextAlign.center),
    ]);
  }
}

// ── Period bar chart ──────────────────────────────────────────────────────────
class _PeriodBarChart extends StatelessWidget {
  final List<({String label, int done, int total, double kcal})> bars;
  final ThemePalette colors;
  const _PeriodBarChart({required this.bars, required this.colors});

  @override
  Widget build(BuildContext context) {
    final maxKcal = bars.fold<double>(1, (m, b) => b.kcal > m ? b.kcal : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: bars.map((b) {
        final fillRatio = maxKcal > 0 ? (b.kcal / maxKcal) : 0.0;
        final pct = b.total > 0 ? (b.done / b.total * 100).round() : 0;
        final barColor = b.done > 0 ? colors.primary : colors.elevated;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (b.done > 0)
                Text('$pct%', style: TextStyle(fontSize: 7, color: colors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: fillRatio > 0 ? (fillRatio * 84).clamp(4, 84) : 4,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  gradient: b.done > 0 ? LinearGradient(
                    colors: [colors.primary, colors.primaryLight],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ) : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(b.label,
                  style: TextStyle(fontSize: 8, color: colors.textMuted),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final ThemePalette colors;
  _LineChartPainter({required this.data, required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min).clamp(1, double.infinity);
    final divisor = (data.length - 1).clamp(1, double.infinity);

    final pts = data.asMap().entries.map((e) => Offset(e.key / divisor * size.width, (1 - (e.value - min) / range) * size.height)).toList();
    final animPts = pts.sublist(0, ((pts.length - 1) * progress).ceil() + 1);

    final fillPath = Path()..moveTo(animPts.first.dx, size.height);
    for (final p in animPts) { fillPath.lineTo(p.dx, p.dy); }
    fillPath..lineTo(animPts.last.dx, size.height)..close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(colors: [colors.primary.withValues(alpha: 0.3), colors.primary.withValues(alpha: 0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill);

    final linePath = Path()..moveTo(animPts.first.dx, animPts.first.dy);
    for (final p in animPts.skip(1)) { linePath.lineTo(p.dx, p.dy); }
    canvas.drawPath(linePath, Paint()..color = colors.primary..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    for (final p in animPts) {
      canvas.drawCircle(p, 4, Paint()..color = colors.primary);
      canvas.drawCircle(p, 2.5, Paint()..color = colors.background);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}


class _ActivityStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _ActivityStat({required this.icon, required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
      Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
    ]);
  }
}

class _HealthCard extends StatelessWidget {
  final String label, value, unit, trend;
  final IconData icon;
  final Color color;
  final bool positive;
  const _HealthCard({required this.label, required this.value, required this.unit, required this.icon, required this.color, required this.trend, required this.positive});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06))),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          const SizedBox(height: 2),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary)))),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(unit, style: TextStyle(fontSize: 11, color: colors.textMuted))),
          ]),
        ])),
        if (trend.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: positive ? colors.success.withValues(alpha: 0.12) : colors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(trend, style: TextStyle(fontSize: 11, color: positive ? colors.success : colors.error, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }
}
