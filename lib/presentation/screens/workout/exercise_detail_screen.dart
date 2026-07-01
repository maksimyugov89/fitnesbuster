// cspell:disable
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/data/models/exercise_db_model.dart';
import 'package:fitnesbuster/presentation/widgets/workout/muscle_map_3d_widget.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  ExerciseDbModel? _exercise;
  bool _loading = true;
  // ── AI form tips ───────────────────────────────────────────────────────────
  String? _aiTips;
  bool _tipsLoading = false;
  bool _tipsError = false;

  // ── Russian instructions (translated via AI) ───────────────────────────────
  List<String>? _instructionsRu;
  bool _instructionsLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    final db = await ExerciseDatabase.load();
    final ex = db.firstWhere(
      (e) => e.id == widget.exerciseId,
      orElse: () => db.first,
    );
    if (mounted) {
      setState(() {
        _exercise = ex;
        _loading = false;
      });
      _loadAiTips(ex);
      _loadInstructionsRu(ex);
      // _loadGif(ex); — disabled: current ExerciseDB API has no gifUrl
    }
  }

  Future<void> _loadInstructionsRu(ExerciseDbModel ex) async {
    if (ex.instructions.isEmpty) return;
    final cacheKey = 'exercise_instructions_ru_${ex.id}';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final list = (jsonDecode(cached) as List).cast<String>();
      if (mounted) setState(() => _instructionsRu = list);
      return;
    }
    if (mounted) setState(() => _instructionsLoading = true);
    try {
      final ai = sl<IDeepSeekService>();
      final numbered = ex.instructions
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value}')
          .join('\n');
      final result = await ai.askQuestion(
        'Переведи эти шаги выполнения упражнения на русский язык. '
        'Верни ровно столько же строк, каждую с новой строки, без нумерации и лишних слов:\n$numbered',
      );
      final lines = result
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();
      await prefs.setString(cacheKey, jsonEncode(lines));
      if (mounted) {
        setState(() {
          _instructionsRu = lines;
          _instructionsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _instructionsLoading = false);
    }
  }

  Future<void> _loadAiTips(ExerciseDbModel ex) async {
    final cacheKey = 'exercise_tips_${ex.id}';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      if (mounted) setState(() => _aiTips = cached);
      return;
    }
    if (mounted) {
      setState(() {
        _tipsLoading = true;
        _tipsError = false;
      });
    }
    try {
      final ai = sl<IDeepSeekService>();
      final muscles = ex.primaryMuscles.map((m) => m.displayNameRu).join(', ');
      final tips = await ai.askQuestion(
        'Упражнение: «${ex.nameRu}» (${ex.name}). Мышцы: $muscles.\n'
        'Дай 3–4 ключевых совета по технике выполнения и 2 типичные ошибки. '
        'Ответ — короткими пунктами, без вступлений, только суть.',
      );
      await prefs.setString(cacheKey, tips.trim());
      if (mounted) {
        setState(() {
          _aiTips = tips.trim();
          _tipsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tipsLoading = false;
          _tipsError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }
    final ex = _exercise!;

    final primaryZones = ex.primaryMuscles
        .expand((m) => ExMuscleZone.zoneIdsFor(m))
        .toSet();
    final secondaryZones = ex.secondaryMuscles
        .expand((m) => ExMuscleZone.zoneIdsFor(m))
        .toSet();

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(c, ex),
          SliverToBoxAdapter(
            child: _buildMuscleSection(c, ex, primaryZones, secondaryZones),
          ),
          SliverToBoxAdapter(child: _buildInfoChips(c, ex)),
          SliverToBoxAdapter(child: _buildGifDemo(c, ex)),
          SliverToBoxAdapter(child: _buildInstructions(c, ex)),
          SliverToBoxAdapter(child: _buildAiTips(c)),
          if (ex.tags.isNotEmpty) SliverToBoxAdapter(child: _buildTags(c, ex)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemePalette c, ExerciseDbModel ex) {
    return SliverAppBar(
      backgroundColor: c.background,
      pinned: true,
      elevation: 0,
      expandedHeight: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: c.textPrimary,
            size: 18,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ex.nameRu,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (ex.name != ex.nameRu)
            Text(
              ex.name,
              style: TextStyle(fontSize: 10, color: c.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: c.surfaceLight),
      ),
    );
  }

  Widget _buildMuscleSection(
    ThemePalette c,
    ExerciseDbModel ex,
    Set<String> primaryZones,
    Set<String> secondaryZones,
  ) {
    return Container(
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // 3D interactive muscle model
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MuscleMap3DWidget(
              primaryMuscles: primaryZones,
              secondaryMuscles: secondaryZones,
              height: 340,
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: SemanticColors.primaryMuscle,
                label: 'Основные',
              ),
              SizedBox(width: 16),
              _LegendDot(
                color: SemanticColors.secondaryMuscle,
                label: 'Вторичные',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ex.primaryMuscles.isNotEmpty)
            _MuscleRow(
              label: 'Основные',
              muscles: ex.primaryMuscles.map((m) => m.displayNameRu).toList(),
              color: SemanticColors.primaryMuscle,
              c: c,
            ),
          if (ex.secondaryMuscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MuscleRow(
              label: 'Вторичные',
              muscles: ex.secondaryMuscles.map((m) => m.displayNameRu).toList(),
              color: SemanticColors.secondaryMuscle,
              c: c,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChips(ThemePalette c, ExerciseDbModel ex) {
    final diffColor = switch (ex.difficulty) {
      ExDifficulty.beginner => SemanticColors.difficultyBeginner,
      ExDifficulty.intermediate => SemanticColors.difficultyIntermediate,
      ExDifficulty.advanced => SemanticColors.difficultyAdvanced,
    };
    final diffLabel = switch (ex.difficulty) {
      ExDifficulty.beginner => 'Начинающий',
      ExDifficulty.intermediate => 'Средний',
      ExDifficulty.advanced => 'Продвинутый',
    };
    final movLabel = switch (ex.movementType) {
      ExMovementType.push => 'Толчок',
      ExMovementType.pull => 'Тяга',
      ExMovementType.hinge => 'Шарнир',
      ExMovementType.squat => 'Присед',
      ExMovementType.lunge => 'Выпад',
      ExMovementType.rotation => 'Вращение',
      ExMovementType.isolation => 'Изоляция',
    };
    String equipLabel(ExEquipment e) => switch (e) {
      ExEquipment.barbell => 'Штанга',
      ExEquipment.dumbbell => 'Гантели',
      ExEquipment.machine => 'Тренажёр',
      ExEquipment.bodyweight => 'Без веса',
      ExEquipment.cables => 'Блок',
      ExEquipment.kettlebell => 'Гиря',
      ExEquipment.none => '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tl('characteristics'),
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: diffLabel, color: diffColor),
              _InfoChip(label: movLabel, color: c.primary),
              ...ex.equipment
                  .where((e) => e != ExEquipment.none)
                  .map(
                    (e) =>
                        _InfoChip(label: equipLabel(e), color: c.accentPurple),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(ThemePalette c, ExerciseDbModel ex) {
    if (ex.instructions.isEmpty) return const SizedBox.shrink();
    // Only show when Russian translation is ready or loading
    if (_instructionsRu == null && !_instructionsLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.tl('technique'),
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              if (_instructionsLoading) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.primary,
                  ),
                ),
              ],
            ],
          ),
          if (_instructionsRu != null) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: c.textPrimary.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: _instructionsRu!.asMap().entries.map((entry) {
                  final i = entry.key;
                  final step = entry.value;
                  final isLast = i == _instructionsRu!.length - 1;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      i == 0 ? 16 : 12,
                      16,
                      isLast ? 16 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: c.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              step,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGifDemo(ThemePalette c, ExerciseDbModel ex) {
    final url = ex.gifUrl;
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Как выполнять',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.textPrimary.withValues(alpha: 0.06)),
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: double.infinity,
              placeholder: (_, _) => SizedBox(
                height: 260,
                child: Center(
                  child: CircularProgressIndicator(
                    color: c.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTips(ThemePalette c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.textPrimary.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  'AI-советы по технике',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_tipsLoading)
              Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Анализирую технику...',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ],
              )
            else if (_aiTips != null)
              Text(
                _aiTips!,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                  height: 1.55,
                ),
              )
            else if (_tipsError)
              Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 14, color: c.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Нет соединения',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (_exercise != null) _loadAiTips(_exercise!);
                    },
                    child: Text(
                      'Повторить',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Советы загружаются...',
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(ThemePalette c, ExerciseDbModel ex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: ex.tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: c.elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 11, color: c.textMuted),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.of(context).textMuted),
        ),
      ],
    );
  }
}

class _MuscleRow extends StatelessWidget {
  final String label;
  final List<String> muscles;
  final Color color;
  final ThemePalette c;
  const _MuscleRow({
    required this.label,
    required this.muscles,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: muscles
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
