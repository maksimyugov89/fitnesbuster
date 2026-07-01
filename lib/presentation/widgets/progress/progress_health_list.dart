import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/progress/progress_cards.dart';

class ProgressHealthList extends StatelessWidget {
  final int? heartRateAvg;
  final int? restingHeartRate;
  final double? heartRateVariability;
  final double? respiratoryRate;
  final int steps;
  final int? sleepMinutes;
  final double? waterIntakeMl;
  final bool healthLoaded;

  const ProgressHealthList({
    super.key,
    required this.heartRateAvg,
    required this.restingHeartRate,
    required this.heartRateVariability,
    required this.respiratoryRate,
    required this.steps,
    required this.sleepMinutes,
    required this.waterIntakeMl,
    required this.healthLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sleepHours = sleepMinutes != null && sleepMinutes! > 0
        ? (sleepMinutes! / 60.0).toStringAsFixed(1)
        : '\u2014';
    final hasData =
        healthLoaded &&
        (heartRateAvg != null || steps > 0 || sleepMinutes != null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      children: [
        HealthCard(
          label: context.l10n.avgHeartRateLabel,
          value: heartRateAvg != null ? '$heartRateAvg' : '\u2014',
          unit: context.l10n.bpmUnit,
          icon: Icons.favorite_rounded,
          color: colors.error,
          trend: heartRateAvg != null ? context.l10n.normalBadge : '',
          positive: true,
        ),
        const SizedBox(height: 12),
        HealthCard(
          label: context.l10n.restingHrLabel,
          value: restingHeartRate != null ? '$restingHeartRate' : '\u2014',
          unit: context.l10n.bpmUnit,
          icon: Icons.monitor_heart_outlined,
          color: colors.accentPurple,
          trend: restingHeartRate != null
              ? (restingHeartRate! <= 60
                    ? AppLocalizations.tl('excellent')
                    : restingHeartRate! <= 80
                    ? context.l10n.normalBadge
                    : AppLocalizations.tl('highLabel'))
              : '',
          positive: restingHeartRate != null && restingHeartRate! <= 80,
        ),
        const SizedBox(height: 12),
        HealthCard(
          label: context.l10n.hrvLabel,
          value: heartRateVariability != null
              ? heartRateVariability!.toStringAsFixed(1)
              : '\u2014',
          unit: context.l10n.msUnit,
          icon: Icons.show_chart_rounded,
          color: colors.accent,
          trend: heartRateVariability != null
              ? (heartRateVariability! >= 40
                    ? AppLocalizations.tl('good')
                    : AppLocalizations.tl('low'))
              : '',
          positive: heartRateVariability != null && heartRateVariability! >= 40,
        ),
        const SizedBox(height: 12),
        HealthCard(
          label: context.l10n.respiratoryRateLabel,
          value: respiratoryRate != null
              ? respiratoryRate!.toStringAsFixed(1)
              : '\u2014',
          unit: context.l10n.bpmRespUnit,
          icon: Icons.air_rounded,
          color: colors.info,
          trend: respiratoryRate != null
              ? (respiratoryRate! <= 20
                    ? context.l10n.normalBadge
                    : AppLocalizations.tl('highLabel'))
              : '',
          positive: respiratoryRate != null && respiratoryRate! <= 20,
        ),
        const SizedBox(height: 12),
        HealthCard(
          label: context.l10n.stepsTodayLabel,
          value: steps > 0 ? '$steps' : '\u2014',
          unit: context.l10n.stepsUnit,
          icon: Icons.directions_walk_rounded,
          color: colors.primary,
          trend: steps >= 10000
              ? AppLocalizations.tl('goalReached')
              : steps > 0
              ? '-${10000 - steps}'
              : '',
          positive: steps >= 10000,
        ),
        const SizedBox(height: 12),
        HealthCard(
          label: context.l10n.sleepLabel2,
          value: sleepHours,
          unit: context.l10n.hoursNightUnit,
          icon: Icons.bedtime_outlined,
          color: colors.accentPurple,
          trend: (sleepMinutes ?? 0) >= 420 ? context.l10n.normalBadge : '',
          positive: (sleepMinutes ?? 0) >= 420,
        ),
        const SizedBox(height: 12),
        HealthCard(
          label: context.l10n.waterHealthLabel,
          value: (waterIntakeMl ?? 0) > 0
              ? '${waterIntakeMl!.toInt()}'
              : '\u2014',
          unit: context.l10n.mlHealthUnit,
          icon: Icons.water_drop_rounded,
          color: colors.info,
          trend: (waterIntakeMl ?? 0) >= 2000 ? context.l10n.normalBadge : '',
          positive: (waterIntakeMl ?? 0) >= 2000,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.info.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\u{1F916} ${context.l10n.aiAdviceLabel}',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasData
                    ? _buildAiAdvice()
                    : AppLocalizations.tl('syncHealthConnectForAi'),
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildAiAdvice() {
    final parts = <String>[];
    if (steps > 0) {
      final estKcal = (steps * 0.04).toInt();
      parts.add(
        AppLocalizations.tlp('stepsTaken', {
          'steps': '$steps',
          'kcal': '$estKcal',
        }),
      );
      if (steps < 7000) {
        parts.add(
          AppLocalizations.tlp('stepsNeedMore', {
            'remaining': '${7000 - steps}',
          }),
        );
      } else {
        parts.add(AppLocalizations.tl('stepsGood'));
      }
    }
    if (heartRateAvg != null && heartRateAvg! > 80) {
      parts.add(
        AppLocalizations.tlp('heartRateElevated', {'bpm': '$heartRateAvg'}),
      );
    }
    if (sleepMinutes != null && sleepMinutes! > 0 && sleepMinutes! < 420) {
      parts.add(
        AppLocalizations.tlp('sleepLow', {
          'hours': (sleepMinutes! / 60).toStringAsFixed(1),
        }),
      );
    }
    return parts.isEmpty ? AppLocalizations.tl('dataSynced') : parts.join(' ');
  }
}
