import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class WorkoutLogScreen extends StatefulWidget {
  final String logId; // date key "YYYY_M_D" or workout id
  const WorkoutLogScreen({super.key, required this.logId});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _SetEntry {
  final int setNumber;
  final String reps;
  final double? weight;
  const _SetEntry({required this.setNumber, required this.reps, this.weight});
}

class _ExerciseLog {
  final String name;
  final List<_SetEntry> sets;
  const _ExerciseLog({required this.name, required this.sets});
}

// ── State ─────────────────────────────────────────────────────────────────────

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  bool _loaded = false;
  bool _workoutDone = false;
  int _kcal = 0;
  int _totalSets = 0;
  int _rating = 0;
  String _dateLabel = '';

  // Per-exercise logs from the session
  List<_ExerciseLog> _exerciseLogs = [];

  // Weekly summary
  int _weekDone = 0;
  int _weekKcal = 0;

  // Which exercise cards are expanded
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _resolveKey() {
    final datePattern = RegExp(r'^\d+_\d+_\d+$');
    if (datePattern.hasMatch(widget.logId)) return widget.logId;
    return todayKey();
  }

  Future<void> _loadData() async {
    final settings = sl<ISettingsRepository>();
    final key = _resolveKey();

    final done       = await settings.getWorkoutDone(key);
    final kcal       = await settings.getWorkoutKcal(key);
    final sets       = await settings.getWorkoutSets(key);
    final rating     = await settings.getWorkoutRating(key);
    final detailJson = await settings.getWorkoutLogDetail(key);
    final exerciseLogs = _parseSetLog(detailJson);

    final now = DateTime.now();
    int weekDone = 0;
    int weekKcal = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final k = dateKey(d);
      if (await settings.getWorkoutDone(k)) {
        weekDone++;
        weekKcal += await settings.getWorkoutKcal(k);
      }
    }

    if (mounted) {
      setState(() {
        _workoutDone  = done;
        _kcal         = kcal;
        _totalSets    = sets;
        _rating       = rating;
        _exerciseLogs = exerciseLogs;
        _weekDone     = weekDone;
        _weekKcal     = weekKcal;
        _dateLabel    = _formatDateLabel(key);
        _loaded       = true;
      });
    }
  }

  List<_ExerciseLog> _parseSetLog(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      // Group by exercise name preserving order
      final order = <String>[];
      final groups = <String, List<_SetEntry>>{};
      for (final item in list) {
        final map  = item as Map<String, dynamic>;
        final name = map['exercise'] as String? ?? '—';
        final set  = (map['set'] as num?)?.toInt() ?? 0;
        final reps = map['reps'] as String? ?? '—';
        final w    = (map['weight'] as num?)?.toDouble();
        if (!groups.containsKey(name)) {
          order.add(name);
          groups[name] = [];
        }
        groups[name]!.add(_SetEntry(setNumber: set, reps: reps, weight: w));
      }
      return order
          .map((name) => _ExerciseLog(name: name, sets: groups[name]!))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _formatDateLabel(String key) {
    final parts = key.split('_');
    if (parts.length != 3) return key;
    final d = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return AppLocalizations.tl('today');
    if (d == today.subtract(const Duration(days: 1))) return AppLocalizations.tl('yesterday');
    final months = [
      '', AppLocalizations.tl('janShort'), AppLocalizations.tl('febShort'),
      AppLocalizations.tl('marShort'), AppLocalizations.tl('aprShort'),
      AppLocalizations.tl('mayShort'), AppLocalizations.tl('junShort'),
      AppLocalizations.tl('julShort'), AppLocalizations.tl('augShort'),
      AppLocalizations.tl('sepShort'), AppLocalizations.tl('octShort'),
      AppLocalizations.tl('novShort'), AppLocalizations.tl('decShort'),
    ];
    return '${d.day} ${months[d.month]}';
  }

  Future<void> _saveRating(int r) async {
    await sl<ISettingsRepository>().setWorkoutRating(_resolveKey(), r);
    if (mounted) setState(() => _rating = r);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.workoutLogTitle, style: AppTextStyles.titleL),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_back_rounded,
                color: colors.textPrimary, size: 20),
          ),
        ),
      ),
      body: _loaded
          ? _buildBody(colors)
          : Center(
              child: CircularProgressIndicator(color: colors.primary)),
    );
  }

  Widget _buildBody(ThemePalette colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Hero card ──────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _workoutDone
                  ? [colors.primary, colors.primaryLight]
                  : [colors.surfaceCard, colors.elevated],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _workoutDone ? context.l10n.workoutDoneStatus3 : context.l10n.workoutNotDoneStatus,
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _workoutDone ? colors.textOnPrimary : colors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(_dateLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: _workoutDone ? colors.primaryDark : colors.textMuted)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _HeroStat(
                  label: context.l10n.kcalShort,
                  value: _kcal > 0 ? '$_kcal' : '—',
                  onPrimary: _workoutDone,
                  colors: colors),
              _HeroStat(
                  label: context.l10n.setsLabel,
                  value: _totalSets > 0 ? '$_totalSets' : '—',
                  onPrimary: _workoutDone,
                  colors: colors),
              _HeroStat(
                  label: context.l10n.exercisesLabel,
                  value: _exerciseLogs.isNotEmpty
                      ? '${_exerciseLogs.length}'
                      : '—',
                  onPrimary: _workoutDone,
                  colors: colors),
              _HeroStat(
                  label: context.l10n.setsCompletedLabel,
                  value: _workoutDone ? '✓' : '✗',
                  onPrimary: _workoutDone,
                  colors: colors),
            ]),
          ]),
        ),

        // ── Rating ────────────────────────────────────────────────────────────
        if (_workoutDone) ...[
          const SizedBox(height: 20),
          Text(context.l10n.rateWorkoutTitle, style: AppTextStyles.titleM),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final selected = _rating == i + 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _saveRating(i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 52,
                    margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? colors.primary
                            : colors.textPrimary.withValues(alpha: 0.06),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                          ['😞', '😐', '🙂', '💪', '🔥'][i],
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],

        // ── Per-exercise log ──────────────────────────────────────────────────
        if (_exerciseLogs.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(children: [
            Text(context.l10n.exercisesLabel, style: AppTextStyles.titleM),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                if (_expanded.length == _exerciseLogs.length) {
                  _expanded.clear();
                } else {
                  _expanded.addAll(_exerciseLogs.map((e) => e.name));
                }
              }),
              child: Text(
                _expanded.length == _exerciseLogs.length
                    ? context.l10n.collapseAll
                    : context.l10n.expandAll,
                style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ..._exerciseLogs.map((log) => _ExerciseLogCard(
                log: log,
                colors: colors,
                isExpanded: _expanded.contains(log.name),
                onToggle: () => setState(() {
                  if (_expanded.contains(log.name)) {
                    _expanded.remove(log.name);
                  } else {
                    _expanded.add(log.name);
                  }
                }),
              )),
        ] else if (_workoutDone) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colors.textPrimary.withValues(alpha: 0.06)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: colors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.detailLogNote,
                  style:
                      TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
            ]),
          ),
        ],

        // ── Week summary ──────────────────────────────────────────────────────
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.06)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.last7DaysTitle, style: AppTextStyles.titleM),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: _WeekStat(
                      icon: '💪',
                      label: context.l10n.taskWorkout,
                      value: '$_weekDone / 7',
                      colors: colors)),
              Expanded(
                  child: _WeekStat(
                      icon: '🔥',
                      label: context.l10n.kcalShort,
                      value: '$_weekKcal',
                      colors: colors)),
              Expanded(
                  child: _WeekStat(
                      icon: '📊',
                      label: context.l10n.setsCompletedLabel,
                      value: '${(_weekDone / 7 * 100).round()}%',
                      colors: colors)),
            ]),
          ]),
        ),

        // ── Tip ───────────────────────────────────────────────────────────────
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.accentPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: colors.accentPurple.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Text('💡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _workoutDone
                    ? context.l10n.greatJobMsg
                    : context.l10n.noWorryMsg,
                style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.5),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Exercise log card ────────────────────────────────────────────────────────

