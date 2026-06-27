import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return AppLocalizations.tl('enterEmailValidation');
    final re = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return AppLocalizations.tl('invalidEmailFormat');
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return AppLocalizations.tl('enterPasswordValidation');
    if (v.length < 6) return AppLocalizations.tl('passwordMinLength');
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    context.read<AuthBloc>().add(AuthLoginRequested(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    ));
  }

  void _handleGoogleLogin() {
    setState(() { _googleLoading = true; _errorMessage = null; });
    context.read<AuthBloc>().add(const AuthGoogleLoginRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateLoading) {
          setState(() => _loading = true);
        } else if (state is AuthStateAuthenticated) {
          setState(() { _loading = false; _googleLoading = false; });
          context.go('/dashboard');
        } else if (state is AuthStateError) {
          setState(() {
            _loading = false;
            _googleLoading = false;
            _errorMessage = state.message;
          });
        } else if (state is AuthStateUnauthenticated) {
          setState(() { _loading = false; _googleLoading = false; });
        }
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(
            width: 350, height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [colors.primary.withValues(alpha: 0.125), Colors.transparent]),
            ),
          )),
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
                        const SizedBox(height: 60),
                        _buildLogo(),
                        const SizedBox(height: 32),
                        Text(l10n.loginTitle, style: AppTextStyles.displayL),
                        const SizedBox(height: 8),
                        Text(l10n.loginSubtitle, style: AppTextStyles.bodyL),
                        const SizedBox(height: 40),

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
                          obscure: _obscure,
                          validator: _validatePassword,
                          textInputAction: TextInputAction.done,
                          onSubmit: (_) => _handleLogin(),
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: colors.textMuted, size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline_rounded, color: colors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: TextStyle(color: colors.error, fontSize: 13))),
                            ]),
                          ),
                        ],

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(l10n.forgotPassword, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),

                        const SizedBox(height: 8),
                        _buildLoginButton(),
                        const SizedBox(height: 20),
                        _buildDivider(),
                        const SizedBox(height: 20),
                        _buildGoogleButton(),
                        const SizedBox(height: 32),
                        _buildRegisterLink(),
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

  Widget _buildLogo() {
    final colors = AppTheme.of(context);
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(gradient: colors.primaryGradient, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text('FB', style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: colors.textOnPrimary))),
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
    Widget? suffix,
  }) {
    final colors = AppTheme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmit,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildLoginButton() {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textOnPrimary,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.textOnPrimary))
            : Text(l10n.loginButton, style: const TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildDivider() {
    final colors = AppTheme.of(context);
    return Row(children: [
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('или', style: TextStyle(color: colors.textMuted, fontSize: 13))),
      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
    ]);
  }

  Widget _buildGoogleButton() {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        onPressed: _googleLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          backgroundColor: colors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _googleLoading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _GoogleIcon(),
                const SizedBox(width: 12),
                Text(l10n.signInWithGoogle, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
      ),
    );
  }

  Widget _buildRegisterLink() {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Flexible(child: Text(l10n.dontHaveAccount, style: TextStyle(color: colors.textSecondary, fontSize: 14), overflow: TextOverflow.ellipsis)),
      GestureDetector(
        onTap: () => context.push('/register'),
        child: Text(l10n.registerButton, style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    ]);
  }

}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      child: const Center(
        child: Text('G', style: TextStyle(
          fontFamily: 'Arial', fontSize: 14, fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        )),
      ),
    );
  }
}
