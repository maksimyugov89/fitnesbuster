import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class QuickStatsCard extends StatelessWidget {
  final int heartRate;
  final double weight;
  final int streak;
  final VoidCallback onHeartRateTap;

  const QuickStatsCard({
    super.key,
    required this.heartRate,
    required this.weight,
    required this.streak,
    required this.onHeartRateTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label:
                '${l10n.heartRateLabel}: ${heartRate > 0 ? '$heartRate ${l10n.dashboardBpm}' : l10n.dashboardTapToEnter}',
            button: true,
            child: GestureDetector(
              onTap: onHeartRateTap,
              child: _StatCard(
                icon: AppImages.heartRate,
                iconColor: SemanticColors.cardioRed,
                label: l10n.heartRateLabel,
                value: heartRate > 0 ? '$heartRate' : '—',
                unit: heartRate > 0 ? l10n.dashboardBpm : '',
                subtitle: heartRate > 0
                    ? l10n.dashboardNormal
                    : l10n.dashboardTapToEnter,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: AppImages.weightTracker,
            iconColor: p.accentPurple,
            label: l10n.weightLabel,
            value: weight > 0 ? '$weight' : '—',
            unit: weight > 0 ? l10n.dashboardKg : '',
            subtitle: weight > 0 ? l10n.dashboardUpdated : l10n.dashboardNoData,
            subtitleColor: p.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: AppImages.calorieCounter,
            iconColor: p.accentOrange,
            label: l10n.dashboardStreak,
            value: '$streak',
            unit: l10n.dashboardDays,
            subtitle: streak > 0
                ? l10n.dashboardKeepGoing
                : l10n.dashboardNoData,
            subtitleColor: streak > 0 ? p.accentOrange : p.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String label, value, unit, subtitle;
  final Color? subtitleColor;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(asset: icon, glowColor: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11, color: p.textMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ),
          Text(unit, style: TextStyle(fontSize: 10, color: p.textMuted)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: subtitleColor ?? p.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
