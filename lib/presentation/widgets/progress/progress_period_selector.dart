import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

enum StatPeriod { today, week, month, year }

class ProgressPeriodSelector extends StatelessWidget {
  final StatPeriod selectedPeriod;
  final ValueChanged<StatPeriod> onChanged;
  const ProgressPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: StatPeriod.values.map((p) {
          final sel = p == selectedPeriod;
          final label = switch (p) {
            StatPeriod.today => context.l10n.periodTodayLabel,
            StatPeriod.week => context.l10n.periodWeekLabel,
            StatPeriod.month => context.l10n.periodMonthLabel,
            StatPeriod.year => context.l10n.periodYearLabel,
          };
          return Expanded(
            child: Semantics(
              label: label,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? colors.textOnPrimary : colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
