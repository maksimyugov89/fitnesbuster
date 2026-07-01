import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

class NutritionFoodItemRow extends StatefulWidget {
  final String food;
  final ThemePalette colors;
  final Color mealColor;
  const NutritionFoodItemRow({
    super.key,
    required this.food,
    required this.colors,
    required this.mealColor,
  });

  @override
  State<NutritionFoodItemRow> createState() => _NutritionFoodItemRowState();
}

class _NutritionFoodItemRowState extends State<NutritionFoodItemRow> {
  bool _expanded = false;

  bool get _isComplex {
    final lower = widget.food.toLowerCase();
    const complexKeywords = [
      'суп',
      'рагу',
      'запеканка',
      'котлет',
      'тушен',
      'жарен',
      'варен',
      'пюре',
      'каша с',
      'рис с',
      'гречка с',
      'салат',
    ];
    return complexKeywords.any(lower.contains) &&
        widget.food.split(' ').length > 2;
  }

  String _getCookingHint() {
    final lower = widget.food.toLowerCase();
    if (lower.contains('суп'))
      return 'Отварите овощи и мясо в подсоленной воде, добавьте специи по вкусу. Варить 30–40 мин.';
    if (lower.contains('рагу') || lower.contains('тушен'))
      return 'Обжарьте ингредиенты, добавьте воду или бульон, тушите на медленном огне 25–35 мин.';
    if (lower.contains('запеканка'))
      return 'Смешайте ингредиенты, выложите в форму, запекайте при 180°C 35–45 мин до золотистой корочки.';
    if (lower.contains('котлет'))
      return 'Сформируйте котлеты, обваляйте в панировке, жарьте по 4–5 мин с каждой стороны.';
    if (lower.contains('каша') ||
        lower.contains('гречка') ||
        lower.contains('рис')) {
      return 'Промойте крупу, залейте водой 1:2, варите на медленном огне 15–20 мин. Посолите по вкусу.';
    }
    if (lower.contains('салат'))
      return 'Нарежьте ингредиенты, смешайте, заправьте маслом или соусом. Подавать свежим.';
    if (lower.contains('пюре'))
      return 'Отварите картофель/овощи, разомните с маслом или молоком до однородной консистенции.';
    return 'Приготовьте согласно рецепту. Следите за температурой и временем готовки для сохранения питательных веществ.';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final m = widget.mealColor;

    final gramMatch = RegExp(
      r'(\d+)\s*(г|гр|мл|ml|г\.?)(?:\s|$)',
      caseSensitive: false,
    ).firstMatch(widget.food);
    final qty = gramMatch?.group(0)?.trim().replaceAll('ml', 'мл') ?? '';
    final foodName = gramMatch != null
        ? widget.food
              .substring(0, gramMatch.start)
              .replaceAll(RegExp(r'[\s—\-]+$'), '')
              .trim()
        : widget.food;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: m),
              ),
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      foodName,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textPrimary,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (qty.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: m.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          qty,
                          style: TextStyle(
                            fontSize: 11,
                            color: m,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isComplex)
                Semantics(
                  label: 'Способ приготовления',
                  button: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.menu_book_rounded,
                        size: 18,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isComplex && _expanded) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 0, 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.elevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: m.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_rounded, size: 12, color: m),
                    const SizedBox(width: 4),
                    Text(
                      'Способ приготовления',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: m,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _getCookingHint(),
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
