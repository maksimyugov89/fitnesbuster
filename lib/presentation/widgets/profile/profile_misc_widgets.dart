import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const LogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Semantics(
      label: AppLocalizations.tl('logoutBtn'),
      button: true,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.logout_rounded, color: colors.textMuted, size: 18),
        label: Text(
          AppLocalizations.tl('logoutBtn'),
          style: TextStyle(color: colors.textMuted),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.surfaceLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

class DeleteAccountButton extends StatelessWidget {
  final VoidCallback onTap;
  const DeleteAccountButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Semantics(
      label: AppLocalizations.tl('deleteAccountBtn'),
      button: true,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.delete_forever_rounded, color: colors.error, size: 16),
        label: Text(
          AppLocalizations.tl('deleteAccountBtn'),
          style: TextStyle(color: colors.error, fontSize: 13),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class StatBox extends StatelessWidget {
  final String number, unit, label;
  final Color color;
  const StatBox({
    super.key,
    required this.number,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.surfaceLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textMuted),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AiProgressDialog extends StatelessWidget {
  const AiProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.generatingPlan,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.tl('deepSeekRecalculating'),
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
