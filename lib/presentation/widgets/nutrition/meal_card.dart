import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/data/models/ai_meal_plan.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/food_item_row.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/meal_alternatives_tile.dart';

class MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final bool isDone;
  final String mealLabel;
  final String mealIcon;
  final Color mealColor;
  final VoidCallback onToggle;

  const MealCard({
    super.key,
    required this.meal,
    required this.isDone,
    required this.mealLabel,
    required this.mealIcon,
    required this.mealColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final time = meal['time'] as String? ?? '';
    final foods = (meal['foods'] as List? ?? []).cast<String>();
    final cal = (meal['calories'] as num?)?.toInt() ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDone ? mealColor.withValues(alpha: 0.08) : colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? mealColor.withValues(alpha: 0.5)
              : colors.textPrimary.withValues(alpha: 0.06),
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MealCardHeader(
            mealLabel: mealLabel,
            mealIcon: mealIcon,
            mealColor: mealColor,
            cal: cal,
            time: time,
            isDone: isDone,
          ),
          if (foods.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: foods
                    .map(
                      (food) => NutritionFoodItemRow(
                        food: food,
                        colors: colors,
                        mealColor: mealColor,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          _MealMacrosRow(meal: meal, mealColor: mealColor, colors: colors),
          _MealAlternatives(meal: meal, mealColor: mealColor, colors: colors),
          _CompleteButton(
            isDone: isDone,
            mealColor: mealColor,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }
}

class _MealCardHeader extends StatelessWidget {
  final String mealLabel;
  final String mealIcon;
  final Color mealColor;
  final int cal;
  final String time;
  final bool isDone;

  const _MealCardHeader({
    required this.mealLabel,
    required this.mealIcon,
    required this.mealColor,
    required this.cal,
    required this.time,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mealColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(mealIcon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealLabel,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: mealColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$cal ${AppLocalizations.tl('kcalShort')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: mealColor,
                  ),
                ),
              ),
              if (isDone)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: mealColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.l10n.mealCompleted,
                        style: TextStyle(
                          fontSize: 10,
                          color: mealColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealMacrosRow extends StatelessWidget {
  final Map<String, dynamic> meal;
  final Color mealColor;
  final ThemePalette colors;

  const _MealMacrosRow({
    required this.meal,
    required this.mealColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final macroRaw =
        meal['macros'] as Map<String, dynamic>? ??
        meal['macro_breakdown'] as Map<String, dynamic>?;
    if (macroRaw == null) return const SizedBox.shrink();
    final macros = MealMacros.fromJson(macroRaw);
    if (macros.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: mealColor.withValues(alpha: 0.12)),
          Row(
            children: [
              _NutritionChip(
                label: context.l10n.proteinShort,
                value: '${macros.protein}${AppLocalizations.tl('gUnit')}',
                color: mealColor,
              ),
              const SizedBox(width: 8),
              _NutritionChip(
                label: context.l10n.carbsShort,
                value: '${macros.carbs}${AppLocalizations.tl('gUnit')}',
                color: mealColor,
              ),
              const SizedBox(width: 8),
              _NutritionChip(
                label: context.l10n.fatShort,
                value: '${macros.fat}${AppLocalizations.tl('gUnit')}',
                color: mealColor,
              ),
              if (macros.fiber > 0) ...[
                const SizedBox(width: 8),
                _NutritionChip(
                  label: context.l10n.fiberShort,
                  value: '${macros.fiber}${AppLocalizations.tl('gUnit')}',
                  color: mealColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MealAlternatives extends StatelessWidget {
  final Map<String, dynamic> meal;
  final Color mealColor;
  final ThemePalette colors;

  const _MealAlternatives({
    required this.meal,
    required this.mealColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final altsRaw = meal['alternatives'] as List?;
    if (altsRaw == null || altsRaw.isEmpty) return const SizedBox.shrink();
    final alts = altsRaw.cast<String>();
    return MealAlternativesTile(alternatives: alts, mealColor: mealColor);
  }
}

class _CompleteButton extends StatelessWidget {
  final bool isDone;
  final Color mealColor;
  final VoidCallback onToggle;

  const _CompleteButton({
    required this.isDone,
    required this.mealColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: isDone
            ? Semantics(
                label: context.l10n.mealCancelCompleted,
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onToggle();
                  },
                  icon: Icon(Icons.undo_rounded, size: 16, color: mealColor),
                  label: Text(
                    context.l10n.mealCancelCompleted,
                    style: TextStyle(
                      fontSize: 13,
                      color: mealColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: mealColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            : Semantics(
                label: context.l10n.mealCompleted,
                button: true,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onToggle();
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    context.l10n.mealCompleted,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: mealColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
