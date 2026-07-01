import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WorkoutGifThumb extends StatelessWidget {
  final String name;
  final String? gifUrl;
  final Color accentColor;

  const WorkoutGifThumb({
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
