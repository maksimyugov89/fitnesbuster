import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class MealAlternativesTile extends StatefulWidget {
  final List<String> alternatives;
  final Color mealColor;

  const MealAlternativesTile({super.key, required this.alternatives, required this.mealColor});

  @override
  State<MealAlternativesTile> createState() => _MealAlternativesTileState();
}

class _MealAlternativesTileState extends State<MealAlternativesTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final m = widget.mealColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Divider(color: m.withValues(alpha: 0.12)),
        Semantics(
          label: context.l10n.replaceIngredientsLabel,
          button: true,
          child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: m.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.swap_horiz_rounded, size: 14, color: m),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.replaceIngredientsLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: m),
                ),
              ),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18, color: colors.textMuted),
            ]),
          ),
        ),
      ),
        if (_expanded) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: m.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: m.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.alternatives.map((alt) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 8),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: m.withValues(alpha: 0.7)),
                  ),
                  Expanded(child: Text(alt, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.45))),
                ]),
              )).toList(),
            ),
          ),
        ],
      ]),
    );
  }
}
