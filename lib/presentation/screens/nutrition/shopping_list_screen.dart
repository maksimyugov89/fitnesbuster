import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

// ── Category helpers ──────────────────────────────────────────────────────────

const _categoryOrder = [
  'Белки',
  'Молочные',
  'Крупы и злаки',
  'Овощи',
  'Фрукты',
  'Жиры и орехи',
  'Прочее',
];

String _categorize(String ingredient) {
  final lc = ingredient.toLowerCase();

  const proteins = ['курица', 'говяд', 'свинин', 'индейк', 'рыб', 'лосос', 'тунец', 'яйцо',
    'яйца', 'яиц', 'протеин', 'морепродукт', 'криветк', 'кальмар', 'треск', 'мясо'];
  const dairy = ['молоко', 'кефир', 'йогурт', 'творог', 'сыр', 'сметан'];
  const grains = ['рис', 'гречк', 'овсянк', 'овёс', 'паст', 'макарон', 'хлеб', 'батон',
    'картофел', 'картошк', 'хлопья', 'крупа', 'крупы', 'киноа', 'булгур', 'перловк'];
  const vegetables = ['огурец', 'огурц', 'помидор', 'томат', 'перец', 'капуст', 'брокколи',
    'шпинат', 'морков', 'салат', 'зелень', 'лук', 'чеснок', 'кабачок', 'баклажан',
    'свёкл', 'свекол', 'горошек', 'кукуруз', 'сельдер', 'петрушк', 'укроп', 'шампин'];
  const fruits = ['яблоко', 'яблок', 'банан', 'апельсин', 'ягода', 'черника', 'клубник',
    'виноград', 'груша', 'манго', 'киви', 'лимон', 'малина', 'смородин', 'арбуз'];
  const fats = ['масло', 'авокадо', 'орех', 'семена', 'миндаль', 'кешью', 'арахис',
    'грецк', 'фундук', 'оливк', 'льняно'];

  for (final kw in proteins) { if (lc.contains(kw)) return 'Белки'; }
  for (final kw in dairy)    { if (lc.contains(kw)) return 'Молочные'; }
  for (final kw in grains)   { if (lc.contains(kw)) return 'Крупы и злаки'; }
  for (final kw in vegetables) { if (lc.contains(kw)) return 'Овощи'; }
  for (final kw in fruits)   { if (lc.contains(kw)) return 'Фрукты'; }
  for (final kw in fats)     { if (lc.contains(kw)) return 'Жиры и орехи'; }
  return 'Прочее';
}

const _categoryEmoji = {
  'Белки':        '🥩',
  'Молочные':     '🥛',
  'Крупы и злаки': '🌾',
  'Овощи':        '🥦',
  'Фрукты':       '🍎',
  'Жиры и орехи': '🥑',
  'Прочее':       '🧂',
};

// ── Purchase group ─────────────────────────────────────────────────────────────

class _PurchaseGroup {
  final String mainItem;
  final List<String> swapOptions;
  const _PurchaseGroup({required this.mainItem, this.swapOptions = const []});
  bool get hasSwaps => swapOptions.isNotEmpty;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _loading = true;
  // category → list of purchase groups
  final Map<String, List<_PurchaseGroup>> _grouped = {};
  // can contain mainItem OR swap option text
  Set<String> _checked = {};
  // tracks which mainItems have swaps expanded
  final Set<String> _expanded = {};

  // Basket cost estimate
  String? _costNote;
  int? _costMin;
  int? _costMax;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadMealPlan(), _loadChecked()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMealPlan() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final plans = await sl<UserRepository>().getAiPlans(uid);
      final jsonStr = plans['mealPlan'];
      if (jsonStr == null) return;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final meals = (data['meals'] as List? ?? []).cast<Map<String, dynamic>>();

      // Parse basket_estimate
      final basketEstimate = data['basket_estimate'] as Map<String, dynamic>?;
      if (basketEstimate != null) {
        final minRub = basketEstimate['min_rub'];
        final maxRub = basketEstimate['max_rub'];
        final note = basketEstimate['note'];
        if (mounted) {
          setState(() {
            _costMin = minRub is int ? minRub : (minRub is double ? minRub.toInt() : null);
            _costMax = maxRub is int ? maxRub : (maxRub is double ? maxRub.toInt() : null);
            _costNote = note as String?;
          });
        }
      }

