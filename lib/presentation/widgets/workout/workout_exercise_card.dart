import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/muscle_zone_matcher.dart';
import 'package:fitnesbuster/domain/services/i_exercise_service.dart';
import 'package:fitnesbuster/presentation/widgets/workout/workout_plan_widgets.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class WorkoutExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final dynamic colors;
  final bool matcherReady;
  final VoidCallback onShow3D;
  final VoidCallback onShowTechnique;
  final bool showTechnique;

  const WorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.colors,
    required this.matcherReady,
    required this.onShow3D,
    required this.onShowTechnique,
    this.showTechnique = true,
  });

  static String _s(dynamic v) {
    if (v is String) return v;
    if (v is List) return v.map((e) => e.toString()).join(', ');
    return '';
  }

  static Color _rpeColor(int rpe, dynamic colors) {
    if (rpe <= 0) return colors.textMuted as Color;
    if (rpe <= 5) return colors.success as Color;
    if (rpe <= 7) return colors.accentOrange as Color;
    return colors.error as Color;
  }

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    final name = _s(ex['name']).isNotEmpty ? _s(ex['name']) : AppLocalizations.tl('exerciseDefault');
    final sets = ex['sets']?.toString() ?? '3';
    final reps = ex['reps']?.toString() ?? '';
    final rest = (ex['rest_seconds'] as num?)?.toInt() ?? 60;
    final rpe = (ex['rpe'] as num?)?.toInt() ?? 0;
    final weightGuideline = _s(ex['weight_guideline']);
    final techniqueCue = _s(ex['technique_cue']).isNotEmpty ? _s(ex['technique_cue']) : _s(ex['technique_tip']);
    final progression = _s(ex['progression']);
    final musclePrimary = _s(ex['muscle_primary']).isNotEmpty ? _s(ex['muscle_primary']) : _s(ex['muscle_group']);
    final primaryZones = musclePrimary.isNotEmpty ? MuscleZoneMatcher.parse(musclePrimary) : <String>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ExerciseGifThumb(
            name: name,
            gifUrl: matcherReady ? sl<IExerciseService>().findByRuName(name)?.gifUrl : null,
            accentColor: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Row(children: [
              Text('$sets × $reps', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              if (musclePrimary.isNotEmpty) ...[
                Text('  ·  ', style: TextStyle(color: colors.textMuted)),
                Flexible(child: Text(musclePrimary, style: TextStyle(fontSize: 11, color: colors.textMuted), overflow: TextOverflow.ellipsis)),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('⏱ $rest с', style: TextStyle(fontSize: 11, color: colors.textMuted)),
            if (rpe > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _rpeColor(rpe, colors).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('RPE $rpe', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _rpeColor(rpe, colors))),
              ),
            ],
          ]),
        ]),
        if (weightGuideline.isNotEmpty || techniqueCue.isNotEmpty || progression.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (weightGuideline.isNotEmpty)
            ExerciseMeta(icon: Icons.monitor_weight_outlined, text: weightGuideline, colors: colors),
          if (techniqueCue.isNotEmpty)
            ExerciseMeta(icon: Icons.lightbulb_outline_rounded, text: techniqueCue, colors: colors),
          if (progression.isNotEmpty)
            ExerciseMeta(icon: Icons.trending_up_rounded, text: progression, colors: colors),
        ],
        if (showTechnique && (primaryZones.isNotEmpty || techniqueCue.isNotEmpty || progression.isNotEmpty)) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(children: [
            if (primaryZones.isNotEmpty)
              Semantics(
                label: '3D мышцы',
                button: true,
                child: GestureDetector(
                  onTap: onShow3D,
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.view_in_ar_rounded, color: colors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text('3D мышцы', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary)),
                  ]),
                ),
              ),
            ),
            const Spacer(),
            if (techniqueCue.isNotEmpty || progression.isNotEmpty)
              Semantics(
                label: 'Техника',
                button: true,
                child: GestureDetector(
                  onTap: onShowTechnique,
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SemanticColors.technique.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SemanticColors.technique.withValues(alpha: 0.2)),
                  ),
                  child:                   const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.format_list_bulleted_rounded, color: SemanticColors.technique, size: 14),
                    SizedBox(width: 6),
                    Text('Техника', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SemanticColors.technique)),
                  ]),
                ),
              ),
              ),
          ]),
        ],
      ]),
    );
  }
}
