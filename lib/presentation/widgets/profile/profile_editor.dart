import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class ProfileEditorSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final VoidCallback onSave;
  final VoidCallback onAvatarTap;

  const ProfileEditorSheet({super.key, required this.nameCtrl, required this.emailCtrl, required this.onSave, required this.onAvatarTap});
  @override State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  final _form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return Form(
      key: _form,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Semantics(
          label: l10n.changeAvatar,
          button: true,
          child: GestureDetector(
            onTap: widget.onAvatarTap,
            child: Text(l10n.changeAvatar, style: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        _SheetField(controller: widget.nameCtrl, label: l10n.nameLabel, icon: Icons.person_outline_rounded, validator: (v) => v!.trim().isEmpty ? l10n.enterNameValidation : null, colors: colors),
        const SizedBox(height: 12),
        _SheetField(controller: widget.emailCtrl, label: l10n.emailLabel, icon: Icons.email_outlined, validator: (v) {
          if (v == null || v.trim().isEmpty) return l10n.enterEmailValidation;
          if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) return l10n.invalidEmailFormat;
          return null;
        }, colors: colors),
        const SizedBox(height: 16),
        Semantics(
          label: l10n.save,
          button: true,
          child: FilledButton(onPressed: () { if (_form.currentState!.validate()) widget.onSave(); },
            style: FilledButton.styleFrom(backgroundColor: colors.primary, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.w700))),
        ),
      ]),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final ThemePalette colors;
  const _SheetField({required this.controller, required this.label, required this.icon, required this.validator, required this.colors});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: colors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: colors.textMuted),
        filled: true, fillColor: colors.elevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.elevated)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.elevated)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
