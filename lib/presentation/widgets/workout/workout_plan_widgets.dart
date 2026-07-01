import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/presentation/widgets/workout/muscle_map_3d_widget.dart';

class ExerciseMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final dynamic colors;
  const ExerciseMeta({
    super.key,
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: colors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic colors;
  const MetaChip({
    super.key,
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class Muscle3DSheet extends StatelessWidget {
  final String title;
  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;
  const Muscle3DSheet({
    super.key,
    required this.title,
    required this.primaryMuscles,
    required this.secondaryMuscles,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sheetH = MediaQuery.of(context).size.height * 0.82;
    return Container(
      height: sheetH,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.view_in_ar_rounded, color: colors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  label: 'Закрыть',
                  button: true,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: colors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const LegendDot(
                  color: SemanticColors.primaryMuscle,
                  label: 'Основные',
                ),
                const SizedBox(width: 16),
                if (secondaryMuscles.isNotEmpty)
                  const LegendDot(
                    color: SemanticColors.secondaryMuscle,
                    label: 'Вспомогательные',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: MuscleMap3DWidget(
                primaryMuscles: primaryMuscles,
                secondaryMuscles: secondaryMuscles,
                height: sheetH - 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class ExerciseGifThumb extends StatelessWidget {
  final String name;
  final String? gifUrl;
  final Color accentColor;
  const ExerciseGifThumb({
    super.key,
    required this.name,
    required this.gifUrl,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (gifUrl == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.fitness_center_rounded, color: accentColor, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: gifUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        memCacheWidth: 88,
        memCacheHeight: 88,
        placeholder: (_, _) => Container(
          width: 44,
          height: 44,
          color: accentColor.withValues(alpha: 0.08),
          child: Icon(
            Icons.fitness_center_rounded,
            color: accentColor.withValues(alpha: 0.4),
            size: 20,
          ),
        ),
        errorWidget: (_, _, _) => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.fitness_center_rounded,
            color: accentColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}
