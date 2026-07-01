import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/muscle_zone_matcher.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/presentation/widgets/workout/workout_plan_widgets.dart';
import 'package:fitnesbuster/presentation/widgets/workout/workout_exercise_card.dart';
import 'package:fitnesbuster/presentation/widgets/workout/weekly_summary_card.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class DayDetailView extends StatelessWidget {
  final dynamic colors;
  final Map<String, dynamic> day;
  final String label;
  final int selectedDay;
  final bool dateWorkoutDone;
  final bool matcherReady;
  final bool isRest;
  final void Function(
    String name,
    Set<String> primaryZones,
    Set<String> secondaryZones,
  )
  onShow3D;
  final void Function(
    String name,
    String techniqueCue,
    String progression,
    String weightGuideline,
  )
  onShowTechnique;
  final VoidCallback? onWorkoutCompleted;

  const DayDetailView({
    super.key,
    required this.colors,
    required this.day,
    required this.label,
    required this.selectedDay,
    required this.dateWorkoutDone,
    required this.matcherReady,
    required this.isRest,
    required this.onShow3D,
    required this.onShowTechnique,
    this.onWorkoutCompleted,
  });

  static String _s(dynamic v) {
    if (v is String) return v;
    if (v is List) return v.map((e) => e.toString()).join(', ');
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final focus = day['focus'] as String? ?? day['name'] as String? ?? '';
    final exercises = (day['exercises'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final cardio = (day['cardio_minutes'] as num?)?.toInt() ?? 0;
    final notes = day['notes'] as String? ?? '';
    final warmup = (day['warmup'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final cooldown = (day['cooldown'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final duration = (day['duration_minutes'] as num?)?.toInt() ?? 0;
    final estCal = (day['estimated_calories_burned'] as num?)?.toInt() ?? 0;

    final workoutDay = isRest
        ? null
        : WorkoutDay(
            day: selectedDay + 1,
            focus: focus,
            exercises: exercises
                .map((ex) => WorkoutExercise.fromJson(ex))
                .toList(),
            cardioMinutes: cardio,
            notes: notes,
          );

    final primary = <String>{};
    final secondary = <String>{};
    for (final ex in exercises) {
      final p = _s(ex['muscle_primary']).isNotEmpty
          ? _s(ex['muscle_primary'])
          : _s(ex['muscle_group']);
      final s = _s(ex['muscle_secondary']);
      if (p.isNotEmpty) primary.addAll(MuscleZoneMatcher.parse(p));
      if (s.isNotEmpty) secondary.addAll(MuscleZoneMatcher.parse(s));
    }

    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label — $focus',
                style: AppTextStyles.titleL,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (cardio > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🏃 ${l10n.minSuffix(cardio)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (duration > 0 || estCal > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (duration > 0)
                MetaChip(
                  icon: Icons.timer_outlined,
                  label: l10n.minSuffix(duration),
                  colors: colors,
                ),
              if (duration > 0 && estCal > 0) const SizedBox(width: 8),
              if (estCal > 0)
                MetaChip(
                  icon: Icons.local_fire_department_outlined,
                  label: l10n.kcalSuffix(estCal),
                  colors: colors,
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (!isRest && exercises.isNotEmpty) ...[
          _buildMusclesDayButton(context, colors, l10n, primary, secondary),
        ],
        if (!isRest) ...[
          if (dateWorkoutDone && selectedDay == todayIdx)
            _buildDoneCard(colors, l10n)
          else
            _buildStartButton(
              context,
              colors,
              l10n,
              workoutDay!,
              exercises,
              cardio,
            ),
          const SizedBox(height: 16),
        ],
        if (warmup.isNotEmpty) ...[
          WorkoutSectionList(
            title: l10n.warmupTitle,
            items: warmup,
            color: colors.accentOrange,
            colors: colors,
          ),
          const SizedBox(height: 12),
        ],
        if (isRest)
          _buildRestDayCard(colors, l10n, notes)
        else
          ...exercises.map((ex) {
            final exName = _s(ex['name']).isNotEmpty
                ? _s(ex['name'])
                : l10n.exerciseDefault;
            final techniqueCue = _s(ex['technique_cue']).isNotEmpty
                ? _s(ex['technique_cue'])
                : _s(ex['technique_tip']);
            final progression = _s(ex['progression']);
            final weightGuideline = _s(ex['weight_guideline']);
            final musclePrimary = _s(ex['muscle_primary']).isNotEmpty
                ? _s(ex['muscle_primary'])
                : _s(ex['muscle_group']);
            final muscleSecondary = _s(ex['muscle_secondary']);
            final primaryZones = musclePrimary.isNotEmpty
                ? MuscleZoneMatcher.parse(musclePrimary)
                : <String>{};
            final secondaryZones = muscleSecondary.isNotEmpty
                ? MuscleZoneMatcher.parse(muscleSecondary)
                : <String>{};
            return WorkoutExerciseCard(
              exercise: ex,
              colors: colors,
              matcherReady: matcherReady,
              onShow3D: () => onShow3D(exName, primaryZones, secondaryZones),
              onShowTechnique: () => onShowTechnique(
                exName,
                techniqueCue,
                progression,
                weightGuideline,
              ),
              showTechnique: techniqueCue.isNotEmpty || progression.isNotEmpty,
            );
          }),
        if (cooldown.isNotEmpty && !isRest) ...[
          const SizedBox(height: 12),
          WorkoutSectionList(
            title: l10n.cooldownTitle,
            items: cooldown,
            color: colors.info,
            colors: colors,
          ),
        ],
        if (notes.isNotEmpty && !isRest) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.info.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: colors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMusclesDayButton(
    BuildContext context,
    dynamic colors,
    _,
    Set<String> primary,
    Set<String> secondary,
  ) {
    if (primary.isEmpty && secondary.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: context.l10n.musclesWorkoutTitle,
      button: true,
      child: GestureDetector(
        onTap: () =>
            onShow3D(context.l10n.musclesWorkoutTitle, primary, secondary),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.view_in_ar_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.musclesWorkoutTitle,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      context.l10n.view3D,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5C8AFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C9A7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoneCard(dynamic colors, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: colors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workoutDoneStatus,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.success,
                  ),
                ),
                Text(
                  l10n.workoutDoneSubtitleNext,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.success.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events_rounded,
            color: colors.success.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    dynamic colors,
    AppLocalizations l10n,
    WorkoutDay workoutDay,
    List<Map<String, dynamic>> exercises,
    int cardio,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.75)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Semantics(
        label: l10n.startWorkoutBtn,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await context.push(AppRouter.workoutExecution, extra: workoutDay);
              if (!context.mounted) return;
              bool done = false;
              try {
                done = await sl<ISettingsRepository>().getWorkoutDone(
                  todayKey(),
                );
              } catch (_) {}
              if (done) onWorkoutCompleted?.call();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.startWorkoutBtn,
                          style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          cardio > 0
                              ? l10n.startWorkoutWithCardio(
                                  exercises.length,
                                  workoutDay.totalSets,
                                  cardio,
                                )
                              : l10n.startWorkoutDetails(
                                  exercises.length,
                                  workoutDay.totalSets,
                                ),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayCard(
    dynamic colors,
    AppLocalizations l10n,
    String notes,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Text('😴', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.restDayTitle,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notes.isNotEmpty ? notes : l10n.restDayNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
