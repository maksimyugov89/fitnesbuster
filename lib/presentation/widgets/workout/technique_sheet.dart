import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';

class WorkoutTechniqueSheet extends StatefulWidget {
  final String title;
  final String techniqueCue;
  final String progression;
  final String weightGuideline;

  const WorkoutTechniqueSheet({super.key, required this.title, required this.techniqueCue, required this.progression, required this.weightGuideline});

  @override
  State<WorkoutTechniqueSheet> createState() => _WorkoutTechniqueSheetState();
}

class _WorkoutTechniqueSheetState extends State<WorkoutTechniqueSheet> {
  String? _gifUrl;

  @override
  void initState() { super.initState(); _loadGif(); }

  Future<void> _loadGif() async {
    final exService = sl<IExerciseService>();
    await exService.init();
    final model = exService.findByRuName(widget.title);
    if (mounted && model?.gifUrl != null) setState(() => _gifUrl = model!.gifUrl);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: BoxDecoration(color: colors.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 38, height: 4, decoration: BoxDecoration(color: colors.colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.format_list_bulleted_rounded, color: SemanticColors.technique, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.title, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
            Semantics(label: 'Закрыть', button: true, child: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: colors.colorScheme.onSurface.withValues(alpha: 0.6)), padding: EdgeInsets.zero, constraints: const BoxConstraints(), iconSize: 20)),
          ])),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_gifUrl != null) ...[
                ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: _gifUrl!, width: double.infinity, height: 220, fit: BoxFit.contain, placeholder: (_, _) => Container(height: 220, decoration: BoxDecoration(color: colors.colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: SemanticColors.technique))), errorWidget: (_, _, _) => const SizedBox.shrink())),
                const SizedBox(height: 16),
              ],
              if (widget.techniqueCue.isNotEmpty) ...[
                _TechniqueSection(icon: Icons.lightbulb_rounded, label: 'Техника', text: widget.techniqueCue, color: SemanticColors.technique),
                const SizedBox(height: 12),
              ],
              if (widget.weightGuideline.isNotEmpty) ...[
                _TechniqueSection(icon: Icons.monitor_weight_outlined, label: 'Нагрузка', text: widget.weightGuideline, color: SemanticColors.weightGuideline),
                const SizedBox(height: 12),
              ],
              if (widget.progression.isNotEmpty) _TechniqueSection(icon: Icons.trending_up_rounded, label: 'Прогрессия', text: widget.progression, color: SemanticColors.progression),
            ])))],
      ));
  }
}

class _TechniqueSection extends StatelessWidget {
  final IconData icon;
  final String label, text;
  final Color color;
  const _TechniqueSection({required this.icon, required this.label, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(fontSize: 13, color: c.colorScheme.onSurface, height: 1.45)),
        ])),
      ]));
  }
}
