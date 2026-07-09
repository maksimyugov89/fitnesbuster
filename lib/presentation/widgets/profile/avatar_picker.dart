import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class ProfileAvatarPicker extends StatelessWidget {
  final String? currentPath;
  final File? previewFile;
  final ValueChanged<File> onFilePicked;
  final VoidCallback onRemove;

  const ProfileAvatarPicker({
    super.key,
    this.currentPath,
    this.previewFile,
    required this.onFilePicked,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _PickTile(
          icon: Icons.camera_alt_outlined,
          label: AppLocalizations.tl('takePhoto'),
          color: colors.primary,
          onTap: () => _pick(ImageSource.camera),
        ),
        _PickTile(
          icon: Icons.photo_library_outlined,
          label: AppLocalizations.tl('chooseFromGallery'),
          color: colors.accent,
          onTap: () => _pick(ImageSource.gallery),
        ),
        if (currentPath != null || previewFile != null)
          _PickTile(
            icon: Icons.delete_outline,
            label: AppLocalizations.tl('deleteAction'),
            color: colors.error,
            onTap: onRemove,
          ),
      ],
    );
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file != null) onFilePicked(File(file.path));
  }
}

class _PickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
