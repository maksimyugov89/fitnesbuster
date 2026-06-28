import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

class BarcodeScanCard extends StatelessWidget {
  final VoidCallback onTap;

  const BarcodeScanCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Semantics(
      label: 'Сканировать штрих-код',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary.withValues(alpha: 0.9), colors.primary.withValues(alpha: 0.6)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Сканировать штрих-код', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Автоматически определим состав и КБЖУ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 16),
        ]),
      ),
    ),
  );
  }
}
