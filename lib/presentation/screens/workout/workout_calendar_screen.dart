import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

// ── Scheduled event stored per date ─────────────────────────────────────────

class _WorkoutEvent {
  final int planDayIndex; // 0-6 in the AI plan
  final String focus;
  final bool isRest;
  _WorkoutEvent({
    required this.planDayIndex,
    required this.focus,
    required this.isRest,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class WorkoutCalendarScreen extends StatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _planDays = []; // raw plan from AI

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // dateKey (yyyy-MM-dd) → planDayIndex override
  Map<String, int> _overrides = {};

  List<String> get _weekLabels => [
    AppLocalizations.tl('monShort'),
    AppLocalizations.tl('tueShort'),
    AppLocalizations.tl('wedShort'),
    AppLocalizations.tl('thuShort'),
    AppLocalizations.tl('friShort'),
    AppLocalizations.tl('satShort'),
    AppLocalizations.tl('sunShort'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadPlan(), _loadOverrides()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPlan() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthStateAuthenticated) return;
      final uid = authState.userId;
      final plans = await sl<IUserRepository>().getAiPlans(uid);
      final jsonStr = plans['workoutPlan'];
      if (jsonStr == null) return;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final raw = data['plan'] as List? ?? [];
      final days = raw
          .whereType<Map<String, dynamic>>()
          .toList()
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() => _planDays = days);
    } catch (e, st) {
      appLogger.w('WorkoutCalendar: load plan days', error: e, stackTrace: st);
    }
  }