      // Parse alternatives from each meal
      final altRegex = RegExp(r'[Вв]место\s+([а-яА-ЯёЁ ]+?)\s*(?:→|->|:)\s*(.+)');

      // Build a map: stem → list of swap options
      final stemToSwaps = <String, List<String>>{};
      for (final meal in meals) {
        final alternatives = (meal['alternatives'] as List? ?? []).cast<String>();
        for (final altStr in alternatives) {
          final match = altRegex.firstMatch(altStr);
          if (match != null) {
            final keyword = match.group(1)!.trim();
            final stem = keyword.toLowerCase().length >= 6
                ? keyword.toLowerCase().substring(0, 6)
                : keyword.toLowerCase();
            final optionsText = match.group(2)!.trim();
            final options = optionsText
                .split(RegExp(r'\s+или\s+'))
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            if (options.isNotEmpty) {
              stemToSwaps.putIfAbsent(stem, () => []);
              for (final opt in options) {
                if (!stemToSwaps[stem]!.contains(opt)) {
                  stemToSwaps[stem]!.add(opt);
                }
              }
            }
          }
        }
      }

      // Collect all unique food items
      final allItems = <String>{};
      for (final meal in meals) {
        final foods = (meal['foods'] as List? ?? []).cast<String>();
        for (final f in foods) {
          final clean = f.trim();
          if (clean.isNotEmpty) allItems.add(clean);
        }
      }

      // Build groups with matched swap options
      final grouped = <String, List<_PurchaseGroup>>{};
      for (final item in allItems) {
        final cat = _categorize(item);
        List<String> matchedSwaps = [];
        for (final entry in stemToSwaps.entries) {
          if (item.toLowerCase().contains(entry.key)) {
            matchedSwaps = entry.value;
            break;
          }
        }
        grouped.putIfAbsent(cat, () => []).add(
          _PurchaseGroup(mainItem: item, swapOptions: matchedSwaps),
        );
      }

      // Sort within category alphabetically by mainItem
      for (final list in grouped.values) {
        list.sort((a, b) => a.mainItem.compareTo(b.mainItem));
      }

