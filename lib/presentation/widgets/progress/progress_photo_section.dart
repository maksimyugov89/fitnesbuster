import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

enum PhotoAngle {
  front('photoFront', 'photoFrontInstr', Icons.person_rounded),
  side('photoSide', 'photoSideInstr', Icons.person_outline_rounded),
  back('photoBack', 'photoBackInstr', Icons.accessibility_new_rounded);

  final String labelKey;
  final String instrKey;
  final IconData icon;
  const PhotoAngle(this.labelKey, this.instrKey, this.icon);
  String label(AppLocalizations l10n) => AppLocalizations.tl(labelKey);
  String instruction(AppLocalizations l10n) => AppLocalizations.tl(instrKey);
}

class ProgressPhotoSection extends StatelessWidget {
  final Map<PhotoAngle, File?> photos;
  final ValueChanged<PhotoAngle> onPickPhoto;
  const ProgressPhotoSection({
    super.key,
    required this.photos,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.photoProgressTitle2,
                style: AppTextStyles.titleM,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.anglesLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.photoNote,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: PhotoAngle.values.map((angle) {
              final file = photos[angle];
              return Expanded(
                child: Semantics(
                  label: angle.label(context.l10n),
                  button: true,
                  child: GestureDetector(
                    onTap: () => onPickPhoto(angle),
                    child: Container(
                      height: 110,
                      margin: EdgeInsets.only(
                        right: angle != PhotoAngle.back ? 8 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: file != null
                            ? Border.all(color: colors.primary, width: 2)
                            : null,
                        image: file != null
                            ? DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: file == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  angle.icon,
                                  color: colors.textMuted,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  angle.label(context.l10n),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.l10n.tapHint,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  angle.label(context.l10n),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