  Future<void> _loadOverrides() async {
    final raw = await sl<ISettingsRepository>().getCalendarOverrides();
    if (raw != null) {
      final map = (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
      if (mounted) setState(() => _overrides = map);
    }
  }

  Future<void> _saveOverrides() async {
    await sl<ISettingsRepository>().setCalendarOverrides(
      jsonEncode(_overrides),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Default assignment: weekday 1=Mon → plan day 0, etc.
  int _defaultPlanIndex(DateTime date) =>
      (date.weekday - 1) % _planDays.length.clamp(1, 7);

  Map<String, dynamic>? _planDayFor(DateTime date) {
    if (_planDays.isEmpty) return null;
    final k = _dateKey(date);
    final idx = _overrides[k] ?? _defaultPlanIndex(date);
    return _planDays[idx.clamp(0, _planDays.length - 1)];
  }

  bool _isRest(Map<String, dynamic>? day) {
    if (day == null) return true;
    final exercises = day['exercises'] as List? ?? [];
    final focus = (day['focus'] as String? ?? day['name'] as String? ?? '')
        .toLowerCase();
    final type = (day['type'] as String? ?? '').toLowerCase();
    return exercises.isEmpty ||
        focus.contains('отдых') ||
        focus.contains('восстановлен') ||
        focus.contains('rest') ||
        focus.contains('recovery') ||
        type == 'rest' ||
        type == 'active_recovery';
  }

  String _dayIcon(Map<String, dynamic>? day) {
    if (day == null || _isRest(day)) return AppImages.sleep;
    final focus = (day['focus'] as String? ?? day['name'] as String? ?? '')
        .toLowerCase();
    if (focus.contains('кардио') ||
        focus.contains('интервал') ||
        focus.contains('cardio') ||
        focus.contains('interval')) {
      return AppImages.running;
    }
    if (focus.contains('нога') ||
        focus.contains('ягодиц') ||
        focus.contains('leg') ||
        focus.contains('glute')) {
      return AppImages.legDay;
    }
    if (focus.contains('грудн') ||
        focus.contains('трицепс') ||
        focus.contains('chest') ||
        focus.contains('triceps')) {
      return AppImages.workoutsTab;
    }
    if (focus.contains('спина') ||
        focus.contains('бицепс') ||
        focus.contains('back') ||
        focus.contains('biceps')) {
      return AppImages.workoutsTab;
    }
    if (focus.contains('плечи') ||
        focus.contains('пресс') ||
        focus.contains('shoulder') ||
        focus.contains('abs') ||
        focus.contains('core')) {
      return AppImages.energy;
    }
    return AppImages.workoutsTab;
  }

  List<_WorkoutEvent> _eventsFor(DateTime day) {
    final planDay = _planDayFor(day);
    if (planDay == null) return [];
    final k = _dateKey(day);
    final idx = _overrides[k] ?? _defaultPlanIndex(day);
    return [
      _WorkoutEvent(
        planDayIndex: idx,
        focus: planDay['focus'] as String? ?? planDay['name'] as String? ?? '',
        isRest: _isRest(planDay),
      ),
    ];
  }

  // Shows bottom sheet to reassign a day to any plan day
  void _onDayTapped(DateTime date) {
    setState(() => _selectedDay = date);
    if (_planDays.isEmpty) return;
    _showReassignSheet(date);
  }

  void _showReassignSheet(DateTime date) {
    final colors = AppTheme.of(context);
    final k = _dateKey(date);
    final currentIdx = _overrides[k] ?? _defaultPlanIndex(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          int selected = currentIdx;
          return Container(
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Image.asset(AppImages.calendar, width: 26, height: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocalizations.tlp('assignWorkoutForDate', {
                            'date':
                                '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                          }),
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                ...List.generate(_planDays.length, (i) {
                  final d = _planDays[i];
                  final focus =
                      d['focus'] as String? ?? d['name'] as String? ?? '';
                  final label = i < _weekLabels.length
                      ? _weekLabels[i]
                      : AppLocalizations.tlp('dayLabel', {'n': '${i + 1}'});
                  final isSelected = selected == i;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selected = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Image.asset(_dayIcon(d), width: 24, height: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                ),
                                Text(
                                  focus.isEmpty
                                      ? AppLocalizations.tl('restRecoveryLabel')
                                      : focus,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: colors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Row(
                    children: [
                      if (_overrides.containsKey(k))
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _overrides.remove(k));
                              _saveOverrides();
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: colors.textMuted.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.tl('reset'),
                              style: TextStyle(color: colors.textMuted),
                            ),
                          ),
                        ),
                      if (_overrides.containsKey(k)) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _overrides[k] = selected);
                            _saveOverrides();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.textOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            AppLocalizations.tl('save'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.tl('workoutSchedule'),
          style: AppTextStyles.titleL,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _planDays.isEmpty
          ? _buildEmpty(colors)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              children: [
                _buildCalendar(colors, now),
                const SizedBox(height: 20),
                if (_selectedDay != null)
                  _buildSelectedDayCard(colors, _selectedDay!),
                const SizedBox(height: 20),
                _buildUpcomingWorkouts(colors, now),
              ],
            ),
    );
  }

  Widget _buildEmpty(ThemePalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppImages.calendar, width: 64, height: 64),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.tl('noWorkoutPlan'),
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.tl('generatePlanHint'),
              style: TextStyle(fontSize: 13, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemePalette colors, DateTime now) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TableCalendar(
        locale: localeTag,
        firstDay: now.subtract(const Duration(days: 7)),
        lastDay: now.add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: {
          CalendarFormat.month: AppLocalizations.tl('month'),
        },
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        onDaySelected: (selected, focused) {
          setState(() => _focusedDay = focused);
          _onDayTapped(selected);
        },
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
        eventLoader: _eventsFor,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Syne',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: colors.textMuted,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: colors.textMuted,
          ),
          decoration: const BoxDecoration(color: Colors.transparent),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            color: colors.textMuted.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
          ),
          weekendTextStyle: TextStyle(color: colors.textMuted, fontSize: 13),
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          selectedDecoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: colors.textOnPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          markerDecoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          markersMaxCount: 1,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (ctx, date, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final ev = events.first as _WorkoutEvent;
            if (ev.isRest) return const SizedBox.shrink(); // no marker for rest
            return Positioned(
              bottom: 2,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayCard(ThemePalette colors, DateTime date) {
    final planDay = _planDayFor(date);
    final focus =
        planDay?['focus'] as String? ?? planDay?['name'] as String? ?? '';
    final isRest = _isRest(planDay);
    final icon = _dayIcon(planDay);
    final exercises = (planDay?['exercises'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final k = _dateKey(date);
    final isOverridden = _overrides.containsKey(k);
    final isToday = isSameDay(date, DateTime.now());

    final workoutDay = isRest || exercises.isEmpty
        ? null
        : WorkoutDay(
            day: (date.weekday),
            focus: focus,
            exercises: exercises
                .map((ex) => WorkoutExercise.fromJson(ex))
                .toList(),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${date.day}.${date.month.toString().padLeft(2, '0')}${isToday ? ' — ${AppLocalizations.tl('today')}' : ''}',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            if (isOverridden) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.tl('moved'),
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.accentOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(icon, width: 32, height: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRest
                              ? AppLocalizations.tl('restRecoveryLabel')
                              : focus,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (!isRest)
                          Text(
                            AppLocalizations.tlp('exercisesShortCount', {
                              'n': '${exercises.length}',
                            }),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showReassignSheet(date),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_calendar_rounded,
                            size: 14,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.tl('edit'),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (workoutDay != null) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.push(
                    AppRouter.workoutExecution,
                    extra: workoutDay,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.tl('startWorkoutBtn'),
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: colors.textOnPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingWorkouts(ThemePalette colors, DateTime now) {
    // Next 7 days
    final upcomingDays = List.generate(
      7,
      (i) => now.add(Duration(days: i + 1)),
    );
    final workoutDays = upcomingDays
        .where((d) {
          final planDay = _planDayFor(d);
          return !_isRest(planDay);
        })
        .take(5)
        .toList();

    if (workoutDays.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.tl('nearestWorkouts'),
          style: AppTextStyles.titleM,
        ),
        const SizedBox(height: 12),
        ...workoutDays.map((date) {
          final planDay = _planDayFor(date);
          final focus =
              planDay?['focus'] as String? ?? planDay?['name'] as String? ?? '';
          final icon = _dayIcon(planDay);
          final k = _dateKey(date);
          final isOverridden = _overrides.containsKey(k);
          final weekday = _weekLabels[date.weekday - 1];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Image.asset(icon, width: 24, height: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$weekday, ${date.day}.${date.month.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                          if (isOverridden) ...[
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.tl('moved').toLowerCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.accentOrange,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        focus,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedDay = date);
                    _showReassignSheet(date);
                  },
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
