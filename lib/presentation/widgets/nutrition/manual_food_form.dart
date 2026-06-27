import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/nutrition_shared.dart';

class NutritionManualFoodForm extends StatefulWidget {
  final ThemePalette colors;
  final ValueChanged<FoodEntry> onAdd;
  const NutritionManualFoodForm({super.key, required this.colors, required this.onAdd});

  @override
  State<NutritionManualFoodForm> createState() => _NutritionManualFoodFormState();
}

class _NutritionManualFoodFormState extends State<NutritionManualFoodForm> {
  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  String _mealType = 'breakfast';

  static const _mealTypeKeys = ['breakfast', 'lunch', 'snack', 'dinner'];

  @override
  void dispose() { _nameCtrl.dispose(); _gramsCtrl.dispose(); _kcalCtrl.dispose(); super.dispose(); }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final grams = int.tryParse(_gramsCtrl.text.trim()) ?? 0;
    final kcal = int.tryParse(_kcalCtrl.text.trim()) ?? 0;
    if (name.isEmpty || grams <= 0) return;
    widget.onAdd(FoodEntry(name: name, grams: grams, kcal: kcal, mealType: _mealType));
    _nameCtrl.clear(); _gramsCtrl.clear(); _kcalCtrl.clear();
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.textPrimary.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.addFoodManualTitle, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 14),
        SizedBox(
          height: 34,
          child: ListView(scrollDirection: Axis.horizontal, children: _mealTypeKeys.map((key) =>
            GestureDetector(
              onTap: () => setState(() => _mealType = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _mealType == key ? c.primary : c.elevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(localizedMealLabel(context, key),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: _mealType == key ? c.textOnPrimary : c.textMuted)),
              ),
            ),
          ).toList()),
        ),
        const SizedBox(height: 12),
        NutritionFormField(ctrl: _nameCtrl, hint: context.l10n.foodNameHint, icon: Icons.fastfood_rounded, colors: c, textInput: TextInputType.text),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: NutritionFormField(ctrl: _gramsCtrl, hint: context.l10n.gramsHint, icon: Icons.scale_rounded, colors: c, textInput: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: NutritionFormField(ctrl: _kcalCtrl, hint: context.l10n.caloriesHint, icon: Icons.local_fire_department_rounded, colors: c, textInput: TextInputType.number)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.add, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}
