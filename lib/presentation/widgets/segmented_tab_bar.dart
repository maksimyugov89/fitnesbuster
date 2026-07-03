import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

/// Pill-style tab strip that drives a [TabController].
///
/// Unlike [TabBar]'s built-in `indicator`, the highlight here is painted by
/// the same [Container] that lays out the label — so the pill can never be
/// smaller than the (auto-shrinking) text it contains.
class SegmentedTabBar extends StatefulWidget {
  final TabController controller;
  final List<String> labels;
  final EdgeInsetsGeometry padding;

  const SegmentedTabBar({
    super.key,
    required this.controller,
    required this.labels,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  State<SegmentedTabBar> createState() => _SegmentedTabBarState();
}

class _SegmentedTabBarState extends State<SegmentedTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    // Index tracks the animation's live position, so the highlight keeps up
    // during a swipe-driven TabBarView transition, not just on tap.
    final liveIndex =
        widget.controller.animation?.value.round() ?? widget.controller.index;

    return Padding(
      padding: widget.padding,
      child: Row(
        children: List.generate(widget.labels.length, (i) {
          final selected = i == liveIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.labels[i],
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      color: selected ? colors.primary : colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
