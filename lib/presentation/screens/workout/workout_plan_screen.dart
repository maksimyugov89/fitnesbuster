import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/presentation/widgets/workout/muscle_map_3d_widget.dart';
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
    return exercises.isEmpty || focus.contains('отдых') || focus.contains('восстановлен')
        || type == 'rest' || type == 'active_recovery';
  }

  String _dayIcon(Map<String, dynamic> day) {
    if (_isRest(day)) return '😴';
    final focus = (day['focus'] as String? ?? day['name'] as String? ?? '').toLowerCase();
    if (focus.contains('кардио') || focus.contains('интервал')) return '🏃';
    if (focus.contains('нога') || focus.contains('ягодиц')) return '🦵';
    if (focus.contains('грудн') || focus.contains('трицепс')) return '💪';
    if (focus.contains('спина') || focus.contains('бицепс')) return '🏋️';
    if (focus.contains('плечи') || focus.contains('пресс')) return '⚡';
    return '🏋️';
  }

  Color _rpeColor(int rpe, dynamic colors) {
    if (rpe <= 0) return colors.textMuted as Color;
    if (rpe <= 5) return colors.success as Color;
    if (rpe <= 7) return colors.accentOrange as Color;
    return colors.error as Color;
  }

  // Safely converts a dynamic JSON value (String or List) to String.
  static String _s(dynamic v) {
    if (v is String) return v;
    if (v is List) return v.map((e) => e.toString()).join(', ');
    return '';
  }

  // Maps Russian muscle text from AI plan → 3D zone IDs for MuscleMap3DWidget.
  // Handles both adjective forms ("грудная") and noun forms ("грудь") that AI may generate.
  static Set<String> _muscleTextToZoneIds(String text) {
    final t = text.toLowerCase();
    final zones = <String>{};
    // Chest: catches "грудная", "грудные" AND short noun "грудь"
    if (t.contains('грудн') || t.contains('грудь') || t.contains('пектор')) {
      zones.addAll(['pectoralis_upper', 'pectoralis_lower']);
    }
    if (t.contains('малая грудн') || (t.contains('грудн') && t.contains('малая'))) {
      zones.add('pectoralis_minor');
    }
    // Back: catches "широчайшие", "спина", "спину", "спиной"
    if (t.contains('широч') || t.contains('latiss') || t.contains('lats') || t.contains('спин')) {
      zones.add('latissimus');
    }
    if (t.contains('трапец') || t.contains('trapez')) {
      zones.addAll(['upper_trapezius', 'middle_trapezius', 'lower_trapezius']);
    }
    // Shoulders: catches "дельтовидные" AND noun forms "плечи", "плечо"
    if (t.contains('дельт') || t.contains('delt') || t.contains('плечи') || t.contains('плечо')) {
      if (t.contains('перед')) {
        zones.add('anterior_deltoid');
      } else if (t.contains('задн')) {
        zones.add('posterior_deltoid');
      } else if (t.contains('сред') || t.contains('боков') || t.contains('латер')) {
        zones.add('lateral_deltoid');
      } else {
        zones.addAll(['anterior_deltoid', 'lateral_deltoid', 'posterior_deltoid']);
      }
    }
    if (t.contains('бицепс') || t.contains('bicep')) {
      zones.add('biceps');
    }
    if (t.contains('трицепс') || t.contains('tricep')) {
      zones.add('triceps');
    }
    if (t.contains('квадр') || t.contains('quad') || (t.contains('бедр') && t.contains('перед'))) {
      zones.add('quadriceps');
    }
    if (t.contains('бицепс бедра') || (t.contains('задн') && t.contains('бедр')) || t.contains('hamstr')) {
      zones.add('hamstrings');
    }
    // Glutes: catches "ягодичные", "ягодичная" AND noun "ягодицы", "ягодица"
    if (t.contains('ягоди') || t.contains('glute')) {
      if (t.contains('средн') || t.contains('medius')) {
        zones.add('gluteus_medius');
      } else {
        zones.addAll(['gluteus_maximus', 'gluteus_medius']);
      }
    }
    if (t.contains('икр') || t.contains('голень') || t.contains('calf') || t.contains('calves')) {
      zones.addAll(['gastrocnemius', 'soleus']);
    }
    if (t.contains('пресс') || t.contains('брюшн') || t.contains('abdom') || t.contains('rectus') ||
        (t.contains('прям') && t.contains('живот'))) {
      zones.add('rectus_abdominis');
    }
    if (t.contains('косые') || t.contains('облик') || t.contains('oblique')) {
      zones.add('external_oblique');
    }
    if (t.contains('поперечн') || t.contains('transvers')) {
      zones.add('transverse_abdominis');
    }
    if ((t.contains('разгибател') && t.contains('спин')) || t.contains('erector') || t.contains('выпрямит') || t.contains('поясниц')) {
      zones.add('erector_spinae');
    }
    if (t.contains('ромбовидн') || t.contains('rhomb')) {
      zones.add('teres_major');
    }
    if (t.contains('предплечь') || t.contains('forearm')) {
      zones.add('forearm_flexors');
    }
    if (t.contains('шея') || t.contains('neck') || t.contains('лопатк') || t.contains('грудино')) {
      zones.add('neck');
    }
    if (t.contains('приводящ') || t.contains('adduct')) {
      zones.add('adductors');
    }
    if ((t.contains('сгибател') && t.contains('бедр')) || t.contains('подвздошн') || t.contains('hip flex')) {
      zones.add('hip_flexors');
    }
    if (t.contains('зубчат') || t.contains('serratus')) {
      zones.add('serratus_anterior');
    }
    if (t.contains('манжет') || t.contains('rotator') || t.contains('вращател')) {
      zones.add('rotator_cuff');
    }
    if ((t.contains('плечев') && !t.contains('пояс')) || t.contains('brachiali')) {
      zones.add('brachialis');
    }
    if (t.contains('тибиалис') || t.contains('tibial') || (t.contains('перед') && t.contains('берц'))) {
      zones.add('tibialis_anterior');
    }
    return zones;
  }

  void _showExercise3D(String exerciseName, Set<String> primaryZones, Set<String> secondaryZones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Muscle3DSheet(
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
      builder: (_) => _TechniqueSheet(
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
                    _buildHeader(colors),
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

  Widget _buildHeader(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Top row: ЛР + Календарь (занимают всю ширину) ──────────────
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRouter.prTracker),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.emoji_events_rounded, color: colors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(context.l10n.prTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRouter.workoutCalendar),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.accentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.calendar_month_rounded, color: colors.accentPurple, size: 18),
                  const SizedBox(width: 6),
                  Text(context.l10n.calendarBtn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.accentPurple)),
                ]),
              ),
            ),
          ),
        ]),
        // ── Title row: "Тренировки" + кнопка База ──────────────────────
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.workoutsTitle, style: AppTextStyles.displayM),
              Text(context.l10n.aiPlanSubtitle, style: TextStyle(fontSize: 13, color: colors.textMuted)),
            ]),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push(AppRouter.exerciseBrowser),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.search_rounded, color: colors.accent, size: 18),
                const SizedBox(width: 6),
                Text(context.l10n.baseShort, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.accent)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openImport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_fix_high_rounded, color: colors.primary, size: 18),
                const SizedBox(width: 6),
                Text(context.l10n.aiCorrShort, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.primary)),
              ]),
            ),
          ),
        ]),
      ]),
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
    final count = _days.length.clamp(0, 7);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      children: [
        // ── Weekly summary ──
        if (_meta.weeklySummary.isNotEmpty) ...[
          _WeeklySummaryCard(meta: _meta, colors: colors),
          const SizedBox(height: 16),
        ],

        // ── Day selector ──
        SizedBox(
          height: 84,
          child: Row(
            children: List.generate(count, (i) {
              final day = _days[i];
              final isSelected = i == _selectedDay;
              final isToday = i == todayIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : isToday ? colors.primary.withValues(alpha: 0.1) : colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? colors.primary : isToday ? colors.primary.withValues(alpha: 0.4) : colors.textPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        _getWeekLabels(context.l10n)[i],
                        style: TextStyle(fontSize: 10, color: isSelected ? colors.textOnPrimary : colors.textMuted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(_dayIcon(day), style: const TextStyle(fontSize: 18)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),

        // ── Selected day detail ──
        if (_selectedDay < _days.length)
          _buildDayDetail(
            colors,
            _days[_selectedDay],
            context.l10n.dayLabel(_selectedDay + 1),
          ),

        // ── Recommendations ──
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

        // ── Next week preview ──
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

  Widget _buildDayDetail(dynamic colors, Map<String, dynamic> day, String label) {
    final focus = day['focus'] as String? ?? day['name'] as String? ?? '';
    final exercises = (day['exercises'] as List? ?? []).cast<Map<String, dynamic>>();
    final cardio = (day['cardio_minutes'] as num?)?.toInt() ?? 0;
    final notes = day['notes'] as String? ?? '';
    final isRest = _isRest(day);
    final warmup = (day['warmup'] as List? ?? []).map((e) => e.toString()).toList();
    final cooldown = (day['cooldown'] as List? ?? []).map((e) => e.toString()).toList();
    final duration = (day['duration_minutes'] as num?)?.toInt() ?? 0;
    final estCal = (day['estimated_calories_burned'] as num?)?.toInt() ?? 0;

    final workoutDay = isRest ? null : WorkoutDay(
      day: _selectedDay + 1,
      focus: focus,
      exercises: exercises.map((ex) => WorkoutExercise.fromJson(ex)).toList(),
      cardioMinutes: cardio,
      notes: notes,
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Заголовок ──
      Row(children: [
        Expanded(child: Text('$label — $focus', style: AppTextStyles.titleL, overflow: TextOverflow.ellipsis)),
        if (cardio > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: colors.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text('🏃 ${context.l10n.minSuffix(cardio)}', style: TextStyle(fontSize: 12, color: colors.accentOrange, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),

      // ── Duration + calories meta row ──
      if (duration > 0 || estCal > 0) ...[
        const SizedBox(height: 6),
        Row(children: [
          if (duration > 0) _MetaChip(icon: Icons.timer_outlined, label: context.l10n.minSuffix(duration), colors: colors),
          if (duration > 0 && estCal > 0) const SizedBox(width: 8),
          if (estCal > 0) _MetaChip(icon: Icons.local_fire_department_outlined, label: context.l10n.kcalSuffix(estCal), colors: colors),
        ]),
      ],
      const SizedBox(height: 12),

      // ── 3D Мышцы дня (кнопка) ──
      if (!isRest && exercises.isNotEmpty) ...[
        _buildMusclesDayButton(colors, exercises),
      ],

      // ── Кнопка "Начать" / "Выполнено" ──
      if (!isRest) ...[
        if (_todayWorkoutDone && _selectedDay == (DateTime.now().weekday - 1).clamp(0, 6))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.success.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, color: colors.success, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.l10n.workoutDoneStatus, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: colors.success)),
                  Text(context.l10n.workoutDoneSubtitleNext, style: TextStyle(fontSize: 11, color: colors.success.withValues(alpha: 0.8))),
                ]),
              ),
              Icon(Icons.emoji_events_rounded, color: colors.success.withValues(alpha: 0.7), size: 20),
            ]),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withValues(alpha: 0.75)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await context.push(AppRouter.workoutExecution, extra: workoutDay);
                  if (mounted) {
                    bool done = false;
                    try { done = await sl<ISettingsRepository>().getWorkoutDone(todayKey()); } catch (_) {}
                    if (mounted) setState(() => _todayWorkoutDone = done);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(context.l10n.startWorkoutBtn, style: const TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(cardio > 0 ? context.l10n.startWorkoutWithCardio(exercises.length, workoutDay!.totalSets, cardio) : context.l10n.startWorkoutDetails(exercises.length, workoutDay!.totalSets),
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                      ]),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
                  ]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],

      // ── Разминка ──
      if (warmup.isNotEmpty) ...[
        _SectionList(title: context.l10n.warmupTitle, items: warmup, color: colors.accentOrange, colors: colors),
        const SizedBox(height: 12),
      ],

      // ── Rest / упражнения ──
      if (isRest)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
          ),
          child: Row(children: [
            const Text('😴', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.restDayTitle, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text(notes.isNotEmpty ? notes : context.l10n.restDayNote, style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.4)),
            ])),
          ]),
        )
      else
        ...exercises.map((ex) => _buildExerciseCard(colors, ex)),

      // ── Заминка ──
      if (cooldown.isNotEmpty && !isRest) ...[
        const SizedBox(height: 12),
        _SectionList(title: context.l10n.cooldownTitle, items: cooldown, color: colors.info, colors: colors),
      ],

      // ── Заметки ──
      if (notes.isNotEmpty && !isRest) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.info.withValues(alpha: 0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: colors.info, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(notes, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4))),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildMusclesDayButton(dynamic colors, List<Map<String, dynamic>> exercises) {
    final primary = <String>{};
    final secondary = <String>{};
    for (final ex in exercises) {
      final p = _s(ex['muscle_primary']).isNotEmpty ? _s(ex['muscle_primary']) : _s(ex['muscle_group']);
      final s = _s(ex['muscle_secondary']);
      if (p.isNotEmpty) primary.addAll(_muscleTextToZoneIds(p));
      if (s.isNotEmpty) secondary.addAll(_muscleTextToZoneIds(s));
    }
    if (primary.isEmpty && secondary.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showExercise3D(context.l10n.musclesWorkoutTitle, primary, secondary),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.view_in_ar_rounded, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.musclesWorkoutTitle, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            Text(context.l10n.view3D, style: TextStyle(fontSize: 11, color: colors.textMuted)),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFFE84444), shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFF4FA3E0), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textMuted),
          ]),
        ]),
      ),
    );
  }

  Widget _buildExerciseCard(dynamic colors, Map<String, dynamic> ex) {
    final name = _s(ex['name']).isNotEmpty ? _s(ex['name']) : context.l10n.exerciseDefault;
    final sets = ex['sets']?.toString() ?? '3';
    final reps = ex['reps']?.toString() ?? '';
    final rest = (ex['rest_seconds'] as num?)?.toInt() ?? 60;
    final rpe = (ex['rpe'] as num?)?.toInt() ?? 0;
    final weightGuideline = _s(ex['weight_guideline']);
    final techniqueCue = _s(ex['technique_cue']).isNotEmpty ? _s(ex['technique_cue']) : _s(ex['technique_tip']);
    final progression = _s(ex['progression']);
    final musclePrimary = _s(ex['muscle_primary']).isNotEmpty ? _s(ex['muscle_primary']) : _s(ex['muscle_group']);
    final muscleSecondary = _s(ex['muscle_secondary']);
    final primaryZones = musclePrimary.isNotEmpty ? _muscleTextToZoneIds(musclePrimary) : <String>{};
    final secondaryZones = muscleSecondary.isNotEmpty ? _muscleTextToZoneIds(muscleSecondary) : <String>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _ExerciseGifThumb(
            name: name,
            gifUrl: _matcherReady ? sl<IExerciseService>().findByRuName(name)?.gifUrl : null,
            accentColor: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Text('$sets × $reps', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              if (musclePrimary.isNotEmpty) ...[
                Text('  ·  ', style: TextStyle(color: colors.textMuted)),
                Flexible(child: Text(musclePrimary, style: TextStyle(fontSize: 11, color: colors.textMuted), overflow: TextOverflow.ellipsis)),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('⏱ $rest с', style: TextStyle(fontSize: 11, color: colors.textMuted)),
            if (rpe > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _rpeColor(rpe, colors).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('RPE $rpe', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _rpeColor(rpe, colors))),
              ),
            ],
          ]),
        ]),

        // ── Extra info ──
        if (weightGuideline.isNotEmpty || techniqueCue.isNotEmpty || progression.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (weightGuideline.isNotEmpty)
            _ExerciseMeta(icon: Icons.monitor_weight_outlined, text: weightGuideline, colors: colors),
          if (techniqueCue.isNotEmpty)
            _ExerciseMeta(icon: Icons.lightbulb_outline_rounded, text: techniqueCue, colors: colors),
          if (progression.isNotEmpty)
            _ExerciseMeta(icon: Icons.trending_up_rounded, text: progression, colors: colors),
        ],

        // ── 3D мышцы + Техника кнопки ──
        if (primaryZones.isNotEmpty || techniqueCue.isNotEmpty || progression.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(children: [
            if (primaryZones.isNotEmpty)
              GestureDetector(
                onTap: () => _showExercise3D(name, primaryZones, secondaryZones),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.view_in_ar_rounded, color: colors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text('3D мышцы', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
                  ]),
                ),
              ),
            const Spacer(),
            if (techniqueCue.isNotEmpty || progression.isNotEmpty)
              GestureDetector(
                onTap: () => _showExerciseTechnique(name, techniqueCue, progression, weightGuideline),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF9500).withValues(alpha: 0.2)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.format_list_bulleted_rounded, color: Color(0xFFFF9500), size: 14),
                    SizedBox(width: 6),
                    Text('Техника', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFF9500))),
                  ]),
                ),
              ),
          ]),
        ],
      ]),
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

