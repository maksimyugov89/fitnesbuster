import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/constants/avatar_presets.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class AvatarPickerSheet extends StatefulWidget {
  final int currentPresetIndex;
  final String currentCustomPath;
  final ValueChanged<int> onPresetSelected;
  final ValueChanged<String> onCustomSelected;

  const AvatarPickerSheet({
    super.key,
    required this.currentPresetIndex,
    required this.currentCustomPath,
    required this.onPresetSelected,
    required this.onCustomSelected,
  });

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late int _selected;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPresetIndex;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 600, maxHeight: 600);
      if (xfile != null && mounted) widget.onCustomSelected(xfile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.tl('photoPickFailed')}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.only(top: 12, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text(AppLocalizations.tl('chooseAvatar'), style: AppTextStyles.titleL),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _SourceButton(icon: Icons.camera_alt_rounded, label: AppLocalizations.tl('camera'), color: colors.primary, onTap: _picking ? null : () => _pickImage(ImageSource.camera))),
          const SizedBox(width: 12),
          Expanded(child: _SourceButton(icon: Icons.photo_library_rounded, label: AppLocalizations.tl('gallery'), color: colors.accentPurple, onTap: _picking ? null : () => _pickImage(ImageSource.gallery))),
        ]),
        if (widget.currentCustomPath.isNotEmpty && File(widget.currentCustomPath).existsSync()) ...[
          const SizedBox(height: 16),
          Row(children: [
            Text(AppLocalizations.tl('yourPhoto'), style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(width: 12),
            ClipOval(child: Image.file(File(widget.currentCustomPath), width: 46, height: 46, fit: BoxFit.cover)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.primary.withValues(alpha: 0.4))),
              child: Text(AppLocalizations.tl('active'), style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w700)),
            ),
          ]),
        ],
        const SizedBox(height: 20),
        Divider(color: colors.surfaceLight),
        const SizedBox(height: 16),
        Row(children: [
          Text(AppLocalizations.tl('standardAvatars'), style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_selected >= 0)
            Semantics(
              label: AppLocalizations.tl('apply'),
              button: true,
              child: GestureDetector(
                onTap: () => widget.onPresetSelected(_selected),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text(AppLocalizations.tl('apply'), style: TextStyle(fontSize: 12, color: colors.textOnPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 14, crossAxisSpacing: 12, mainAxisExtent: 80),
          itemCount: kAvatarPresets.length,
          itemBuilder: (_, i) {
            final p = kAvatarPresets[i];
            final isSelected = _selected == i;
            return Semantics(
              label: '${AppLocalizations.tl('chooseAvatar')} ${p.label}',
              button: true,
              child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); setState(() => _selected = i); },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: p.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                    boxShadow: isSelected ? [BoxShadow(color: p.gradientColors.first.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)] : [],
                  ),
                  child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 5),
                Text(p.label, style: TextStyle(fontSize: 9, color: isSelected ? colors.primary : colors.textMuted, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _SourceButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