class _ExerciseLogCard extends StatelessWidget {
  final _ExerciseLog log;
  final ThemePalette colors;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExerciseLogCard({
    required this.log,
    required this.colors,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.fitness_center_rounded,
                        color: colors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.name,
                          style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary),
                        ),
                        Text(
                          '${log.sets.length} ${context.l10n.setsLabel}',
                          style: TextStyle(
                              fontSize: 11, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Summary: max weight or reps
                  _buildSummaryBadge(context),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),

            // Expanded: per-set table
            if (isExpanded) ...[
              Divider(
                  height: 1,
                  color: colors.textPrimary.withValues(alpha: 0.06)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: [
                    // Table header
                    Row(
                      children: [
                        _TableCell(context.l10n.setHeader, colors.textMuted,
                            flex: 1, bold: true),
                        _TableCell(context.l10n.repsHeader, colors.textMuted,
                            flex: 2, bold: true),
                        _TableCell(context.l10n.weightKgHeader, colors.textMuted,
                            flex: 2, bold: true, align: TextAlign.right),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...log.sets.asMap().entries.map((e) {
                      final s = e.value;
                      final isOdd = e.key.isOdd;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                            vertical: 7, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isOdd
                              ? colors.elevated.withValues(alpha: 0.5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _TableCell(
                                '${s.setNumber}', colors.textPrimary,
                                flex: 1),
                            _TableCell(s.reps, colors.textSecondary,
                                flex: 2),
                            _TableCell(
                              s.weight != null
                                  ? s.weight!.toStringAsFixed(
                                      s.weight! % 1 == 0 ? 0 : 1)
                                  : '—',
                              s.weight != null
                                  ? colors.primary
                                  : colors.textMuted,
                              flex: 2,
                              align: TextAlign.right,
                              bold: s.weight != null,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(BuildContext context) {
    final hasWeight = log.sets.any((s) => s.weight != null);
    if (!hasWeight) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          log.sets.isNotEmpty ? log.sets.first.reps : '—',
          style: TextStyle(fontSize: 11, color: colors.textMuted),
        ),
      );
    }
    final maxWeight =
        log.sets.where((s) => s.weight != null).map((s) => s.weight!).reduce(
              (a, b) => a > b ? a : b,
            );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.l10n.maxWeightLabel(maxWeight.toStringAsFixed(maxWeight % 1 == 0 ? 0 : 1)),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.primary),
      ),
    );
  }
}

// ─── Table cell helper ────────────────────────────────────────────────────────

class _TableCell extends StatelessWidget {
  final String text;
  final Color color;
  final int flex;
  final bool bold;
  final TextAlign align;

  const _TableCell(
    this.text,
    this.color, {
    this.flex = 1,
    this.bold = false,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color,
        ),
      ),
    );
  }
}

// ─── Stat widgets ─────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label, value;
  final bool onPrimary;
  final ThemePalette colors;
  const _HeroStat(
      {required this.label,
      required this.value,
      required this.onPrimary,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final textColor =
        onPrimary ? colors.textOnPrimary : colors.textPrimary;
    final labelColor =
        onPrimary ? colors.primaryDark : colors.textMuted;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: 10, color: labelColor)),
      const SizedBox(height: 2),
      Text(value,
          style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor)),
    ]);
  }
}

class _WeekStat extends StatelessWidget {
  final String icon, label, value;
  final ThemePalette colors;
  const _WeekStat(
      {required this.icon,
      required this.label,
      required this.value,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary)),
      Text(label,
          style: TextStyle(fontSize: 9, color: colors.textMuted),
          textAlign: TextAlign.center),
    ]);
  }
}