// ── Weekly summary card ────────────────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final WorkoutPlanMeta meta;
  final dynamic colors;
  const _WeeklySummaryCard({required this.meta, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        const Text('📊', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Неделя ${meta.weekNumber}${meta.phase.isNotEmpty ? " · ${meta.phase}" : ""}',
            style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          if (meta.weeklySummary.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(meta.weeklySummary, style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4)),
          ],
        ])),
        if (meta.weeklyVolumeSets > 0) Column(children: [
          Text('${meta.weeklyVolumeSets}', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: colors.primary)),
          Text('подх.', style: TextStyle(fontSize: 9, color: colors.textMuted)),
        ]),
      ]),
    );
  }
}

// ── Section list (warmup / cooldown) ──────────────────────────────────────────

class _SectionList extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final dynamic colors;
  const _SectionList({required this.title, required this.items, required this.color, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5, right: 8),
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            Expanded(child: Text(item, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}

// ── Exercise meta row ─────────────────────────────────────────────────────────

class _ExerciseMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final dynamic colors;
  const _ExerciseMeta({required this.icon, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 13, color: colors.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.4))),
      ]),
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic colors;
  const _MetaChip({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: colors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── 3D Muscle bottom sheet ────────────────────────────────────────────────────

class _Muscle3DSheet extends StatelessWidget {
  final String title;
  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;

  const _Muscle3DSheet({
    required this.title,
    required this.primaryMuscles,
    required this.secondaryMuscles,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sheetH = MediaQuery.of(context).size.height * 0.82;

    return Container(
      height: sheetH,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
          width: 38, height: 4,
          decoration: BoxDecoration(
            color: colors.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Icon(Icons.view_in_ar_rounded, color: colors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, color: colors.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
            ),
          ]),
        ),
        const SizedBox(height: 4),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const _LegendDot(color: Color(0xFFE84444), label: 'Основные'),
            const SizedBox(width: 16),
            if (secondaryMuscles.isNotEmpty)
              const _LegendDot(color: Color(0xFF4FA3E0), label: 'Вспомогательные'),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: MuscleMap3DWidget(
              primaryMuscles: primaryMuscles,
              secondaryMuscles: secondaryMuscles,
              height: sheetH - 100,
            ),
          ),
        ),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
    ]);
  }
}

