import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class AiChatCard extends StatelessWidget {
  const AiChatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    return Semantics(
      label: l10n.askAiLabel,
      button: true,
      child: GestureDetector(
        onTap: () => context.push('/chat'),
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              p.primary.withValues(alpha: 0.12),
              p.accent.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.primary.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primary, p.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('AI', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.askAiLabel, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: p.textPrimary)),
              const SizedBox(height: 4),
              Text(l10n.askAiSubtitle, style: TextStyle(fontSize: 12, color: p.textSecondary)),
            ]),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: p.primary, size: 16),
        ]),
      ),
    ),
  );
  }
}
