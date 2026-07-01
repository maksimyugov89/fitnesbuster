import 'package:flutter/material.dart';
import 'package:fitnesbuster/data/models/ai_meal_plan.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class MacroRing extends StatelessWidget {
  final MealMacros macros;
  final Color color;

  const MacroRing({super.key, required this.macros, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NutritionChip(
          label: AppLocalizations.tl('proteinShort'),
          value: '${macros.protein}${AppLocalizations.tl('gUnit')}',
          color: color,
        ),
        const SizedBox(width: 8),
        _NutritionChip(
          label: AppLocalizations.tl('carbsShort'),
          value: '${macros.carbs}${AppLocalizations.tl('gUnit')}',
          color: color,
        ),
        const SizedBox(width: 8),
        _NutritionChip(
          label: AppLocalizations.tl('fatShort'),
          value: '${macros.fat}${AppLocalizations.tl('gUnit')}',
          color: color,
        ),
        if (macros.fiber > 0) ...[
          const SizedBox(width: 8),
          _NutritionChip(
            label: AppLocalizations.tl('fiberShort'),
            value: '${macros.fiber}${AppLocalizations.tl('gUnit')}',
            color: color,
          ),
        ],
      ],
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label, value;
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
