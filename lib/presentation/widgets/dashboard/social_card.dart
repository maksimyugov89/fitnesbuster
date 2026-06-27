import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/router/app_router.dart';

class SocialCard extends StatelessWidget {
  final int pendingRequests;
  const SocialCard({super.key, required this.pendingRequests});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.socialSection, style: AppTextStyles.titleM),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _SocialBtn(emoji: '👥', label: l10n.feedTitle, onTap: () => context.push(AppRouter.feed))),
          const SizedBox(width: 10),
          Expanded(child: _SocialBtn(emoji: '🤝', label: l10n.friendsTitle, badge: pendingRequests, onTap: () => context.push(AppRouter.friends))),
          const SizedBox(width: 10),
          Expanded(child: _SocialBtn(emoji: '⚡', label: l10n.challengesTitle, onTap: () => context.push(AppRouter.challenges))),
        ]),
      ]),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String emoji, label;
  final int? badge;
  final VoidCallback onTap;
  const _SocialBtn({required this.emoji, required this.label, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: p.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            if (badge != null && badge! > 0)
              Positioned(
                right: -12, top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
