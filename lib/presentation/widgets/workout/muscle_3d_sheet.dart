import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/presentation/widgets/workout/muscle_map_3d_widget.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';

class WorkoutMuscle3DSheet extends StatelessWidget {
  final String title;
  final Set<String> primaryMuscles;
  final Set<String> secondaryMuscles;

  const WorkoutMuscle3DSheet({super.key, required this.title, required this.primaryMuscles, required this.secondaryMuscles});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final sheetH = MediaQuery.of(context).size.height * 0.82;

    return Container(
      height: sheetH,
      decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 38, height: 4, decoration: BoxDecoration(color: colors.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Icon(Icons.view_in_ar_rounded, color: colors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary), overflow: TextOverflow.ellipsis)),
            Semantics(label: 'Закрыть', button: true, child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: colors.textMuted), padding: EdgeInsets.zero, constraints: const BoxConstraints(), iconSize: 20)),
          ])),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const WorkoutLegendDot(color: SemanticColors.primaryMuscle, label: 'Основные'),
            const SizedBox(width: 16),
            if (secondaryMuscles.isNotEmpty) const WorkoutLegendDot(color: SemanticColors.secondaryMuscle, label: 'Вспомогательные'),
          ])),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: MuscleMap3DWidget(primaryMuscles: primaryMuscles, secondaryMuscles: secondaryMuscles, height: sheetH - 100),
          )),
      ]));
  }
}

class WorkoutLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const WorkoutLegendDot({super.key, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
    ]);
  }
}