      if (mounted) setState(() => _grouped.addAll(grouped));
    } catch (e, st) {
      appLogger.w('ShoppingList: parse meal plan', error: e, stackTrace: st);
    }
  }

  Future<void> _loadChecked() async {
    final saved = await sl<ISettingsRepository>().getShoppingListChecked();
    if (mounted) setState(() => _checked = saved.toSet());
  }

  Future<void> _saveChecked() async {
    await sl<ISettingsRepository>().setShoppingListChecked(_checked.toList());
  }

  bool _isGroupBought(_PurchaseGroup g) =>
      _checked.contains(g.mainItem) || g.swapOptions.any(_checked.contains);

  void _toggleMain(_PurchaseGroup g) {
    setState(() {
      final wasChecked = _checked.contains(g.mainItem);
      for (final alt in g.swapOptions) { _checked.remove(alt); }
      if (wasChecked) {
        _checked.remove(g.mainItem);
      } else {
        _checked.add(g.mainItem);
      }
    });
    _saveChecked();
  }

  void _toggleAlt(_PurchaseGroup g, String alt) {
    setState(() {
      final wasChecked = _checked.contains(alt);
      _checked.remove(g.mainItem);
      for (final a in g.swapOptions) { _checked.remove(a); }
      if (!wasChecked) {
        _checked.add(alt);
      }
    });
    _saveChecked();
  }

  void _toggleExpand(String mainItem) {
    setState(() {
      if (_expanded.contains(mainItem)) {
        _expanded.remove(mainItem);
      } else {
        _expanded.add(mainItem);
      }
    });
  }

  void _resetAll() {
    setState(() {
      _checked.clear();
      _expanded.clear();
    });
    _saveChecked();
  }

  void _copyToClipboard() {
    final lines = <String>[];
    for (final cat in _categoryOrder) {
      final groups = _grouped[cat];
      if (groups == null || groups.isEmpty) continue;
      lines.add('${_categoryEmoji[cat] ?? ''} $cat:');
      for (final group in groups) {
        final bought = _isGroupBought(group);
        lines.add('  ${bought ? '✓' : '○'} ${group.mainItem}');
        if (group.hasSwaps) {
          lines.add('    или: ${group.swapOptions.join(' / ')}');
        }
      }
      lines.add('');
    }
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Список скопирован в буфер обмена')),
    );
  }

  int get _totalItems => _grouped.values.fold(0, (s, l) => s + l.length);
  int get _checkedCount =>
      _grouped.values.expand((l) => l).where(_isGroupBought).length;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Список покупок', style: AppTextStyles.titleL),
          if (!_loading && _totalItems > 0)
            Text('$_checkedCount / $_totalItems куплено', style: TextStyle(fontSize: 11, color: colors.textMuted)),
        ]),
        actions: [
          if (!_loading && _checkedCount > 0)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: colors.textMuted),
              tooltip: 'Сбросить',
              onPressed: _resetAll,
            ),
          IconButton(
            icon: Icon(Icons.copy_rounded, color: colors.textMuted),
            tooltip: 'Скопировать',
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grouped.isEmpty
              ? _buildEmpty(colors)
              : _buildList(colors),
    );
  }

  Widget _buildEmpty(ThemePalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🛒', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Список пуст',
            style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Сгенерируй AI-план питания,\nи ингредиенты появятся здесь',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildCostCard(ThemePalette colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.shopping_basket_rounded, color: colors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Примерная стоимость корзины',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'от $_costMin ₽ до $_costMax ₽ / неделю',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            if (_costNote != null && _costNote!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _costNote!,
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildList(ThemePalette colors) {
    final orderedCats = _categoryOrder.where((c) => _grouped.containsKey(c)).toList();

    // Progress bar at top
    final progress = _totalItems > 0 ? _checkedCount / _totalItems : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      children: [
        // Progress strip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
          ),
          child: Column(children: [
            Row(children: [
              Text('Куплено', style: TextStyle(fontSize: 12, color: colors.textMuted)),
              const Spacer(),
              Text(
                '$_checkedCount / $_totalItems',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.primary),
              ),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Cost estimate card (below progress bar)
        if (_costMin != null && _costMax != null) ...[
          _buildCostCard(colors),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 4),

        for (final cat in orderedCats) ...[
          _CategoryHeader(
            emoji: _categoryEmoji[cat] ?? '🍽️',
            label: cat,
            count: _grouped[cat]!.length,
            checkedCount: _grouped[cat]!.where(_isGroupBought).length,
            colors: colors,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: () {
                final groups = _grouped[cat]!;
                final widgets = <Widget>[];
                for (int i = 0; i < groups.length; i++) {
                  final group = groups[i];
                  final isLast = i == groups.length - 1;
                  final isChecked = _isGroupBought(group);
                  final isExpanded = _expanded.contains(group.mainItem);

                  widgets.add(
                    _ShoppingItem(
                      text: group.mainItem,
                      checked: isChecked,
                      colors: colors,
                      hasSwaps: group.hasSwaps,
                      isExpanded: isExpanded,
                      onToggle: () => _toggleMain(group),
                      onLongPress: () => _showSubstitution(group.mainItem),
                      onExpandTap: group.hasSwaps ? () => _toggleExpand(group.mainItem) : null,
                    ),
                  );

                  if (isExpanded && group.hasSwaps) {
                    for (int j = 0; j < group.swapOptions.length; j++) {
                      final alt = group.swapOptions[j];
                      widgets.add(
                        _SwapOptionItem(
                          text: alt,
                          checked: _checked.contains(alt),
                          colors: colors,
                          onToggle: () => _toggleAlt(group, alt),
                        ),
                      );
                    }
                  }

                  if (!isLast || (isExpanded && group.hasSwaps)) {
                    // Add divider after main item if not last, or after swap options
                  }
                  if (!isLast) {
                    widgets.add(
                      Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 56),
                    );
                  }
                }
                return widgets;
              }(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Hint
        Center(
          child: Text(
            '💡 Нажми ↔ чтобы выбрать замену · Долгое нажатие — спросить AI',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _showSubstitution(String ingredient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubstitutionSheet(ingredient: ingredient),
    );
  }
}

// ── Category header ────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final int checkedCount;
  final ThemePalette colors;

  const _CategoryHeader({
    required this.emoji,
    required this.label,
    required this.count,
    required this.checkedCount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = checkedCount == count && count > 0;
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: allDone ? colors.textMuted : colors.textPrimary,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        '$checkedCount/$count',
        style: TextStyle(fontSize: 11, color: colors.textMuted),
      ),
      if (allDone) ...[
        const SizedBox(width: 6),
        Icon(Icons.check_circle_rounded, size: 14, color: colors.success),
      ],
    ]);
  }
}

// ── Shopping item ─────────────────────────────────────────────────────────────

class _ShoppingItem extends StatelessWidget {
  final String text;
  final bool checked;
  final ThemePalette colors;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;
  final bool hasSwaps;
  final bool isExpanded;
  final VoidCallback? onExpandTap;

  const _ShoppingItem({
    required this.text,
    required this.checked,
    required this.colors,
    required this.onToggle,
    required this.onLongPress,
    this.hasSwaps = false,
    this.isExpanded = false,
    this.onExpandTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: checked ? colors.primary : colors.textMuted.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: checked
                ? Icon(Icons.check_rounded, size: 14, color: colors.textOnPrimary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: checked ? colors.textMuted : colors.textPrimary,
                decoration: checked ? TextDecoration.lineThrough : null,
                decorationColor: colors.textMuted,
              ),
            ),
          ),
          if (hasSwaps)
            GestureDetector(
              onTap: onExpandTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: colors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else
            Icon(Icons.more_horiz_rounded, size: 16, color: colors.textMuted.withValues(alpha: 0.4)),
        ]),
      ),
    );
  }
}

// ── Swap option item ──────────────────────────────────────────────────────────

class _SwapOptionItem extends StatelessWidget {
  final String text;
  final bool checked;
  final ThemePalette colors;
  final VoidCallback onToggle;

  const _SwapOptionItem({
    required this.text,
    required this.checked,
    required this.colors,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: colors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.only(left: 52, right: 16, top: 9, bottom: 9),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: checked ? colors.primary.withValues(alpha: 0.8) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked
                      ? colors.primary.withValues(alpha: 0.8)
                      : colors.textMuted.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? Icon(Icons.check_rounded, size: 11, color: colors.textOnPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              'или: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.primary.withValues(alpha: 0.7),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: checked ? colors.textMuted : colors.textPrimary.withValues(alpha: 0.75),
                  decoration: checked ? TextDecoration.lineThrough : null,
                  decorationColor: colors.textMuted,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Substitution bottom sheet ─────────────────────────────────────────────────

class _SubstitutionSheet extends StatefulWidget {
  final String ingredient;
  const _SubstitutionSheet({required this.ingredient});

  @override
  State<_SubstitutionSheet> createState() => _SubstitutionSheetState();
}

class _SubstitutionSheetState extends State<_SubstitutionSheet> {
  bool _loading = true;
  String _result = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ai = sl<DeepSeekService>();
      // Strip portion info (e.g. "Куриное филе 150г — Основной белок" → "Куриное филе")
      final cleanName = widget.ingredient
          .replaceAll(RegExp(r'\s*\d+\s*(г|гр|мл|л|кг|шт)[^а-яА-Я]*'), '')
          .replaceAll(RegExp(r'\s*—.*'), '')
          .trim();

      final answer = await ai.askQuestion(
        'Предложи 3–4 замены ингредиента «$cleanName» с сохранением похожего питательного состава. '
        'Для каждой замены укажи: название, примерный эквивалент по граммам и краткое пояснение (1 фраза). '
        'Ответ давай кратко, по одной замене на строку, без лишних слов.',
      );
      if (mounted) setState(() { _loading = false; _result = answer.trim(); });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Ошибка AI: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Text('🔄', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Замена ингредиента', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              const SizedBox(height: 2),
              Text(widget.ingredient, style: TextStyle(fontSize: 12, color: colors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),

        const SizedBox(height: 16),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        const SizedBox(height: 16),

        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, style: TextStyle(color: colors.error, fontSize: 14)),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(_result, style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.6)),
            ),
          ),
      ]),
    );
  }
}
