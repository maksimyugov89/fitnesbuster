import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({super.key});
  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  bool _loaded = false;
  List<_DayRecord> _days = [];

  // Aggregates (last 7 days)
  int _weekEaten = 0;
  int _weekTarget = 0;
  int _weekWater = 0;
  int _weekOnTargetDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settings = sl<ISettingsRepository>();
    final now = DateTime.now();
    final records = <_DayRecord>[];

    int weekEaten = 0, weekTarget = 0, weekWater = 0, weekOnTarget = 0;

    for (int i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final k = dateKey(d);

      final eaten = await settings.getEatenCal(k);
      final target = await settings.getTargetCal(k);
      final water = await settings.getWaterGlasses(k);

      // Manual foods for this day
      final rawFoods = await settings.getManualFoods(k);
      final foods = rawFoods.map((s) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          return _FoodItem(
            name: m['name'] as String? ?? '',
            grams: (m['grams'] as num?)?.toInt() ?? 0,
            kcal: (m['kcal'] as num?)?.toInt() ?? 0,
            mealType: m['type'] as String? ?? '',
          );
        } catch (_) { return null; }
      }).whereType<_FoodItem>().toList();

      // Completed meal plan meals
      final mealsDoneRaw = await settings.getMealsDone(k);
      final mealsDone = mealsDoneRaw.length;

      // Skip completely empty days (no data at all)
      if (eaten == 0 && water == 0 && foods.isEmpty && mealsDone == 0) {
        records.add(_DayRecord(date: d, eaten: 0, target: 0, waterGlasses: 0, foods: [], mealsDone: 0, hasData: false));
        continue;
      }

      records.add(_DayRecord(
        date: d,
        eaten: eaten,
        target: target,
        waterGlasses: water,
        foods: foods,
        mealsDone: mealsDone,
        hasData: true,
      ));

      if (i < 7) {
        weekEaten += eaten;
        weekTarget += target;
        weekWater += water;
        if (target > 0 && eaten > 0 && eaten <= target * 1.1) weekOnTarget++;
      }
    }

    if (mounted) {
      setState(() {
        _days = records;
        _weekEaten = weekEaten;
        _weekTarget = weekTarget;
        _weekWater = weekWater;
        _weekOnTargetDays = weekOnTarget;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Дневник питания', style: AppTextStyles.titleL),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.surfaceCard, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
          ),
        ),
      ),
      body: _loaded ? _buildBody(colors) : Center(child: CircularProgressIndicator(color: colors.primary)),
    );
  }

  Widget _buildBody(ThemePalette colors) {
    final activeDays = _days.where((d) => d.hasData).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [

        // ── Weekly summary card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.accentOrange.withValues(alpha: 0.85), colors.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('За 7 дней', style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _SummaryCell(label: 'Ккал съедено', value: '$_weekEaten', sub: _weekTarget > 0 ? 'цель ${_weekTarget ~/ 7}/д' : '', colors: colors)),
              Expanded(child: _SummaryCell(label: 'Дней в норме', value: '$_weekOnTargetDays / 7', sub: '', colors: colors)),
              Expanded(child: _SummaryCell(label: 'Стаканов воды', value: '$_weekWater', sub: '', colors: colors)),
            ]),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Stats strip ──────────────────────────────────────────────────────
        Row(children: [
          _StripStat(icon: '📅', label: 'Дней с данными', value: '$activeDays / 30', colors: colors),
          const SizedBox(width: 10),
          _StripStat(
            icon: '🔥',
            label: 'Ср. калории/день',
            value: activeDays > 0 ? '${(_weekEaten / 7).round()}' : '—',
            colors: colors,
          ),
        ]),

        const SizedBox(height: 20),

        // ── Day list ─────────────────────────────────────────────────────────
        Text('История питания', style: AppTextStyles.titleM),
        const SizedBox(height: 12),

        ..._days.map((day) => _DayTile(record: day, colors: colors)),
      ],
    );
  }
}

// ─── Day tile with expandable food list ──────────────────────────────────────

