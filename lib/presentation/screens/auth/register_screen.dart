import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/localization/language_service.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/legal/legal_consent.dart';
import 'package:fitnesbuster/core/legal/legal_documents.dart';
import 'package:fitnesbuster/presentation/screens/legal/legal_document_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _acceptTerms = false;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  final _termsTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _termsTap.onTap = () => _openLegalDocument(termsOfUse);
    _privacyTap.onTap = () => _openLegalDocument(privacyPolicy);
  }

  void _openLegalDocument(LegalDocument document) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(document: document),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) {
      return AppLocalizations.tl('enterEmailValidation');
    }
    final re = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) {
      return AppLocalizations.tl('invalidEmailFormat');
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) {
      return AppLocalizations.tl('enterPasswordValidation');
    }
    if (v.length < 6) return AppLocalizations.tl('passwordMinLength');
    if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
      return AppLocalizations.tl('passwordNeedLetter');
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return AppLocalizations.tl('passwordNeedNumber');
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) {
      return AppLocalizations.tl('enterPasswordValidation');
    }
    if (v != _passCtrl.text) return AppLocalizations.tl('passwordsDontMatch');
    return null;
  }

  double _passwordStrength(String p) {
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9!@#$%^&*]').hasMatch(p)) s += 0.25;
    return s;
  }

  Color _strengthColor(double s) {
    final colors = AppTheme.of(context);
    if (s <= 0.25) return colors.error;
    if (s <= 0.5) return colors.accentOrange;
    if (s <= 0.75) return colors.warning;
    return colors.success;
  }

  String _strengthLabel(double s) {
    if (s <= 0.25) return AppLocalizations.tl('passwordStrengthWeak');
    if (s <= 0.5) return AppLocalizations.tl('passwordStrengthMedium');
    if (s <= 0.75) return AppLocalizations.tl('passwordStrengthGood');
    return AppLocalizations.tl('passwordStrengthStrong');
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ensureTermsAccepted()) return;

    setState(() => _loading = true);
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        name: '',
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        consent: LegalConsentAcceptance.emailRegistration(
          localeCode: LanguageService.current.code,
        ),
      ),
    );
  }

  bool _ensureTermsAccepted() {
    if (_acceptTerms) return true;
    final colors = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.tl('authTermsRequired')),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return false;
  }

  void _handleGoogleRegister() {
    if (!_ensureTermsAccepted()) return;
    setState(() => _googleLoading = true);
    context.read<AuthBloc>().add(
      AuthGoogleLoginRequested(
        newAccountConsent: LegalConsentAcceptance.googleRegistration(
          localeCode: LanguageService.current.code,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    final passStrength = _passwordStrength(_passCtrl.text);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateAuthenticated) {
          setState(() {
            _loading = false;
            _googleLoading = false;
          });
          context.go('/onboarding/goal');
        } else if (state is AuthStateLoading) {
          setState(() => _loading = true);
        } else if (state is AuthStateUnauthenticated) {
          setState(() {
            _loading = false;
            _googleLoading = false;
          });
        } else if (state is AuthStateError) {
          setState(() {
            _loading = false;
            _googleLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: colors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            l10n.registerTitle,
                            style: AppTextStyles.displayL,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.registerSubtitle,
                            style: AppTextStyles.bodyL,
                          ),
                          const SizedBox(height: 32),

                          // Email
                          _buildLabel(l10n.emailLabel),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _emailCtrl,
                            hint: l10n.emailHint,
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildLabel(l10n.passwordLabel),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _passCtrl,
                            hint: l10n.passwordHint,
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePass,
                            validator: _validatePassword,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: colors.textMuted,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),

                          // Password strength
                          if (_passCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: passStrength,
                                      backgroundColor: colors.surfaceLight,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _strengthColor(passStrength),
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _strengthLabel(passStrength),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _strengthColor(passStrength),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Confirm password
                          _buildLabel(l10n.confirmPasswordLabel),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _confirmCtrl,
                            hint: l10n.confirmPasswordLabel,
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            validator: _validateConfirm,
                            textInputAction: TextInputAction.done,
                            onSubmit: (_) => _handleRegister(),
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: colors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Terms checkbox
                          GestureDetector(
                            onTap: () =>
                                setState(() => _acceptTerms = !_acceptTerms),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _acceptTerms
                                        ? colors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _acceptTerms
                                          ? colors.primary
                                          : colors.textMuted,
                                      width: 2,
                                    ),
                                  ),
                                  child: _acceptTerms
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: colors.textOnPrimary,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: AppLocalizations.tl(
                                            'authConsentPrefix',
                                          ),
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppLocalizations.tl(
                                            'authTermsOfUse',
                                          ),
                                          recognizer: _termsTap,
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppLocalizations.tl('authAnd'),
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppLocalizations.tl(
                                            'authPrivacyPolicy',
                                          ),
                                          recognizer: _privacyTap,
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Register button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: colors.textOnPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colors.textOnPrimary,
                                      ),
                                    )
                                  : Text(
                                      l10n.registerButton,
                                      style: const TextStyle(
                                        fontFamily: 'Syne',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  AppLocalizations.tl('authOr'),
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _googleLoading
                                  ? null
                                  : _handleGoogleRegister,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                backgroundColor: colors.surfaceLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _googleLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.textSecondary,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'G',
                                              style: TextStyle(
                                                fontFamily: 'Arial',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF4285F4),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          l10n.orContinueWith,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.alreadyHaveAccount,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  l10n.loginButton,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: AppTextStyles.labelL);

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onSubmit,
    void Function(String)? onChanged,
    Widget? suffix,
  }) {
    final colors = AppTheme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmit,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 16,
        fontFamily: 'Inter',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        errorStyle: TextStyle(color: colors.error, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
