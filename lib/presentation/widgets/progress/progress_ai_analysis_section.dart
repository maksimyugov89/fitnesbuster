import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class ProgressAiAnalysisSection extends StatelessWidget {
  final String? aiAnalysis;
  final bool aiAnalyzing;
  final int measurementsCount;
  final bool hasPhotos;
  final VoidCallback onAnalyze;
  const ProgressAiAnalysisSection({
    super.key,
    required this.aiAnalysis,
    required this.aiAnalyzing,
    required this.measurementsCount,
    required this.hasPhotos,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.info.withValues(alpha: 0.12),
            colors.accentPurple.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.info.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.aiProgressTitle,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!aiAnalyzing)
                Semantics(
                  label: aiAnalysis != null
                      ? context.l10n.updateBtn
                      : context.l10n.analyzeBtn,
                  button: true,
                  child: GestureDetector(
                    onTap: onAnalyze,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        aiAnalysis != null
                            ? context.l10n.updateBtn
                            : context.l10n.analyzeBtn,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (aiAnalysis != null) ...[
            Text(
              aiAnalysis!,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
          ] else ...[
            Text(
              context.l10n.aiAnalysisHintText(
                measurementsCount,
                hasPhotos ? context.l10n.photoProgressTitle2 : '',
              ),
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
