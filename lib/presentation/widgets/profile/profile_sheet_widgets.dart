import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class SheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const SheetWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.titleL),
          const SizedBox(height: 24),
          child,
        ]),
      ),
    );
  }
}

class SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  const SheetField({super.key, required this.controller, required this.label, required this.icon, this.obscure = false, this.keyboardType, this.validator, this.suffix});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelL),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(color: colors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
          filled: true,
          fillColor: colors.surfaceLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.error)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.error, width: 2)),
          errorStyle: TextStyle(color: colors.error, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}

class SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? label;
  const SaveButton({super.key, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return Semantics(
      label: label ?? l10n.save,
      button: true,
      child: SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.textOnPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label ?? l10n.save, style: const TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class NotifToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const NotifToggle({super.key, required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textMuted)),
      value: value,
      activeTrackColor: colors.primary,
      onChanged: onChanged,
    );
  }
}
