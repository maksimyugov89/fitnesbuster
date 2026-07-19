import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/data/models/exercise_db_model.dart';
import 'package:fitnesbuster/presentation/widgets/workout/muscle_map_3d_widget.dart';
import 'package:fitnesbuster/presentation/widgets/loading_shimmer.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class ExerciseBrowserScreen extends StatefulWidget {
  const ExerciseBrowserScreen({super.key});

  @override
  State<ExerciseBrowserScreen> createState() => _ExerciseBrowserScreenState();
}

class _ExerciseBrowserScreenState extends State<ExerciseBrowserScreen> {
  // Muscle chip filter
  ExMuscle? _selectedMuscle;

  // Exercise-focus mode (highlights muscles on 3D map)
  ExerciseDbModel? _focusedExercise;

  ExEquipment? _equipFilter;
  ExDifficulty? _diffFilter;

  List<ExerciseDbModel> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exercises = await ExerciseDatabase.load();
    if (mounted) {
      setState(() {
        _all = exercises;
        _loading = false;
      });
    }
  }

  List<ExerciseDbModel> get _filtered {
    return _all.where((ex) {
      if (_selectedMuscle != null &&
          !ex.primaryMuscles.contains(_selectedMuscle!) &&
          !ex.secondaryMuscles.contains(_selectedMuscle!)) {
        return false;
      }
      if (_equipFilter != null && !ex.equipment.contains(_equipFilter!)) {
        return false;
      }
      if (_diffFilter != null && ex.difficulty != _diffFilter!) {
        return false;
      }
      return true;
    }).toList();
  }

  Set<String> get _primaryZones {
    if (_focusedExercise != null) {
      return _focusedExercise!.primaryMuscles
          .expand((m) => ExMuscleZone.zoneIdsFor(m))
          .toSet();
    }
    if (_selectedMuscle != null) {
      return ExMuscleZone.zoneIdsFor(_selectedMuscle!).toSet();
    }
    return {};
  }

  Set<String> get _secondaryZones {
    if (_focusedExercise != null) {
      return _focusedExercise!.secondaryMuscles
          .expand((m) => ExMuscleZone.zoneIdsFor(m))
          .toSet();
    }
    return {};
  }

  void _onExerciseTap(ExerciseDbModel ex) {
    setState(() {
      if (_focusedExercise?.id == ex.id) {
        _focusedExercise = null;
        return;
      }
      _focusedExercise = ex;
      _selectedMuscle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(c),
          SliverToBoxAdapter(child: _buildMapPanel(c)),
          SliverToBoxAdapter(child: _buildControls(c)),
          if (_loading)
            SliverFillRemaining(
              child: Center(child: LoadingShimmer.gridView(6)),
            )
          else
            _buildExerciseList(c),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemePalette c) {
    return SliverAppBar(
      backgroundColor: c.background,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: c.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppImages.exercises, width: 28, height: 28),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.tl('exercisesTitle'),
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: c.surfaceLight),
      ),
    );
  }

  Widget _buildMapPanel(ThemePalette c) {
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          // 3D muscle map
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MuscleMap3DWidget(
              primaryMuscles: _primaryZones,
              secondaryMuscles: _secondaryZones,
              height: 280,
            ),
          ),
          const SizedBox(height: 10),
          // Status pill
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _focusedExercise != null
                ? _ExercisePill(
                    exercise: _focusedExercise!,
                    c: c,
                    onClear: () => setState(() {
                      _focusedExercise = null;
                    }),
                  )
                : _selectedMuscle != null
                ? _MusclePill(
                    muscle: _selectedMuscle!,
                    c: c,
                    onClear: () => setState(() {
                      _selectedMuscle = null;
                    }),
                  )
                : Text(
                    AppLocalizations.tl('exerciseSelectionHint'),
                    key: const ValueKey('hint'),
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                    textAlign: TextAlign.center,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemePalette c) {
    return Container(
      color: c.background,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Muscle filter
          _FilterRow<ExMuscle>(
            label: AppLocalizations.tl('filterMuscle'),
            selected: _selectedMuscle,
            items: ExMuscle.values
                .where((m) => m != ExMuscle.pectoralisMinor)
                .map(
                  (m) => (
                    m,
                    m.displayNameForLocale(
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
                )
                .toList(),
            onSelected: (v) => setState(() {
              _focusedExercise = null;
              _selectedMuscle = _selectedMuscle == v ? null : v;
            }),
            c: c,
          ),
          const SizedBox(height: 8),
          // Equipment filter
          _FilterRow<ExEquipment>(
            label: AppLocalizations.tl('filterEquipment'),
            selected: _equipFilter,
            items: [
              (
                ExEquipment.barbell,
                AppLocalizations.tl('exerciseEquipmentBarbell'),
              ),
              (
                ExEquipment.dumbbell,
                AppLocalizations.tl('exerciseEquipmentDumbbell'),
              ),
              (
                ExEquipment.machine,
                AppLocalizations.tl('exerciseEquipmentMachine'),
              ),
              (
                ExEquipment.bodyweight,
                AppLocalizations.tl('exerciseEquipmentBodyweight'),
              ),
              (
                ExEquipment.cables,
                AppLocalizations.tl('exerciseEquipmentCables'),
              ),
              (
                ExEquipment.kettlebell,
                AppLocalizations.tl('exerciseEquipmentKettlebell'),
              ),
            ],
            onSelected: (v) =>
                setState(() => _equipFilter = _equipFilter == v ? null : v),
            c: c,
          ),
          const SizedBox(height: 8),
          // Difficulty filter
          _FilterRow<ExDifficulty>(
            label: AppLocalizations.tl('filterDifficulty'),
            selected: _diffFilter,
            items: [
              (
                ExDifficulty.beginner,
                AppLocalizations.tl('exerciseDifficultyBeginner'),
              ),
              (
                ExDifficulty.intermediate,
                AppLocalizations.tl('exerciseDifficultyIntermediate'),
              ),
              (
                ExDifficulty.advanced,
                AppLocalizations.tl('exerciseDifficultyAdvanced'),
              ),
            ],
            onSelected: (v) =>
                setState(() => _diffFilter = _diffFilter == v ? null : v),
            c: c,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tlp('exercisesCount', {
              'n': '${_filtered.length}',
            }),
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildExerciseList(ThemePalette c) {
    final list = _filtered;
    if (list.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center_rounded, size: 48, color: c.textMuted),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.tl('exerciseNotFound'),
                style: TextStyle(color: c.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _ExerciseCard(
            exercise: list[i],
            c: c,
            isSelected: _focusedExercise?.id == list[i].id,
            onTap: () => _onExerciseTap(list[i]),
            onDetailTap: () => ctx.push('/exercises/${list[i].id}'),
          ),
          childCount: list.length,
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MusclePill extends StatelessWidget {
  final ExMuscle muscle;
  final ThemePalette c;
  final VoidCallback onClear;
  const _MusclePill({
    required this.muscle,
    required this.c,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(muscle),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_rounded, size: 14, color: c.primary),
          const SizedBox(width: 6),
          Text(
            muscle.displayNameForLocale(
              Localizations.localeOf(context).languageCode,
            ),
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.primary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close_rounded, size: 14, color: c.primary),
          ),
        ],
      ),
    );
  }
}

class _ExercisePill extends StatelessWidget {
  final ExerciseDbModel exercise;
  final ThemePalette c;
  final VoidCallback onClear;
  const _ExercisePill({
    required this.exercise,
    required this.c,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(exercise.id),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: SemanticColors.primaryMuscle.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SemanticColors.primaryMuscle.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            size: 14,
            color: Color(0xFFE8453C),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              exercise.displayNameForLocale(
                Localizations.localeOf(context).languageCode,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE8453C),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFFE8453C),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow<T> extends StatelessWidget {
  final String label;
  final T? selected;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;
  final ThemePalette c;

  const _FilterRow({
    required this.label,
    required this.selected,
    required this.items,
    required this.onSelected,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, text) = items[i];
          final isSel = selected == value;
          return GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? c.primary : c.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                  color: isSel ? c.textOnPrimary : c.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseDbModel exercise;
  final ThemePalette c;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDetailTap;
  const _ExerciseCard({
    required this.exercise,
    required this.c,
    this.isSelected = false,
    this.onTap,
    this.onDetailTap,
  });

  Color _diffColor() => switch (exercise.difficulty) {
    ExDifficulty.beginner => SemanticColors.difficultyBeginner,
    ExDifficulty.intermediate => SemanticColors.difficultyIntermediate,
    ExDifficulty.advanced => SemanticColors.difficultyAdvanced,
  };

  String _diffLabel() => switch (exercise.difficulty) {
    ExDifficulty.beginner => AppLocalizations.tl('exerciseDifficultyBeginner'),
    ExDifficulty.intermediate => AppLocalizations.tl(
      'exerciseDifficultyIntermediate',
    ),
    ExDifficulty.advanced => AppLocalizations.tl('exerciseDifficultyAdvanced'),
  };

  String _equipLabel(ExEquipment e) => switch (e) {
    ExEquipment.barbell => AppLocalizations.tl('exerciseEquipmentBarbell'),
    ExEquipment.dumbbell => AppLocalizations.tl('exerciseEquipmentDumbbell'),
    ExEquipment.machine => AppLocalizations.tl('exerciseEquipmentMachine'),
    ExEquipment.bodyweight => AppLocalizations.tl(
      'exerciseEquipmentBodyweight',
    ),
    ExEquipment.cables => AppLocalizations.tl('exerciseEquipmentCables'),
    ExEquipment.kettlebell => AppLocalizations.tl(
      'exerciseEquipmentKettlebell',
    ),
    ExEquipment.none => '',
  };

  @override
  Widget build(BuildContext context) {
    final diffColor = _diffColor();
    final primMuscles = exercise.primaryMuscles
        .take(2)
        .map(
          (m) => m.displayNameForLocale(
            Localizations.localeOf(context).languageCode,
          ),
        )
        .join(' · ');
    final equipLabels = exercise.equipment
        .where((e) => e != ExEquipment.none)
        .map(_equipLabel)
        .where((s) => s.isNotEmpty)
        .toList();
    final gifUrl = exercise.gifUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: isSelected ? c.primary.withValues(alpha: 0.1) : c.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? c.primary.withValues(alpha: 0.6)
                : c.surfaceLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GIF thumbnail
            gifUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: gifUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      memCacheWidth: 88,
                      memCacheHeight: 88,
                      placeholder: (_, _) => Container(
                        width: 44,
                        height: 44,
                        color: c.surfaceLight,
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: c.textMuted,
                          size: 20,
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: c.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: c.textMuted,
                      size: 20,
                    ),
                  ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.displayNameForLocale(
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? c.primary : c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _diffLabel(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: diffColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDetailTap,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (primMuscles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      primMuscles,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                  if (equipLabels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: equipLabels
                          .map(
                            (label) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
