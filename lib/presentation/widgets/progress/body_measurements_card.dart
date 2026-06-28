import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/entities/body_measurement.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

class ProgressBodyMeasurementsDialog extends StatefulWidget {
  final Future<void> Function(BodyMeasurement) onSave;
  final UserProfile? profile;
  const ProgressBodyMeasurementsDialog({super.key, required this.onSave, this.profile});
  @override
  State<ProgressBodyMeasurementsDialog> createState() => _ProgressBodyMeasurementsDialogState();
}

class _ProgressBodyMeasurementsDialogState extends State<ProgressBodyMeasurementsDialog> {
  final _form = GlobalKey<FormState>();
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _hips = TextEditingController();
  final _fat = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _chest.dispose(); _waist.dispose(); _hips.dispose(); _fat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final m = BodyMeasurement(
      date: DateTime.now(),
      chestCm: _parseField(_chest.text),
      waistCm: _parseField(_waist.text),
      hipsCm: _parseField(_hips.text),
      bodyFatPercent: _parseField(_fat.text),
    );
    await widget.onSave(m);
    if (mounted) Navigator.pop(context);
  }

  double? _parseField(String s) => s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));

  void _calcBodyFat() {
    final p = widget.profile;
    if (p == null) return;
    final heightM = p.height / 100;
    final bmi = p.weight / (heightM * heightM);
    final bf = p.gender == Gender.male
        ? (1.20 * bmi) + (0.23 * p.age) - 16.2
        : (1.20 * bmi) + (0.23 * p.age) - 5.4;
    setState(() => _fat.text = bf.clamp(3, 50).toStringAsFixed(1));
  }

  Widget _buildField(String label, String unit, TextEditingController ctrl, ThemePalette colors, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: '$label ($unit)',
        labelStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        suffixText: unit,
        suffixStyle: TextStyle(color: colors.textMuted),
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          final d = double.tryParse(v.trim().replaceAll(',', '.'));
          if (d == null || d <= 0) return 'Введите корректное значение';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return AlertDialog(
      backgroundColor: colors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(children: [
        Icon(Icons.straighten_rounded, color: colors.primary, size: 22),
        const SizedBox(width: 8),
        Text('Замеры тела', style: TextStyle(color: colors.textPrimary, fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 18)),
      ]),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Введите актуальные значения.\nПустые поля будут пропущены.', style: TextStyle(fontSize: 12, color: colors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _buildField('Грудь', 'см', _chest, colors, Icons.circle_outlined),
            const SizedBox(height: 12),
            _buildField('Талия', 'см', _waist, colors, Icons.circle_outlined),
            const SizedBox(height: 12),
            _buildField('Бёдра', 'см', _hips, colors, Icons.circle_outlined),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildField('Жир тела', '%', _fat, colors, Icons.percent_rounded)),
              if (widget.profile != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Semantics(
                    label: 'Рассчитать',
                    button: true,
                    child: TextButton(
                      style: TextButton.styleFrom(
                      backgroundColor: colors.primary.withValues(alpha: 0.12),
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _calcBodyFat,
                    child: const Text('Рассчитать', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            if (widget.profile != null)
              Text('Расчёт по BMI (вес/рост/возраст/пол)', style: TextStyle(fontSize: 10, color: colors.textMuted)),
            const SizedBox(height: 8),
            Text('💡 Измеряйте сантиметровой лентой утром натощак в одних и тех же условиях',
              style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.5), textAlign: TextAlign.center),
          ]),
        ),
      ),
      actions: [
        Semantics(
          label: 'Отмена',
          button: true,
          child: TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text('Отмена', style: TextStyle(color: colors.textMuted))),
        ),
        Semantics(
          label: 'Сохранить',
          button: true,
          child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Сохранить'),
        ),
        ),
      ],
    );
  }
}
