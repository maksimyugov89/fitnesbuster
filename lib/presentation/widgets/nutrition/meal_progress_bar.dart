import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

class MealProgressBar extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final Set<int> completedMeals;
  final Map<String, String> mealIcons;
  final Map<String, Color> mealColors;
  final String Function(String) normalizeMealType;

  const MealProgressBar({
    super.key,
    required this.meals,
    required this.completedMeals,
    required this.mealIcons,
    required this.mealColors,
    required this.normalizeMealType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    if (meals.isEmpty) return const SizedBox.shrink();
    return Row(
      children: meals.asMap().entries.map((e) {
        final isDone = completedMeals.contains(e.key);
        final type = normalizeMealType(e.value['type'] as String? ?? '');
        final mealColor = mealColors[type] ?? colors.primary;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Text(
                  mealIcons[type] ?? '🍽️',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDone ? mealColor : colors.elevated,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
