import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/presentation/widgets/workout/weekly_summary_card.dart';
import 'package:fitnesbuster/presentation/widgets/workout/technique_sheet.dart';
import 'package:fitnesbuster/presentation/widgets/workout/workout_plan_widgets.dart';
import 'package:fitnesbuster/presentation/widgets/workout/workout_day_selector.dart';
import 'package:fitnesbuster/presentation/widgets/workout/workout_plan_header.dart';
import 'package:fitnesbuster/presentation/widgets/workout/day_detail_view.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';
import 'package:fitnesbuster/core/services/share_intent_service.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/presentation/screens/workout/import_workout_sheet.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  /// Increment to trigger a reload on every [WorkoutPlanScreen] instance.
  static final planVersion = ValueNotifier<int>(0);

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _days = [];
  WorkoutPlanMeta _meta = const WorkoutPlanMeta();
  int _selectedDay = 0;
  bool _testWeekCompleted = false;
  bool _todayWorkoutDone = false;
  bool _matcherReady = false;

  List<String> _getWeekLabels(AppLocalizations l10n) => [
    l10n.monShort, l10n.tueShort, l10n.wedShort, l10n.thuShort,
    l10n.friShort, l10n.satShort, l10n.sunShort,
  ];

  @override
  void initState() {
    super.initState();
    appLogger.d('[WorkoutPlan] initState');
    _tabCtrl = TabController(length: 2, vsync: this);
    _selectedDay = (DateTime.now().weekday - 1).clamp(0, 6);
    _load();
    WorkoutPlanScreen.planVersion.addListener(_onPlanVersionChanged);
    ShareIntentService.pendingShare.addListener(_onPendingShare);
    ShareIntentService.checkInitialShare();
  }

  @override
  void dispose() {
    WorkoutPlanScreen.planVersion.removeListener(_onPlanVersionChanged);
    ShareIntentService.pendingShare.removeListener(_onPendingShare);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onPendingShare() {
    final content = ShareIntentService.consume();
    if (content == null || content.isEmpty) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImportWorkoutSheet(initialContent: content),
    );
  }

  void _openImport() {
    showImportWorkoutSheet(context);
  }

  void _onPlanVersionChanged() {
    appLogger.d('[WorkoutPlan] planVersion changed, calling _load');
    _load();
  }

  Future<void> _load() async {
    try {
      final authState = context.read<AuthBloc>().state;
      final uid = authState is AuthStateAuthenticated ? authState.user.id : null;
      if (uid == null) {
        appLogger.d('[WorkoutPlan] _load: uid is null');
        if (mounted) {
          setState(() { _loading = false; _error = AppLocalizations.tl('loginRequired'); });
        }
        return;
      }
      final repo = sl<IUserRepository>();
      appLogger.d('[WorkoutPlan] _load: calling getAiPlans for $uid');
      final plans = await repo.getAiPlans(uid);
      final jsonStr = plans['workoutPlan'];
      appLogger.d('[WorkoutPlan] _load: workoutPlan=${jsonStr != null ? "OK len=${jsonStr.length}" : "NULL"} mealPlan=${plans["mealPlan"] != null ? "OK" : "NULL"}');
      if (jsonStr == null) {
        if (mounted) {
          setState(() { _loading = false; _error = AppLocalizations.tl('planNotGeneratedMsg'); });
        }
        return;
      }
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      appLogger.d('[WorkoutPlan] _load: jsonDecode OK, keys=${data.keys.join(",")}');
      final rawPlan = data['plan'];
      final planList = rawPlan is List
          ? rawPlan.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList()
          : <Map<String, dynamic>>[];
      appLogger.d('[WorkoutPlan] _load: planList length=${planList.length}');
      final meta = WorkoutPlanMeta.fromPlanJson(data);
      int completed = 0;
      try {
        completed = await repo.isTestWeekCompleted(uid) ? 1 : 0;
      } catch (_) {
        // Firestore unavailable — assume not completed
      }
      bool todayDone = false;
      try {
        todayDone = await sl<ISettingsRepository>().getWorkoutDone(todayKey());
      } catch (_) {}
      sl<IExerciseService>().init().then((_) {
        if (mounted) setState(() => _matcherReady = true);
      });
      if (mounted) {
        setState(() {
          _loading = false;
          _days = planList;
          _meta = meta;
          _testWeekCompleted = completed == 1;
          _todayWorkoutDone = todayDone;
        });
      }
    } on FormatException catch (e) {
      appLogger.d('[WorkoutPlan] _load: FormatException', error: e);
      if (mounted) {
        setState(() { _loading = false; _error = AppLocalizations.tl('planDamagedMsg'); });
      }
    } catch (e) {
      appLogger.d('[WorkoutPlan] _load: Exception', error: e);
      if (mounted) {
        setState(() { _loading = false; _error = AppLocalizations.tl('planLoadFailMsg'); });
      }
    }
  }

  bool _isRest(Map<String, dynamic> day) {
    final exercises = day['exercises'] as List? ?? [];
    final focus = (day['focus'] as String? ?? day['name'] as String? ?? '').toLowerCase();
    final type = (day['type'] as String? ?? '').toLowerCase();
    return exercises.isEmpty ||
        focus.contains(AppLocalizations.tl('restDayKeyword')) ||
        focus.contains(AppLocalizations.tl('recoveryKeyword'))
        || type == 'rest' || type == 'active_recovery';
  }

  String _dayIcon(Map<String, dynamic> day) {
    if (_isRest(day)) return '😴';
    final focus = (day['focus'] as String? ?? day['name'] as String? ?? '').toLowerCase();
    if (focus.contains(AppLocalizations.tl('cardioKeyword')) || focus.contains(AppLocalizations.tl('intervalKeyword'))) return '🏃';
    if (focus.contains(AppLocalizations.tl('legDayKeyword')) || focus.contains(AppLocalizations.tl('glutesKeyword'))) return '🦵';
    if (focus.contains(AppLocalizations.tl('chestKeyword')) || focus.contains(AppLocalizations.tl('tricepsKeyword'))) return '💪';
    if (focus.contains(AppLocalizations.tl('backKeyword')) || focus.contains(AppLocalizations.tl('bicepsKeyword'))) return '🏋️';
    if (focus.contains(AppLocalizations.tl('shouldersKeyword')) || focus.contains(AppLocalizations.tl('absKeyword'))) return '⚡';
    return '🏋️';
  }

  Color _rpeColor(int rpe, dynamic colors) {
    if (rpe <= 0) return colors.textMuted as Color;
    if (rpe <= 5) return colors.success as Color;
    if (rpe <= 7) return colors.accentOrange as Color;
    return colors.error as Color;
  }

  void _showExercise3D(String exerciseName, Set<String> primaryZones, Set<String> secondaryZones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Muscle3DSheet(
        title: exerciseName,
        primaryMuscles: primaryZones,
        secondaryMuscles: secondaryZones,
      ),
    );
  }

  void _showExerciseTechnique(String exerciseName, String techniqueCue, String progression, String weightGuideline) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutTechniqueSheet(
        title: exerciseName,
        techniqueCue: techniqueCue,
        progression: progression,
        weightGuideline: weightGuideline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(colors)
                : Column(children: [
                    WorkoutPlanHeader(colors: colors, onOpenImport: _openImport),
                    if (!_testWeekCompleted) _buildTestWeekCard(colors),
                    TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
                      dividerColor: Colors.transparent,
                      labelColor: colors.primary,
                      unselectedLabelColor: colors.textMuted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter'),
                      tabs: [Tab(text: context.l10n.weekTab), Tab(text: context.l10n.fullPlanTab)],
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    Expanded(
                      child: TabBarView(controller: _tabCtrl, children: [
                        _buildWeekView(colors),
                        _buildFullPlan(colors),
                      ]),
                    ),
                  ]),
      ),
    );
  }

  Widget _buildError(dynamic colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.fitness_center_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(fontSize: 15, color: colors.textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.l10n.retry),
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: colors.textOnPrimary),
          ),
        ]),
      ),
    );
  }

  Widget _buildTestWeekCard(dynamic colors) {
    return GestureDetector(
      onTap: () => context.push('/test-week'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.info.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.testWeekTitle, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            Text(context.l10n.testWeekSubtitle, style: TextStyle(fontSize: 11, color: colors.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: colors.info, borderRadius: BorderRadius.circular(8)),
            child: Text(context.l10n.startTestBtn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textOnPrimary)),
          ),
        ]),
      ),
    );
  }

  Widget _buildWeekView(dynamic colors) {
    if (_days.isEmpty) {
      return Center(child: Text(context.l10n.noData, style: TextStyle(color: colors.textMuted)));
    }
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      children: [
        if (_meta.weeklySummary.isNotEmpty) ...[
          WorkoutWeekSummary(meta: _meta, colors: colors),
          const SizedBox(height: 16),
        ],
        WorkoutDaySelector(
          days: _days,
          selectedDay: _selectedDay,
          todayIdx: todayIdx,
          onDaySelected: (i) => setState(() => _selectedDay = i),
          colors: colors,
          dayIcon: _dayIcon,
          weekLabels: _getWeekLabels,
        ),
        const SizedBox(height: 20),
        if (_selectedDay < _days.length)
          DayDetailView(
            key: ValueKey('day_$_selectedDay'),
            colors: colors,
            day: _days[_selectedDay],
            label: context.l10n.dayLabel(_selectedDay + 1),
            selectedDay: _selectedDay,
            dateWorkoutDone: _todayWorkoutDone,
            matcherReady: _matcherReady,
            isRest: _isRest(_days[_selectedDay]),
            onShow3D: _showExercise3D,
            onShowTechnique: _showExerciseTechnique,
            onWorkoutCompleted: () { if (mounted) setState(() => _todayWorkoutDone = true); },
          ),
        if (_meta.recommendations.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(context.l10n.weeklyRecsTitle, style: AppTextStyles.titleM),
          const SizedBox(height: 12),
          ..._meta.recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•', style: TextStyle(color: colors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(child: Text(rec, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.45))),
            ]),
          )),
        ],
        if (_meta.nextWeekPreview.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.accentPurple.withValues(alpha: 0.25)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🔮', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.nextWeekTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.accentPurple)),
                const SizedBox(height: 4),
                Text(_meta.nextWeekPreview, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
              ])),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildFullPlan(dynamic colors) {
    if (_days.isEmpty) {
      return Center(child: Text(context.l10n.noData, style: TextStyle(color: colors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      itemCount: _days.length,
      itemBuilder: (ctx, i) {
        final day = _days[i];
        final focus = day['focus'] as String? ?? day['name'] as String? ?? '';
        final exercises = (day['exercises'] as List? ?? []).cast<Map<String, dynamic>>();
        final cardio = (day['cardio_minutes'] as num?)?.toInt() ?? 0;
        final isRest = _isRest(day);
        final label = context.l10n.dayLabel(i + 1);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isRest ? colors.surfaceLight : colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_dayIcon(day), style: const TextStyle(fontSize: 20))),
            ),
            title: Text(
              '$label — $focus',
              style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              isRest ? context.l10n.restDayTitle : (cardio > 0 ? '${context.l10n.exercisesCount(exercises.length)} · ${context.l10n.cardioMinutes(cardio)}' : context.l10n.exercisesCount(exercises.length)),
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            children: isRest
                ? [Text(day['notes'] as String? ?? context.l10n.restDayTitle, style: TextStyle(fontSize: 13, color: colors.textMuted))]
                : exercises.map((ex) {
                    final rpe = (ex['rpe'] as num?)?.toInt() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.radio_button_unchecked, size: 14, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          '${ex['name']} — ${ex['sets']}×${ex['reps']}',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        )),
                        if (rpe > 0) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _rpeColor(rpe, colors).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('RPE $rpe', style: TextStyle(fontSize: 10, color: _rpeColor(rpe, colors), fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    );
                  }).toList(),
          ),
        );
      },
    );
  }
}
