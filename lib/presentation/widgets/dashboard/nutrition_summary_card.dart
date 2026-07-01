import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/bloc/user/user_bloc.dart';

class NutritionSummaryCard extends StatelessWidget {
  final int eatenCal;
  final int targetNutCal;
  final double caloriesBurned;

  const NutritionSummaryCard({
    super.key,
    required this.eatenCal,
    required this.targetNutCal,
    required this.caloriesBurned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    int bmr = 0;
    final userState = context.read<UserBloc>().state;
    if (userState is UserStateLoaded && userState.user.profile != null) {
      bmr = userState.user.profile!.bmr.toInt();
    }

    final target = targetNutCal.toDouble();
    final eaten = eatenCal.toDouble();
    final activity = caloriesBurned;
    final totalBurned = bmr.toDouble() + activity;
    final hasTarget = target > 0;
    final overLimit = hasTarget && eaten > target;
    final progress = hasTarget ? (eaten / target).clamp(0.0, 1.0) : 0.0;
    final deficit = (totalBurned - eaten).toInt();

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
              Text(l10n.navNutrition, style: AppTextStyles.titleM),
              const Spacer(),
              Semantics(
                label: l10n.navNutrition,
                button: true,
                child: GestureDetector(
                  onTap: () => context.push('/nutrition'),
                  child: Text(
                    l10n.openArrow,
                    style: TextStyle(
                      color: p.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CalStat(
                label: l10n.dashboardTarget,
                value: hasTarget ? '${target.toInt()}' : '—',
                color: p.textSecondary,
              ),
              const _CalDivider(),
              _CalStat(
                label: l10n.eatenLabel,
                value: '${eaten.toInt()}',
                color: overLimit ? p.error : p.accentOrange,
              ),
              const _CalDivider(),
              _CalStat(
                label: l10n.burnedLabel,
                value: totalBurned > 0 ? '${totalBurned.toInt()}' : '—',
                color: p.primary,
                subtitle: bmr > 0 ? l10n.dashboardMetabolismPlusActivity : null,
              ),
              const _CalDivider(),
              _CalStat(
                label: deficit >= 0
                    ? l10n.dashboardDeficit
                    : l10n.dashboardSurplus,
                value: totalBurned > 0 ? '${deficit.abs()}' : '—',
                color: deficit >= 0 ? p.accent : p.error,
              ),
            ],
          ),
          if (bmr > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: p.textMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.dashboardBmr('$bmr') +
                        (activity > 0
                            ? ' ${l10n.dashboardActivityPlus('${activity.toInt()}')}'
                            : ''),
                    style: TextStyle(fontSize: 10, color: p.textMuted),
                  ),
                ),
              ],
            ),
          ],
          if (hasTarget) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: p.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  overLimit ? p.error : p.accentOrange,
                ),
                minHeight: 8,
              ),
            ),
          ],
          if (overLimit) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_rounded, size: 13, color: p.error),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.dashboardCalExceeded('${(eaten - target).toInt()}'),
                    style: TextStyle(
                      fontSize: 11,
                      color: p.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (deficit > 0 && eaten > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 13,
                  color: p.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.dashboardCalDeficit('$deficit'),
                    style: TextStyle(
                      fontSize: 11,
                      color: p.primary,
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

class _CalStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final String? subtitle;
  const _CalStat({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: p.textMuted)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: TextStyle(fontSize: 8, color: p.textMuted)),
        ],
      ],
    );
  }
}

class _CalDivider extends StatelessWidget {
  const _CalDivider();
  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Container(width: 1, height: 48, color: p.surfaceLight);
  }
}
