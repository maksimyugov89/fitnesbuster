import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class AddedFoodTile extends StatelessWidget {
  final String name;
  final String mealType;
  final int grams;
  final int kcal;
  final VoidCallback onDelete;

  const AddedFoodTile({
    super.key,
    required this.name,
    required this.mealType,
    required this.grams,
    required this.kcal,
    required this.onDelete,
  });

  String get _mealTypeLabel {
    const keys = {
      'breakfast': 'breakfast',
      'lunch': 'lunch',
      'dinner': 'dinner',
      'snack': 'snack',
      'pre_workout': 'mealPreWorkout',
      'post_workout': 'mealPostWorkout',
      'evening_snack': 'mealEveningSnack',
      'morning_snack': 'mealMorningSnack',
    };
    final key = keys[mealType];
    return key == null ? mealType : AppLocalizations.tl(key);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              size: 16,
              color: colors.accentOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$_mealTypeLabel · $grams ${AppLocalizations.tl('gUnit')}${kcal > 0 ? ' · $kcal ${AppLocalizations.tl('kcalShort')}' : ''}',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          if (kcal > 0)
            Text(
              '$kcal',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.accentOrange,
              ),
            ),
          Semantics(
            label: AppLocalizations.tl('delete'),
            button: true,
            child: IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: colors.textMuted,
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
