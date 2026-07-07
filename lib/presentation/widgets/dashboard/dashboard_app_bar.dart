import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/constants/avatar_presets.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final int avatarPresetIndex;
  final String avatarCustomPath;
  final AnimationController headerCtrl;
  final ValueNotifier<bool>? initNotifier;

  const DashboardAppBar({
    super.key,
    required this.userName,
    required this.avatarPresetIndex,
    required this.avatarCustomPath,
    required this.headerCtrl,
    this.initNotifier,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final displayName = userName.isNotEmpty
        ? userName
        : AppLocalizations.of(context).dashboardDefaultName;
    final firstName = displayName.split(' ').first;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      pinned: false,
      elevation: 0,
      expandedHeight: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: p.background),
      ),
      title: FadeTransition(
        opacity: headerCtrl,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.greetingMorning,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    firstName,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Semantics(
              label: context.l10n.editProfileLabel,
              button: true,
              child: GestureDetector(
                onTap: () => context.go('/profile'),
                child: _buildAvatar(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final p = AppTheme.of(context);
    const size = 42.0;

    if (avatarCustomPath.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.primary.withValues(alpha: 0.5), width: 2),
        ),
        child: ClipOval(
          child: Image.file(
            File(avatarCustomPath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildInitialsAvatar(context, size),
          ),
        ),
      );
    }

    if (avatarPresetIndex >= 0 && avatarPresetIndex < kAvatarPresets.length) {
      final preset = kAvatarPresets[avatarPresetIndex];
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: preset.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: preset.gradientColors[0].withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Center(
          child: Image.asset(
            preset.iconAsset,
            width: size * 0.62,
            height: size * 0.62,
          ),
        ),
      );
    }

    return _buildInitialsAvatar(context, size);
  }

  Widget _buildInitialsAvatar(BuildContext context, double size) {
    final p = AppTheme.of(context);
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.primary, p.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.textOnPrimary,
          ),
        ),
      ),
    );
  }
}
