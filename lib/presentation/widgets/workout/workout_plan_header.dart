import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class WorkoutPlanHeader extends StatelessWidget {
  final dynamic colors;
  final VoidCallback onOpenImport;

  const WorkoutPlanHeader({
    super.key,
    required this.colors,
    required this.onOpenImport,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Semantics(
              label: l10n.prTitle,
              button: true,
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
                  Text(l10n.prTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
                ]),
              ),
            ),
          ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: l10n.calendarBtn,
              button: true,
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
                  Text(l10n.calendarBtn, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.accentPurple)),
                ]),
              ),
            ),
          ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(l10n.workoutsTitle, style: AppTextStyles.displayM),
              ),
              Text(l10n.aiPlanSubtitle, style: TextStyle(fontSize: 13, color: colors.textMuted)),
            ]),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: l10n.baseShort,
            button: true,
            child: GestureDetector(
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
                  Text(l10n.baseShort, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.accent)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: l10n.aiCorrShort,
            button: true,
            child: GestureDetector(
              onTap: onOpenImport,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_fix_high_rounded, color: colors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(l10n.aiCorrShort, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.primary)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
