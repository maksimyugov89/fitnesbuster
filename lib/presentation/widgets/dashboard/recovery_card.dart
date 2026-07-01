import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/services/recovery_score_service.dart';

class RecoveryCard extends StatelessWidget {
  final RecoveryScore recoveryScore;
  const RecoveryCard({super.key, required this.recoveryScore});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    final r = recoveryScore;
    final color = r.color;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.recoveryTitle, style: AppTextStyles.titleM),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: r.score / 100,
                        strokeWidth: 9,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${r.score}',
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: color,
                                height: 1.0,
                              ),
                            ),
                          ),
                          Text(
                            '%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.75),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.advice,
                      style: TextStyle(
                        fontSize: 13,
                        color: p.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: _RecoveryStat(
                            icon: '😴',
                            label: l10n.sleepLabel,
                            value: RecoveryScoreService.formatSleep(
                              r.sleepMinutes,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: _RecoveryStat(
                            icon: '💓',
                            label: 'HRV',
                            value: r.hrv != null
                                ? '${r.hrv!.toStringAsFixed(0)} ms'
                                : '—',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: _RecoveryStat(
                            icon: '❤️',
                            label: l10n.heartRateLabel,
                            value: r.restingHr != null
                                ? '${r.restingHr} ${l10n.dashboardBpm}'
                                : '—',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdaptationBanner extends StatelessWidget {
  final RecoveryScore recoveryScore;
  const AdaptationBanner({super.key, required this.recoveryScore});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final r = recoveryScore;
    final isLow = r.level == RecoveryLevel.low;
    final bannerColor = isLow ? p.error : p.accentOrange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                isLow ? '😴' : '⚡',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLow
                      ? AppLocalizations.of(context).recoveryAiRest
                      : AppLocalizations.of(context).recoveryAiReduce,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLow
                      ? AppLocalizations.of(context).recoveryLowMsg2
                      : AppLocalizations.of(context).recoveryHRVLowMsg2,
                  style: TextStyle(
                    fontSize: 11,
                    color: p.textSecondary,
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

class _RecoveryStat extends StatelessWidget {
  final String icon, label, value;
  const _RecoveryStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$icon $label', style: TextStyle(fontSize: 9, color: p.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }
}
