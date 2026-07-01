import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/entities/personal_record.dart';
import 'package:fitnesbuster/data/repositories/pr_repository.dart';

class PrScreen extends StatefulWidget {
  const PrScreen({super.key});
  @override
  State<PrScreen> createState() => _PrScreenState();
}

class _PrScreenState extends State<PrScreen> {
  final _repo = PrRepository();
  bool _loading = true;
  Map<String, List<PersonalRecord>> _grouped = {};
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.getAll();
    if (mounted) {
      setState(() {
        _grouped = _repo.groupByExercise(all);
        _loading = false;
      });
    }
  }

  Future<void> _delete(PersonalRecord pr) async {
    await _repo.delete(pr.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final totalRecords = _grouped.values.fold(0, (s, list) => s + list.length);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, totalRecords),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _grouped.isEmpty
                  ? _buildEmpty(colors)
                  : _buildList(colors),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, colors),
        backgroundColor: colors.primary,
        foregroundColor: colors.textOnPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Добавить',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemePalette colors, int totalRecords) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Личные рекорды', style: AppTextStyles.displayM),
                Text(
                  totalRecords == 0
                      ? 'Нет записей'
                      : '$totalRecords записей · ${_grouped.length} упражнений',
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemePalette colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 56,
                color: colors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Нет личных рекордов',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Записывайте лучшие результаты после тренировок — вес, повторения, подходы.',
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddSheet(context, colors),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Добавить первый рекорд',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemePalette colors) {
    final exercises = _grouped.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: exercises.length,
      itemBuilder: (ctx, i) =>
          _buildExerciseCard(colors, exercises[i], _grouped[exercises[i]]!),
    );
  }

  Widget _buildExerciseCard(
    ThemePalette colors,
    String name,
    List<PersonalRecord> records,
  ) {
    final best = _repo.getBest(records)!;
    final isExpanded = _expanded.contains(name);
    final dateStr = DateFormat('d MMM yyyy', 'ru').format(best.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expanded.remove(name);
              } else {
                _expanded.add(name);
              }
            }),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (!best.isBodyweight) ...[
                              _Badge(
                                text: best.displayWeight,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (best.reps != null)
                              _Badge(
                                text: best.displayReps,
                                color: colors.success,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (records.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accentOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${records.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.accentOrange,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: colors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── History ──
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: colors.textPrimary.withValues(alpha: 0.06),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                children: [
                  ...records.map(
                    (pr) => _buildHistoryRow(colors, pr, pr.id == best.id),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          _showAddSheet(context, colors, prefilledName: name),
                      icon: Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                      label: Text(
                        'Добавить результат',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryRow(ThemePalette colors, PersonalRecord pr, bool isBest) {
    final dateStr = DateFormat('d MMM', 'ru').format(pr.date);
    return Dismissible(
      key: Key(pr.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colors.error,
          size: 20,
        ),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return await _confirmDelete(colors);
      },
      onDismissed: (_) => _delete(pr),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (isBest)
              const Text('🏆', style: TextStyle(fontSize: 14))
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                size: 14,
                color: colors.textMuted,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pr.summary.isNotEmpty ? pr.summary : '—',
                style: TextStyle(
                  fontSize: 13,
                  color: isBest ? colors.textPrimary : colors.textSecondary,
                  fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (pr.notes.isNotEmpty) ...[
              Icon(Icons.notes_rounded, size: 13, color: colors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              dateStr,
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(ThemePalette colors) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Удалить запись?',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Отмена',
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: colors.error),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showAddSheet(
    BuildContext context,
    ThemePalette colors, {
    String? prefilledName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddPrSheet(
        colors: colors,
        prefilledName: prefilledName,
        suggestions: _grouped.keys.toList()..sort(),
        onSave: (name, weight, reps, sets, notes) async {
          Navigator.pop(ctx);
          final messenger = ScaffoldMessenger.of(context);
          await _repo.add(
            exerciseName: name,
            weightKg: weight,
            reps: reps,
            sets: sets,
            notes: notes,
          );
          await _load();
          if (mounted) {
            setState(() => _expanded.add(name));
            messenger.showSnackBar(
              SnackBar(
                content: Text('Рекорд сохранён: $name'),
                backgroundColor: colors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// ─── Add PR bottom sheet ──────────────────────────────────────────────────────

class _AddPrSheet extends StatefulWidget {
  final ThemePalette colors;
  final String? prefilledName;
  final List<String> suggestions;
  final void Function(
    String name,
    double? weight,
    int? reps,
    int? sets,
    String notes,
  )
  onSave;

  const _AddPrSheet({
    required this.colors,
    required this.suggestions,
    required this.onSave,
    this.prefilledName,
  });

  @override
  State<_AddPrSheet> createState() => _AddPrSheetState();
}

class _AddPrSheetState extends State<_AddPrSheet> {
  late final TextEditingController _nameCtrl;
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _setsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prefilledName ?? '');
    _filteredSuggestions = widget.suggestions;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _setsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _filterSuggestions(String query) {
    setState(() {
      _filteredSuggestions = query.isEmpty
          ? widget.suggestions
          : widget.suggestions
                .where((s) => s.toLowerCase().contains(query.toLowerCase()))
                .toList();
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsCtrl.text);
    final sets = int.tryParse(_setsCtrl.text);
    HapticFeedback.mediumImpact();
    widget.onSave(name, weight, reps, sets, _notesCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.elevated,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Записать рекорд',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Введите упражнение и ваш лучший результат',
              style: TextStyle(fontSize: 12, color: c.textMuted),
            ),
            const SizedBox(height: 20),

            // Exercise name
            _SheetField(
              ctrl: _nameCtrl,
              hint: 'Упражнение',
              icon: Icons.fitness_center_rounded,
              colors: c,
              onChanged: _filterSuggestions,
            ),
            if (_filteredSuggestions.isNotEmpty &&
                _nameCtrl.text.isNotEmpty &&
                widget.prefilledName == null) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filteredSuggestions
                      .take(5)
                      .map(
                        (s) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _nameCtrl.text = s;
                              _filteredSuggestions = [];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Weight + Reps + Sets row
            Row(
              children: [
                Expanded(
                  child: _SheetField(
                    ctrl: _weightCtrl,
                    hint: 'Вес (кг)',
                    icon: Icons.monitor_weight_outlined,
                    colors: c,
                    inputType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetField(
                    ctrl: _repsCtrl,
                    hint: 'Повторения',
                    icon: Icons.repeat_rounded,
                    colors: c,
                    inputType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetField(
                    ctrl: _setsCtrl,
                    hint: 'Подходы',
                    icon: Icons.layers_rounded,
                    colors: c,
                    inputType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes
            _SheetField(
              ctrl: _notesCtrl,
              hint: 'Заметка (необязательно)',
              icon: Icons.notes_rounded,
              colors: c,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.emoji_events_rounded, size: 18),
                label: const Text(
                  'Сохранить рекорд',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helper widgets ────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final ThemePalette colors;
  final TextInputType inputType;
  final ValueChanged<String>? onChanged;

  const _SheetField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.colors,
    this.inputType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      onChanged: onChanged,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: colors.textMuted),
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

// ─── Lightweight PR log widget (used from workout done screen) ────────────────

class PrLogCard extends StatefulWidget {
  final List<String> exerciseNames;
  final ThemePalette colors;
  const PrLogCard({
    super.key,
    required this.exerciseNames,
    required this.colors,
  });

  @override
  State<PrLogCard> createState() => _PrLogCardState();
}

class _PrLogCardState extends State<PrLogCard> {
  final _repo = PrRepository();
  String? _selectedExercise;
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _setsCtrl = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseNames.isNotEmpty) {
      _selectedExercise = widget.exerciseNames.first;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _setsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedExercise == null) return;
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsCtrl.text);
    final sets = int.tryParse(_setsCtrl.text);
    if (weight == null && reps == null) return;
    HapticFeedback.mediumImpact();
    await _repo.add(
      exerciseName: _selectedExercise!,
      weightKg: weight,
      reps: reps,
      sets: sets,
    );
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    if (_saved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, color: c.success, size: 22),
            const SizedBox(width: 10),
            Text(
              'Рекорд сохранён!',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.textPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: c.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Записать личный рекорд',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise picker
          if (widget.exerciseNames.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.exerciseNames.map((name) {
                  final sel = name == _selectedExercise;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedExercise = name),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? c.primary : c.elevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? c.textOnPrimary : c.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else if (widget.exerciseNames.isNotEmpty)
            Text(
              _selectedExercise ?? '',
              style: TextStyle(fontSize: 12, color: c.textMuted),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MiniField(ctrl: _weightCtrl, hint: 'кг', colors: c),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniField(ctrl: _repsCtrl, hint: 'повт', colors: c),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniField(ctrl: _setsCtrl, hint: 'сетов', colors: c),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Записать',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final ThemePalette colors;
  const _MiniField({
    required this.ctrl,
    required this.hint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
