import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

class StreakCard extends StatelessWidget {
  final UserLevel level;
  const StreakCard({super.key, required this.level});

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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Image.asset(lvl.icon, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${AppLocalizations.of(context).levelLabel} '
                      '${lvl.level} · '
                      '${GamificationService.localizedLevelName(lvl.level)}',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      lvl.isMaxLevel
                          ? '${lvl.totalXp} XP'
                          : '${lvl.xpInCurrentLevel} / ${lvl.xpNeededForNext} XP',
                      style: TextStyle(fontSize: 10, color: p.textMuted),
                    ),
                  ],
                ),
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: AppLocalizations.of(context).achievementsTitle,
            button: true,
            child: GestureDetector(
              onTap: () => context.push('/achievements'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  AppImages.achievements,
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodaysWorkoutCard extends StatelessWidget {
  final List<bool> weekWorkouts;
  final int workoutKcalToday;
  final Animation<double> animation;
  final bool testWeekCheckDone;
  final bool testWeekCompleted;
  final String? workoutPlanJson;
  final String? mealPlanJson;

  const TodaysWorkoutCard({
    super.key,
    required this.weekWorkouts,
    required this.workoutKcalToday,
    required this.animation,
    required this.testWeekCheckDone,
    required this.testWeekCompleted,
    this.workoutPlanJson,
    this.mealPlanJson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WeeklyChart(
          weekWorkouts: weekWorkouts,
          workoutKcalToday: workoutKcalToday,
          animation: animation,
        ),
        if (testWeekCheckDone && !testWeekCompleted) ...[
          const SizedBox(height: 24),
          const _TestWeekBanner(),
        ],
        if (workoutPlanJson != null || mealPlanJson != null) ...[
          const SizedBox(height: 24),
          _AiPlans(
            workoutPlanJson: workoutPlanJson,
            mealPlanJson: mealPlanJson,
          ),
        ],
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<bool> weekWorkouts;
  final int workoutKcalToday;
  final Animation<double> animation;

  const _WeeklyChart({
    required this.weekWorkouts,
    required this.workoutKcalToday,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    final days = [
      l10n.monShort,
      l10n.tueShort,
      l10n.wedShort,
      l10n.thuShort,
      l10n.friShort,
      l10n.satShort,
      l10n.sunShort,
    ];
    final todayIndex = DateTime.now().weekday - 1;
    final doneCount = weekWorkouts.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(l10n.weekLabel, style: AppTextStyles.titleM),
              const Spacer(),
              Text(
                l10n.workoutsWeekCount(doneCount),
                style: TextStyle(
                  fontSize: 12,
                  color: doneCount > 0 ? p.primary : p.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: p.primary,
                              ),
                            ),
                          AnimatedBuilder(
                            animation: animation,
                            builder: (_, _) => AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: done
                                  ? (38 * animation.value).clamp(8, 38)
                                  : (isToday ? 8 : 4),
                              decoration: BoxDecoration(
                                gradient: done
                                    ? (isToday
                                          ? p.primaryGradient
                                          : const LinearGradient(
                                              colors: [
                                                SemanticColors.progression,
                                                Color(0xFF66BB6A),
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ))
                                    : null,
                                color: done
                                    ? null
                                    : (isToday
                                          ? p.primary.withValues(alpha: 0.3)
                                          : p.surfaceLight),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday
                                  ? p.primary
                                  : done
                                  ? p.textSecondary
                                  : p.textMuted,
                              fontWeight: (isToday || done)
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 13,
                  color: p.accentOrange,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${l10n.today} ${l10n.workoutCalBurned}: $workoutKcalToday ${l10n.kcalShort}',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TestWeekBanner extends StatelessWidget {
  const _TestWeekBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    return Semantics(
      label: l10n.testWeekTitle,
      button: true,
      child: GestureDetector(
        onTap: () => context.push('/test-week'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SemanticColors.cardDark, SemanticColors.cardDarker],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: p.info.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: p.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Image.asset(AppImages.target, width: 30, height: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.testWeekTitle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.info,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(context).dashboardStartProgram,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.testWeekSubtitle,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: _InfoPill(
                            l10n.dashboardIndividualLabel,
                            SemanticColors.featurePill,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: _InfoPill(
                            l10n.dashboardYourSchedule,
                            SemanticColors.featurePill,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: _InfoPill(
                            AppLocalizations.tl('dashboardAtYourPace'),
                            SemanticColors.featurePill,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, color: p.info, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiPlans extends StatelessWidget {
  final String? workoutPlanJson;
  final String? mealPlanJson;
  const _AiPlans({this.workoutPlanJson, this.mealPlanJson});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.aiPlanSection, style: AppTextStyles.titleM),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: p.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.workoutPlanTitle,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: l10n.openArrow,
                      button: true,
                      child: GestureDetector(
                        onTap: () => context.push('/workout'),
                        child: Text(
                          l10n.openArrow,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: l10n.startTodayBtn,
                  button: true,
                  child: GestureDetector(
                    onTap: () => context.push('/workout/session/today'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            p.primary,
                            p.primary.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: p.textOnPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.startTodayBtn,
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: p.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: p.accentOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.mealPlanLabel,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: l10n.openArrow,
                  button: true,
                  child: GestureDetector(
                    onTap: () => context.push('/nutrition/meal-plan'),
                    child: Text(
                      l10n.openArrow,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _InfoPill extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoPill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
