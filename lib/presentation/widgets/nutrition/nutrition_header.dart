import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class NutritionHeader extends StatelessWidget {
  final int completedCount;
  final int totalMeals;
  final VoidCallback onShoppingListTap;

  const NutritionHeader({
    super.key,
    required this.completedCount,
    required this.totalMeals,
    required this.onShoppingListTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.nutritionTitle,
                    style: AppTextStyles.displayM,
                  ),
                ),
                Text(
                  context.l10n.aiPlanSubtitle,
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              ],
            ),
          ),
          if (completedCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                context.l10n.mealsEatenCount(completedCount, totalMeals),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Semantics(
            label: context.l10n.shoppingListLabel,
            button: true,
            child: GestureDetector(
              onTap: onShoppingListTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🛒', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.shoppingListLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
