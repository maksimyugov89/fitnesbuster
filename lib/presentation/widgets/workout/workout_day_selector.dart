import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class WorkoutDaySelector extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int selectedDay;
  final int todayIdx;
  final ValueChanged<int> onDaySelected;
  final dynamic colors;
  final String Function(Map<String, dynamic>) dayIcon;
  final List<String> Function(AppLocalizations) weekLabels;

  const WorkoutDaySelector({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.todayIdx,
    required this.onDaySelected,
    required this.colors,
    required this.dayIcon,
    required this.weekLabels,
  });

  @override
  Widget build(BuildContext context) {
    final count = days.length.clamp(0, 7);
    final labels = weekLabels(context.l10n);

    return SizedBox(
      height: 84,
      child: Row(
        children: List.generate(count, (i) {
          final day = days[i];
          final isSelected = i == selectedDay;
          final isToday = i == todayIdx;
          return Expanded(
            child: Semantics(
              label: labels[i],
              button: true,
              child: GestureDetector(
                onTap: () => onDaySelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : isToday
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : isToday
                          ? colors.primary.withValues(alpha: 0.4)
                          : colors.textPrimary.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? colors.textOnPrimary
                              : colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 24,
                        child: Image.asset(
                          dayIcon(day),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
