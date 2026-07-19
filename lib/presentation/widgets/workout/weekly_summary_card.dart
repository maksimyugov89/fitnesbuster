import 'package:flutter/material.dart';
import 'package:fitnesbuster/data/models/workout_day.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class WorkoutWeekSummary extends StatelessWidget {
  final WorkoutPlanMeta meta;
  final dynamic colors;
  const WorkoutWeekSummary({
    super.key,
    required this.meta,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Image.asset(AppImages.progressTab, width: 26, height: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.tlp('weekNumShort', {'n': '${meta.weekNumber}'})}${meta.phase.isNotEmpty ? " · ${meta.phase}" : ""}',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if (meta.weeklySummary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta.weeklySummary,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (meta.weeklyVolumeSets > 0)
            Column(
              children: [
                Text(
                  '${meta.weeklyVolumeSets}',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
                Text(
                  AppLocalizations.tl('setsShort'),
                  style: TextStyle(fontSize: 9, color: colors.textMuted),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class WorkoutSectionList extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final dynamic colors;
  const WorkoutSectionList({
    super.key,
    required this.title,
    required this.items,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
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
          ),
        ],
      ),
    );
  }
}