class _TechniqueSheet extends StatefulWidget {
  final String title;
  final String techniqueCue;
  final String progression;
  final String weightGuideline;

  const _TechniqueSheet({
    required this.title,
    required this.techniqueCue,
    required this.progression,
    required this.weightGuideline,
  });

  @override
  State<_TechniqueSheet> createState() => _TechniqueSheetState();
}

class _TechniqueSheetState extends State<_TechniqueSheet> {
  String? _gifUrl;

  @override
  void initState() {
    super.initState();
    _loadGif();
  }

  Future<void> _loadGif() async {
    final exService = sl<IExerciseService>();
    await exService.init();
    final model = exService.findByRuName(widget.title);
    if (mounted && model?.gifUrl != null) setState(() => _gifUrl = model!.gifUrl);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(
          width: 38, height: 4,
          decoration: BoxDecoration(
            color: colors.textMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFFFF9500), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, color: colors.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20,
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Exercise GIF demonstration
              if (_gifUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: _gifUrl!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: colors.textMuted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF9500),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Technique sections
              if (widget.techniqueCue.isNotEmpty) ...[
                _TechniqueSection(
                  icon: Icons.lightbulb_rounded,
                  label: 'Техника',
                  text: widget.techniqueCue,
                  color: const Color(0xFFFF9500),
                  colors: colors,
                ),
                const SizedBox(height: 12),
              ],
              if (widget.weightGuideline.isNotEmpty) ...[
                _TechniqueSection(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Нагрузка',
                  text: widget.weightGuideline,
                  color: const Color(0xFF4FA3E0),
                  colors: colors,
                ),
                const SizedBox(height: 12),
              ],
              if (widget.progression.isNotEmpty)
                _TechniqueSection(
                  icon: Icons.trending_up_rounded,
                  label: 'Прогрессия',
                  text: widget.progression,
                  color: const Color(0xFF4CAF50),
                  colors: colors,
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TechniqueSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;
  final dynamic colors;

  const _TechniqueSection({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.45)),
          ]),
        ),
      ]),
    );
  }
}

class _ExerciseGifThumb extends StatelessWidget {
  final String name;
  final String? gifUrl;
  final Color accentColor;

  const _ExerciseGifThumb({
    required this.name,
    required this.gifUrl,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (gifUrl == null) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.fitness_center_rounded, color: accentColor, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: gifUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        memCacheWidth: 88,
        memCacheHeight: 88,
        placeholder: (_, __) => Container(
          width: 44, height: 44,
          color: accentColor.withValues(alpha: 0.08),
          child: Icon(Icons.fitness_center_rounded, color: accentColor.withValues(alpha: 0.4), size: 20),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fitness_center_rounded, color: accentColor, size: 20),
        ),
      ),
    );
  }
}
