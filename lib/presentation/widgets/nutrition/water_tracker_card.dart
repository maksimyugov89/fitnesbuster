import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class WaterTrackerCard extends StatelessWidget {
  final int intakeMl;
  final int targetMl;
  final ValueChanged<int> onAdd;

  const WaterTrackerCard({
    super.key,
    required this.intakeMl,
    required this.targetMl,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final pct = targetMl > 0 ? (intakeMl / targetMl).clamp(0.0, 1.0) : 0.0;
    final done = pct >= 1.0;
    final intakeLiters = (intakeMl / 1000).toStringAsFixed(1);
    final targetLiters = (targetMl / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? c.info.withValues(alpha: 0.12) : c.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? c.info.withValues(alpha: 0.5) : c.info.withValues(alpha: 0.2),
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(done ? '✅' : '💧', key: ValueKey(done), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.tl('waterTitle'), style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: c.textPrimary)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  done
                      ? AppLocalizations.tl('goalReachedMsg')
                      : AppLocalizations.tlp('drankOf', {'intake': intakeLiters, 'target': targetLiters}),
                  key: ValueKey('$intakeMl/$targetMl'),
                  style: TextStyle(fontSize: 12, color: done ? c.info : c.textMuted),
                ),
              ),
            ]),
          ),
          if (intakeMl > 0)
            Semantics(
              label: '−200 ${AppLocalizations.tl('mlUnit')}',
              button: true,
              child: GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); onAdd(-200); },
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: c.elevated, borderRadius: BorderRadius.circular(8)),
                  child: Text('−200', style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: 14,
              child: LinearProgressIndicator(
                value: pct, minHeight: 14,
                backgroundColor: c.elevated,
                valueColor: AlwaysStoppedAnimation(done ? c.info : c.info.withValues(alpha: 0.8)),
              ),
            ),
          ),
          if (!done)
            Positioned.fill(
              child: Center(
                child: Text(
                  '${(pct * 100).toInt()}%',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.textOnPrimary),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _WaterBtn(ml: 100, label: '+100', c: c, onTap: () => onAdd(100)),
          const SizedBox(width: 8), _WaterBtn(ml: 200, label: '+200', c: c, onTap: () => onAdd(200)),
          const SizedBox(width: 8), _WaterBtn(ml: 300, label: '+300', c: c, onTap: () => onAdd(300)),
          const SizedBox(width: 8), _WaterBtn(ml: 500, label: '+500', c: c, onTap: () => onAdd(500)),
          const Spacer(),
          if (intakeMl > 0)
            Text(AppLocalizations.tlp('moreMl', {'ml': '${targetMl - intakeMl > 0 ? targetMl - intakeMl : 0}'}),
                style: TextStyle(fontSize: 12, color: c.textMuted)),
        ]),
      ]),
    );
  }
}

class _WaterBtn extends StatelessWidget {
  final int ml;
  final String label;
  final ThemePalette c;
  final VoidCallback onTap;
  const _WaterBtn({required this.ml, required this.label, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: c.elevated, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.info)),
      ),
    ),
  );
  }
}