class _DayTile extends StatelessWidget {
  final _DayRecord record;
  final ThemePalette colors;
  const _DayTile({required this.record, required this.colors});

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(record.date.year, record.date.month, record.date.day);
    if (d == today) return 'Сегодня';
    if (d == yesterday) return 'Вчера';
    const months = ['','янв','фев','мар','апр','май','июн','июл','авг','сен','окт','ноя','дек'];
    return '${record.date.day} ${months[record.date.month]}';
  }

  Color _statusColor(ThemePalette c) {
    if (!record.hasData) return c.textMuted;
    if (record.target > 0 && record.eaten > record.target * 1.1) return c.error;
    if (record.eaten > 0) return c.success;
    return c.textMuted;
  }

  String get _statusLabel {
    if (!record.hasData) return '—';
    if (record.target > 0 && record.eaten > record.target * 1.1) return 'Превышение';
    if (record.eaten > 0 && record.target > 0) return 'В норме';
    if (record.eaten > 0) return 'Ок';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    if (!record.hasData) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.textPrimary.withValues(alpha: 0.04)),
          ),
          child: Row(children: [
            Text(_dateLabel, style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('Нет данных', style: TextStyle(fontSize: 12, color: colors.textMuted.withValues(alpha: 0.5))),
          ]),
        ),
      );
    }

    final progress = record.target > 0 ? (record.eaten / record.target).clamp(0.0, 1.2) : 0.0;
    final statusColor = _statusColor(colors);
    final canExpand = record.foods.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: canExpand
            ? ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                title: _tileHeader(statusColor, progress),
                iconColor: colors.textMuted,
                collapsedIconColor: colors.textMuted,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  ...record.foods.map((f) => _FoodRow(item: f, colors: colors)),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: _tileHeader(statusColor, progress),
              ),
      ),
    );
  }

  Widget _tileHeader(Color statusColor, double progress) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_dateLabel, style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(_statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Text('🍽️', style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(
          record.eaten > 0
              ? record.target > 0 ? '${record.eaten} / ${record.target} ккал' : '${record.eaten} ккал'
              : 'нет данных',
          style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text('💧', style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text('${record.waterGlasses} ст.', style: TextStyle(fontSize: 12, color: colors.info)),
        if (record.mealsDone > 0) ...[
          const SizedBox(width: 10),
          Text('✓ ${ record.mealsDone} приёма', style: TextStyle(fontSize: 11, color: colors.success)),
        ],
      ]),
      if (record.target > 0) ...[
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: colors.elevated,
            valueColor: AlwaysStoppedAnimation(
              record.eaten > record.target * 1.1 ? colors.error : statusColor,
            ),
          ),
        ),
      ],
    ]);
  }
}

class _FoodRow extends StatelessWidget {
  final _FoodItem item;
  final ThemePalette colors;
  const _FoodRow({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(Icons.restaurant_rounded, size: 14, color: colors.accentOrange),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${item.mealType} · ${item.grams}г', style: TextStyle(fontSize: 10, color: colors.textMuted)),
        ])),
        if (item.kcal > 0)
          Text('${item.kcal} ккал', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.accentOrange)),
      ]),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _SummaryCell extends StatelessWidget {
  final String label, value, sub;
  final ThemePalette colors;
  const _SummaryCell({required this.label, required this.value, required this.sub, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white60)),
    ]);
  }
}

class _StripStat extends StatelessWidget {
  final String icon, label, value;
  final ThemePalette colors;
  const _StripStat({required this.icon, required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
            Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          ])),
        ]),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _DayRecord {
  final DateTime date;
  final int eaten, target, waterGlasses, mealsDone;
  final List<_FoodItem> foods;
  final bool hasData;

  const _DayRecord({
    required this.date, required this.eaten, required this.target,
    required this.waterGlasses, required this.foods, required this.mealsDone,
    required this.hasData,
  });
}

class _FoodItem {
  final String name, mealType;
  final int grams, kcal;
  const _FoodItem({required this.name, required this.grams, required this.kcal, required this.mealType});
}
