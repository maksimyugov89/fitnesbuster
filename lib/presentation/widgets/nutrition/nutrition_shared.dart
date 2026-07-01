import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

String localizedMealLabel(BuildContext context, String key) {
  final l = context.l10n;
  return switch (key) {
    'breakfast' => l.breakfast,
    'lunch' => l.lunch,
    'dinner' => l.dinner,
    'snack' => l.snack,
    'pre_workout' => l.snack,
    'post_workout' => l.snack,
    'evening_snack' => l.snack,
    'morning_snack' => l.breakfast,
    _ => key,
  };
}

class FoodEntry {
  final String name, mealType;
  final int grams, kcal;
  const FoodEntry({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.mealType,
  });
}

class NutritionFormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final ThemePalette colors;
  final TextInputType textInput;
  const NutritionFormField({
    super.key,
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.colors,
    required this.textInput,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: textInput,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: colors.textMuted),
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.elevated),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.elevated),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
