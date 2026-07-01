import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/di/injection.dart' show sl;
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldown = Duration(seconds: 60);
  static const _autoPollInterval = Duration(seconds: 4);

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _checking = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _pollTimer = Timer.periodic(_autoPollInterval, (_) => _checkVerified());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _checkVerified({bool showFeedback = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    context.read<AuthBloc>().add(const AuthEmailVerificationChecked());
    // Give the bloc a tick to reload from Firebase and emit the new state.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _checking = false);
    final state = context.read<AuthBloc>().state;
    final verified = state is AuthStateAuthenticated && state.emailVerified;
    if (showFeedback && !verified) {
      _showSnack(context.l10n.verifyEmailNotYetSnackbar);
    }
  }

  Future<void> _resend() async {
    if (_resending || _cooldownSeconds > 0) return;
    setState(() => _resending = true);
    try {
      await sl<IAuthRepository>().sendEmailVerification();
      if (!mounted) return;
      _showSnack(context.l10n.verifyEmailSentSnackbar);
      _startCooldown();
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppLocalizations.tl('genericError'));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showSnack(String message) {
    final colors = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.082),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_rounded,
                        color: colors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.verifyEmailTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayL,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.verifyEmailSubtitle(email),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyL.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _checking
                          ? null
                          : () => _checkVerified(showFeedback: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _checking
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colors.textOnPrimary,
                              ),
                            )
                          : Text(
                              l10n.verifyEmailCheckBtn,
                              style: const TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: (_resending || _cooldownSeconds > 0)
                        ? null
                        : _resend,
                    child: Text(
                      _cooldownSeconds > 0
                          ? l10n.verifyEmailResendCooldown(
                              _cooldownSeconds.toString(),
                            )
                          : l10n.verifyEmailResendBtn,
                      style: TextStyle(
                        color: _cooldownSeconds > 0
                            ? colors.textMuted
                            : colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthLogoutRequested(),
                    ),
                    child: Text(
                      l10n.verifyEmailLogoutBtn,
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
