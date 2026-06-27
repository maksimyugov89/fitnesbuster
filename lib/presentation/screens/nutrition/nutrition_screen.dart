import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/data/models/ai_meal_plan.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/barcode_scanner_screen.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Meal plan ──────────────────────────────────────────────────────────────
  bool _mealLoading = true;
  List<Map<String, dynamic>> _meals = [];
  List<String> _mealRecs = [];
  int _targetCal = 0;

  // Which meals the user has marked as done
  final Set<int> _completedMeals = {};

  // ── Supplements ───────────────────────────────────────────────────────────
  List<AiSupplement> _supplements = [];

  // ── Water tracker ──────────────────────────────────────────────────────────
  int _waterIntakeMl = 0;
  int _waterTargetMl = 2500;

  // ── Manually added food ────────────────────────────────────────────────────
  final List<_FoodEntry> _addedFoods = [];

  static const _mealIcons = {
    'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍎',
    'pre_workout': '🏋️', 'post_workout': '💪', 'evening_snack': '🌛',
    'morning_snack': '🌤️',
  };
  static const _mealLabels = {
    'breakfast': 'Завтрак', 'lunch': 'Обед', 'dinner': 'Ужин', 'snack': 'Перекус',
    'pre_workout': 'Предтрен', 'post_workout': 'Послетрен', 'evening_snack': 'Веч. перекус',
    'morning_snack': 'Утр. перекус',
  };
  static const _mealColors = {
    'breakfast': Color(0xFFFFAB40),
    'lunch': Color(0xFF26C6DA),
    'dinner': Color(0xFF7E57C2),
    'snack': Color(0xFF66BB6A),
    'pre_workout': Color(0xFFEF5350),
    'post_workout': Color(0xFFFF7043),
    'evening_snack': Color(0xFFAB47BC),
    'morning_snack': Color(0xFF42A5F5),
  };

  // ── Calories ───────────────────────────────────────────────────────────────
  int get _planCaloriesEaten =>
      _completedMeals.fold(0, (s, i) => i < _meals.length ? s + ((_meals[i]['calories'] as num?)?.toInt() ?? 0) : s);
  int get _manualCaloriesEaten => _addedFoods.fold(0, (s, f) => s + f.kcal);
  int get _totalEaten => _planCaloriesEaten + _manualCaloriesEaten;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadMealPlan();
    _loadAddedFoods();
    _loadWater();
  }


  // ── Water persistence ─────────────────────────────────────────────────────
  Future<void> _loadWater() async {
    final ml = await sl<ISettingsRepository>().getWaterMl(todayKey());
    if (mounted) setState(() => _waterIntakeMl = ml);
  }

  Future<void> _addWater(int ml) async {
    final next = (_waterIntakeMl + ml).clamp(0, _waterTargetMl * 2);
    setState(() => _waterIntakeMl = next);
    await sl<ISettingsRepository>().setWaterMl(todayKey(), next);
  }

  String _normalizeMealType(String raw) => raw.replaceAll(' ', '').toLowerCase();

  // ── Persist completion + eaten calories ───────────────────────────────────
  Future<void> _saveProgress() async {
    final settings = sl<ISettingsRepository>();
    final k = todayKey();
    await settings.setMealsDone(k, _completedMeals.map((i) => '$i').toList());
    await settings.setEatenCal(k, _totalEaten);
    if (_targetCal > 0) await settings.setTargetCal(k, _targetCal);
    final foods = _addedFoods.map((f) => jsonEncode({'name': f.name, 'grams': f.grams, 'kcal': f.kcal, 'type': f.mealType})).toList();
    await settings.setManualFoods(k, foods);
  }

  Future<void> _loadMealCompletion() async {
    final k = todayKey();
    final raw = await sl<ISettingsRepository>().getMealsDone(k);
    final done = raw.map((s) => int.tryParse(s)).whereType<int>().where((i) => i < _meals.length).toSet();
    if (mounted && done.isNotEmpty) setState(() => _completedMeals.addAll(done));
  }

  Future<void> _loadAddedFoods() async {
    final k = todayKey();
    final raw = await sl<ISettingsRepository>().getManualFoods(k);
    final foods = raw.map((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return _FoodEntry(name: m['name'] as String, grams: (m['grams'] as num).toInt(), kcal: (m['kcal'] as num).toInt(), mealType: m['type'] as String);
      } catch (_) { return null; }
    }).whereType<_FoodEntry>().toList();
    if (mounted && foods.isNotEmpty) setState(() => _addedFoods.addAll(foods));
  }

  Future<void> _loadMealPlan() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthStateAuthenticated) {
        if (mounted) { setState(() => _mealLoading = false); }
        return;
      }
      final uid = authState.userId;
      final plans = await sl<UserRepository>().getAiPlans(uid);
      final jsonStr = plans['mealPlan'];
      if (jsonStr == null) {
        if (mounted) { setState(() => _mealLoading = false); }
        return;
      }
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final meals = (data['meals'] as List).cast<Map<String, dynamic>>();
      final water = (data['water_target_ml'] as num?)?.toInt() ?? 2500;
      final recs = (data['recommendations'] as List? ?? data['daily_tips'] as List? ?? []).cast<String>();
      final totalCal = meals.fold(0, (s, m) => s + ((m['calories'] as num?)?.toInt() ?? 0));
      final suppsRaw = data['supplements'] as List? ?? [];
      final supplements = suppsRaw
          .whereType<Map<String, dynamic>>()
          .map(AiSupplement.fromJson)
          .toList();
      if (mounted) {
        setState(() {
          _mealLoading = false;
          _meals = meals;
          _waterTargetMl = water;
          _mealRecs = recs;
          _targetCal = totalCal;
          _supplements = supplements;
        });
      }
      // Load which meals were completed today AFTER meals list is set
      await _loadMealCompletion();
    } catch (_) {
      if (mounted) { setState(() => _mealLoading = false); }
    }
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && mounted) {
      final entry = _FoodEntry(
        name: result['name'] as String,
        grams: result['grams'] as int,
        kcal: result['kcal'] as int,
        mealType: result['mealType'] as String,
      );
      setState(() => _addedFoods.insert(0, entry));
      await _saveProgress();
    }
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(colors),
          _buildCompactCalories(colors),
          TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: colors.primary,
            unselectedLabelColor: colors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter'),
            tabs: const [Tab(text: 'На сегодня'), Tab(text: 'На неделю'), Tab(text: 'Добавить еду')],
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: TabBarView(controller: _tabCtrl, children: [
              _buildMealPlan(colors),
              _buildWeeklyPlan(colors),
              _buildAddFood(colors),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemePalette colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        const Text('Питание', style: AppTextStyles.displayM),
        const Spacer(),
        if (_completedMeals.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Text('${_completedMeals.length}/${_meals.length} приёмов', style: TextStyle(fontSize: 11, color: colors.success, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push(AppRouter.shoppingList),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🛒', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('Покупки', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.accentOrange)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── Compact calorie strip ────────────────────────────────────────────────

  Widget _buildCompactCalories(ThemePalette colors) {
    final progress = _targetCal > 0 ? (_totalEaten / _targetCal).clamp(0.0, 1.0) : 0.0;
    final remaining = (_targetCal - _totalEaten).clamp(0, _targetCal);
    final isOverLimit = _totalEaten > _targetCal && _targetCal > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            isOverLimit ? '⚠️ Превышено: $_totalEaten ккал' : '🍽️ Съедено: $_totalEaten ккал',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: isOverLimit ? colors.error : colors.textPrimary),
          ),
          const Spacer(),
          Text(
            _targetCal > 0 ? 'Цель: $_targetCal ккал' : 'Загрузка...',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colors.elevated,
            valueColor: AlwaysStoppedAnimation(isOverLimit ? colors.error : colors.primary),
          ),
        ),
        if (_targetCal > 0) ...[
          const SizedBox(height: 6),
          Row(children: [
            _CompactMacro(label: 'Осталось', value: '$remaining ккал', color: colors.textMuted),
            const Spacer(),
            if (_addedFoods.isNotEmpty)
              _CompactMacro(label: 'Доп. еда', value: '+$_manualCaloriesEaten ккал', color: colors.accentOrange),
          ]),
        ],
      ]),
    );
  }

  // ─── Meal Plan Tab ────────────────────────────────────────────────────────

  Widget _buildMealPlan(ThemePalette colors) {
    if (_mealLoading) return const Center(child: CircularProgressIndicator());
    if (_meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.restaurant_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text('ИИ-план питания не сгенерирован.\nПройдите онбординг и создайте план питания.',
              style: TextStyle(fontSize: 14, color: colors.textMuted, height: 1.5), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Progress bar across all meals
        _buildMealProgress(colors),
        const SizedBox(height: 16),

        // Meal cards
        ..._meals.asMap().entries.map((e) => _buildMealCard(colors, e.key, e.value)),
        const SizedBox(height: 4),

        // Water card
        _WaterCard(
          intakeMl: _waterIntakeMl,
          targetMl: _waterTargetMl,
          colors: colors,
          onAdd: _addWater,
        ),
        const SizedBox(height: 16),

        // Supplements
        if (_supplements.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Спортивное питание', style: AppTextStyles.titleM),
          const SizedBox(height: 10),
          ..._supplements.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentPurple.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.accentPurple.withValues(alpha: 0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(s.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary), overflow: TextOverflow.ellipsis)),
                  if (s.dose.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: colors.accentPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(s.dose, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.accentPurple)),
                    ),
                  ],
                ]),
                if (s.timing.isNotEmpty) Text(s.timing, style: TextStyle(fontSize: 11, color: colors.textMuted)),
                if (s.purpose.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(s.purpose, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35)),
                ],
              ])),
            ]),
          )),
        ],

        // Recommendations
        if (_mealRecs.isNotEmpty) ...[
          const Text('Советы по питанию', style: AppTextStyles.titleM),
          const SizedBox(height: 10),
          ..._mealRecs.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.primary)),
              Expanded(child: Text(rec, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.45))),
            ]),
          )),
        ],
      ],
    );
  }

  Widget _buildMealProgress(ThemePalette colors) {
    if (_meals.isEmpty) return const SizedBox.shrink();
    return Row(
      children: _meals.asMap().entries.map((e) {
        final isDone = _completedMeals.contains(e.key);
        final type = _normalizeMealType(e.value['type'] as String? ?? '');
        final mealColor = _mealColors[type] ?? colors.primary;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(children: [
              Text(_mealIcons[type] ?? '🍽️', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isDone ? mealColor : colors.elevated,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMealCard(ThemePalette colors, int index, Map<String, dynamic> meal) {
    final type = _normalizeMealType(meal['type'] as String? ?? '');
    final time = meal['time'] as String? ?? '';
    final foods = (meal['foods'] as List? ?? []).cast<String>();
    final cal = (meal['calories'] as num?)?.toInt() ?? 0;
    final icon = _mealIcons[type] ?? '🍽️';
    final label = _mealLabels[type] ?? type;
    final mealColor = _mealColors[type] ?? colors.primary;
    final isDone = _completedMeals.contains(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDone ? mealColor.withValues(alpha: 0.08) : colors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? mealColor.withValues(alpha: 0.5) : colors.textPrimary.withValues(alpha: 0.06),
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: mealColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                Text(time, style: TextStyle(fontSize: 12, color: colors.textMuted)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: mealColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('$cal ккал', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: mealColor)),
              ),
              if (isDone) Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: mealColor),
                  const SizedBox(width: 3),
                  Text('Выполнено', style: TextStyle(fontSize: 10, color: mealColor, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ]),
        ),

        // ── Foods list ──
        if (foods.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: foods.map((food) => _FoodItemRow(food: food, colors: colors, mealColor: mealColor)).toList(),
            ),
          ),
        ],

        // ── Macros per meal ──
        Builder(builder: (ctx) {
          final macroRaw = meal['macros'] as Map<String, dynamic>? ?? meal['macro_breakdown'] as Map<String, dynamic>?;
          if (macroRaw == null) return const SizedBox.shrink();
          final macros = MealMacros.fromJson(macroRaw);
          if (macros.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(color: mealColor.withValues(alpha: 0.12)),
              Row(children: [
                _NutritionChip(label: 'Б', value: '${macros.protein}г', color: mealColor),
                const SizedBox(width: 8),
                _NutritionChip(label: 'У', value: '${macros.carbs}г', color: mealColor),
                const SizedBox(width: 8),
                _NutritionChip(label: 'Ж', value: '${macros.fat}г', color: mealColor),
                if (macros.fiber > 0) ...[
                  const SizedBox(width: 8),
                  _NutritionChip(label: 'Кл', value: '${macros.fiber}г', color: mealColor),
                ],
              ]),
              const SizedBox(height: 8),
            ]),
          );
        }),

        // ── Alternatives ──
        Builder(builder: (ctx) {
          final altsRaw = meal['alternatives'] as List?;
          if (altsRaw == null || altsRaw.isEmpty) return const SizedBox.shrink();
          final alts = altsRaw.cast<String>();
          return _AlternativesWidget(alternatives: alts, mealColor: mealColor, colors: colors);
        }),

        // ── Complete button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: isDone
                ? OutlinedButton.icon(
                    onPressed: () { HapticFeedback.lightImpact(); setState(() => _completedMeals.remove(index)); _saveProgress(); },
                    icon: Icon(Icons.undo_rounded, size: 16, color: mealColor),
                    label: Text('Отменить', style: TextStyle(fontSize: 13, color: mealColor, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: mealColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () { HapticFeedback.mediumImpact(); setState(() => _completedMeals.add(index)); _saveProgress(); },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Приём пищи выполнен', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: mealColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  // ─── Weekly Plan Tab ──────────────────────────────────────────────────────

  Widget _buildWeeklyPlan(ThemePalette colors) {
    if (_mealLoading) return const Center(child: CircularProgressIndicator());
    if (_meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_today_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text('Создайте план питания в онбординге,\nчтобы видеть недельное меню.',
              style: TextStyle(fontSize: 14, color: colors.textMuted, height: 1.5), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    // Build a 7-day plan: repeat the daily meals across the week with day labels
    const dayNames = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    final today = DateTime.now().weekday - 1; // 0=Mon, 6=Sun

    // Aggregate unique foods (shopping list)
    final shoppingList = <String>{};
    for (final meal in _meals) {
      final foods = (meal['foods'] as List? ?? []).cast<String>();
      for (final f in foods) {
        // Keep only the product name (first comma-separated part)
        shoppingList.add(f.split(',').first.trim());
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Week overview header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary.withValues(alpha: 0.8), colors.accentPurple.withValues(alpha: 0.6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Text('📅', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Недельный план питания',
                  style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Ежедневный рацион · $_targetCal ккал/день',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // 7-day list
        ...List.generate(7, (i) {
          final dayIdx = (today + i) % 7;
          final label = dayNames[dayIdx];
          final isToday = i == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isToday ? colors.primary.withValues(alpha: 0.08) : colors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday ? colors.primary.withValues(alpha: 0.4) : colors.textPrimary.withValues(alpha: 0.06),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Row(children: [
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Сегодня', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                if (isToday) const SizedBox(width: 8),
                Expanded(child: Text(label,
                    style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700,
                        color: isToday ? colors.primary : colors.textPrimary))),
                Text('$_targetCal ккал',
                    style: TextStyle(fontSize: 12, color: colors.textMuted, fontWeight: FontWeight.w600)),
              ]),
              initiallyExpanded: isToday,
              iconColor: colors.textMuted,
              collapsedIconColor: colors.textMuted,
              children: _meals.map((meal) {
                final type = _normalizeMealType(meal['type'] as String? ?? '');
                final time = meal['time'] as String? ?? '';
                final foods = (meal['foods'] as List? ?? []).cast<String>();
                final cal = (meal['calories'] as num?)?.toInt() ?? 0;
                final icon = _mealIcons[type] ?? '🍽️';
                final label2 = _mealLabels[type] ?? type;
                final mealColor = _mealColors[type] ?? colors.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: mealColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(label2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                        const Spacer(),
                        Text('$cal ккал', style: TextStyle(fontSize: 11, color: mealColor, fontWeight: FontWeight.w700)),
                      ]),
                      Text(time, style: TextStyle(fontSize: 10, color: colors.textMuted)),
                      if (foods.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(foods.take(3).join(', ') + (foods.length > 3 ? '...' : ''),
                            style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4)),
                      ],
                    ])),
                  ]),
                );
              }).toList(),
            ),
          );
        }),

        const SizedBox(height: 20),

        // Shopping list section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.success.withValues(alpha: 0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🛒', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('Список покупок на неделю',
                  style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: shoppingList.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                ),
                child: Text(item, style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ]),
        ),
      ],
    );
  }

  // ─── Add Food Tab ─────────────────────────────────────────────────────────

  Widget _buildAddFood(ThemePalette colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Barcode scan
        _buildBarcodeCard(colors),
        const SizedBox(height: 16),

        // Manual entry
        _ManualFoodForm(
          colors: colors,
          onAdd: (entry) { setState(() => _addedFoods.insert(0, entry)); _saveProgress(); },
        ),
        const SizedBox(height: 20),

        // Added foods list
        if (_addedFoods.isNotEmpty) ...[
          Row(children: [
            const Text('Добавленная еда', style: AppTextStyles.titleM),
            const Spacer(),
            Text('$_manualCaloriesEaten ккал', style: TextStyle(fontSize: 13, color: colors.accentOrange, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ..._addedFoods.asMap().entries.map((e) => _AddedFoodTile(
            entry: e.value,
            colors: colors,
            onDelete: () { setState(() => _addedFoods.removeAt(e.key)); _saveProgress(); },
          )),
        ],
      ],
    );
  }

  Widget _buildBarcodeCard(ThemePalette colors) {
    return GestureDetector(
      onTap: _openBarcodeScanner,
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
    );
  }
}

// ─── Food item row with gram parsing ─────────────────────────────────────────

class _FoodItemRow extends StatefulWidget {
  final String food;
  final ThemePalette colors;
  final Color mealColor;
  const _FoodItemRow({required this.food, required this.colors, required this.mealColor});

  @override
  State<_FoodItemRow> createState() => _FoodItemRowState();
}

class _FoodItemRowState extends State<_FoodItemRow> {
  bool _expanded = false;

  bool get _isComplex {
    final lower = widget.food.toLowerCase();
    const complexKeywords = ['суп', 'рагу', 'запеканка', 'котлет', 'тушен', 'жарен', 'варен', 'пюре', 'каша с', 'рис с', 'гречка с', 'салат'];
    return complexKeywords.any(lower.contains) && widget.food.split(' ').length > 2;
  }

  String _getCookingHint() {
    final lower = widget.food.toLowerCase();
    if (lower.contains('суп')) return 'Отварите овощи и мясо в подсоленной воде, добавьте специи по вкусу. Варить 30–40 мин.';
    if (lower.contains('рагу') || lower.contains('тушен')) return 'Обжарьте ингредиенты, добавьте воду или бульон, тушите на медленном огне 25–35 мин.';
    if (lower.contains('запеканка')) return 'Смешайте ингредиенты, выложите в форму, запекайте при 180°C 35–45 мин до золотистой корочки.';
    if (lower.contains('котлет')) return 'Сформируйте котлеты, обваляйте в панировке, жарьте по 4–5 мин с каждой стороны.';
    if (lower.contains('каша') || lower.contains('гречка') || lower.contains('рис')) {
      return 'Промойте крупу, залейте водой 1:2, варите на медленном огне 15–20 мин. Посолите по вкусу.';
    }
    if (lower.contains('салат')) return 'Нарежьте ингредиенты, смешайте, заправьте маслом или соусом. Подавать свежим.';
    if (lower.contains('пюре')) return 'Отварите картофель/овощи, разомните с маслом или молоком до однородной консистенции.';
    return 'Приготовьте согласно рецепту. Следите за температурой и временем готовки для сохранения питательных веществ.';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final m = widget.mealColor;

    // Parse quantity from food string (e.g. "Овсянка — 150г" or "Куриная грудка 200г")
    final gramMatch = RegExp(r'(\d+)\s*(г|гр|мл|ml|г\.?)(?:\s|$)', caseSensitive: false).firstMatch(widget.food);
    final qty = gramMatch?.group(0)?.trim().replaceAll('ml', 'мл') ?? '';
    final foodName = gramMatch != null
        ? widget.food.substring(0, gramMatch.start).replaceAll(RegExp(r'[\s—\-]+$'), '').trim()
        : widget.food;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: m),
          ),
          Expanded(
            child: Wrap(children: [
              Text(foodName, style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.4, fontWeight: FontWeight.w500)),
              if (qty.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: m.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(qty, style: TextStyle(fontSize: 11, color: m, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ),
          if (_isComplex)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.menu_book_rounded,
                  size: 18, color: c.textMuted),
              ),
            ),
        ]),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.restaurant_rounded, size: 12, color: m),
              const SizedBox(width: 4),
              Text('Способ приготовления', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: m)),
            ]),
            const SizedBox(height: 6),
            Text(_getCookingHint(), style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.5)),
          ]),
        ),
      ],
    ]);
  }
}

// ─── Water card ───────────────────────────────────────────────────────────────

class _WaterCard extends StatelessWidget {
  final int intakeMl;
  final int targetMl;
  final ThemePalette colors;
  final ValueChanged<int> onAdd;

  const _WaterCard({
    required this.intakeMl,
    required this.targetMl,
    required this.colors,
    required this.onAdd,
  });

  static const _quickAmounts = [100, 200, 500];

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final pct = targetMl > 0 ? (intakeMl / targetMl).clamp(0.0, 1.0) : 0.0;
    final remaining = (targetMl - intakeMl).clamp(0, targetMl);
    final done = intakeMl >= targetMl;
    final intakeLiters = (intakeMl / 1000).toStringAsFixed(1);
    final targetLiters = (targetMl / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done
            ? c.info.withValues(alpha: 0.12)
            : c.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? c.info.withValues(alpha: 0.5)
              : c.info.withValues(alpha: 0.2),
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(done ? '✅' : '💧',
                key: ValueKey(done), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Вода', style: TextStyle(
                  fontFamily: 'Syne', fontSize: 15,
                  fontWeight: FontWeight.w800, color: c.textPrimary)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  done
                      ? 'Цель достигнута!'
                      : 'Выпито $intakeLiters л из $targetLiters л',
                  key: ValueKey('$intakeMl/$targetMl'),
                  style: TextStyle(fontSize: 12, color: done ? c.info : c.textMuted),
                ),
              ),
            ]),
          ),
          // Undo last 200 ml
          if (intakeMl > 0)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onAdd(-200);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: c.elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('−200', style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),

        const SizedBox(height: 12),

        // ── Progress bar ──
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: 14,
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 14,
                backgroundColor: c.elevated,
                valueColor: AlwaysStoppedAnimation(done ? c.info : c.info.withValues(alpha: 0.8)),
              ),
            ),
          ),
          if (!done)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('ещё $remaining мл',
                      style: TextStyle(fontSize: 9, color: c.textMuted, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ]),

        const SizedBox(height: 14),

        // ── Quick-add buttons ──
        Row(children: [
          ..._quickAmounts.map((ml) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onAdd(ml);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: c.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('+$ml', style: TextStyle(
                        fontFamily: 'Syne', fontSize: 14,
                        fontWeight: FontWeight.w800, color: c.info)),
                    Text('мл', style: TextStyle(fontSize: 9, color: c.info.withValues(alpha: 0.7))),
                  ]),
                ),
              ),
            ),
          )),
        ]),
      ]),
    );
  }
}

// ─── Manual food form ─────────────────────────────────────────────────────────

class _ManualFoodForm extends StatefulWidget {
  final ThemePalette colors;
  final ValueChanged<_FoodEntry> onAdd;
  const _ManualFoodForm({required this.colors, required this.onAdd});

  @override
  State<_ManualFoodForm> createState() => _ManualFoodFormState();
}

class _ManualFoodFormState extends State<_ManualFoodForm> {
  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  String _mealType = 'Завтрак';

  static const _mealTypes = ['Завтрак', 'Обед', 'Перекус', 'Ужин'];

  @override
  void dispose() { _nameCtrl.dispose(); _gramsCtrl.dispose(); _kcalCtrl.dispose(); super.dispose(); }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final grams = int.tryParse(_gramsCtrl.text.trim()) ?? 0;
    final kcal = int.tryParse(_kcalCtrl.text.trim()) ?? 0;
    if (name.isEmpty || grams <= 0) return;
    widget.onAdd(_FoodEntry(name: name, grams: grams, kcal: kcal, mealType: _mealType));
    _nameCtrl.clear(); _gramsCtrl.clear(); _kcalCtrl.clear();
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surfaceCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.textPrimary.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ввести вручную', style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 14),

        // Meal type chips
        SizedBox(
          height: 34,
          child: ListView(scrollDirection: Axis.horizontal, children: _mealTypes.map((t) =>
            GestureDetector(
              onTap: () => setState(() => _mealType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _mealType == t ? c.primary : c.elevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: _mealType == t ? c.textOnPrimary : c.textMuted)),
              ),
            ),
          ).toList()),
        ),
        const SizedBox(height: 12),

        // Food name
        _FormField(ctrl: _nameCtrl, hint: 'Название продукта или блюда', icon: Icons.fastfood_rounded, colors: c, textInput: TextInputType.text),
        const SizedBox(height: 10),

        // Grams + Kcal in a row
        Row(children: [
          Expanded(child: _FormField(ctrl: _gramsCtrl, hint: 'Граммы (г)', icon: Icons.scale_rounded, colors: c, textInput: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: _FormField(ctrl: _kcalCtrl, hint: 'Калории (ккал)', icon: Icons.local_fire_department_rounded, colors: c, textInput: TextInputType.number)),
        ]),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Добавить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Added food tile ──────────────────────────────────────────────────────────

class _AddedFoodTile extends StatelessWidget {
  final _FoodEntry entry;
  final ThemePalette colors;
  final VoidCallback onDelete;
  const _AddedFoodTile({required this.entry, required this.colors, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(color: c.surfaceCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.textPrimary.withValues(alpha: 0.06))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.restaurant_rounded, size: 16, color: c.accentOrange),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${entry.mealType} · ${entry.grams}г${entry.kcal > 0 ? ' · ${entry.kcal} ккал' : ''}',
            style: TextStyle(fontSize: 11, color: c.textMuted)),
        ])),
        if (entry.kcal > 0)
          Text('${entry.kcal}', style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: c.accentOrange)),
        IconButton(onPressed: onDelete, icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted), padding: const EdgeInsets.all(8)),
      ]),
    );
  }
}

// ─── Alternatives widget ──────────────────────────────────────────────────────

class _AlternativesWidget extends StatefulWidget {
  final List<String> alternatives;
  final Color mealColor;
  final ThemePalette colors;
  const _AlternativesWidget({required this.alternatives, required this.mealColor, required this.colors});

  @override
  State<_AlternativesWidget> createState() => _AlternativesWidgetState();
}

class _AlternativesWidgetState extends State<_AlternativesWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final m = widget.mealColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Divider(color: m.withValues(alpha: 0.12)),
        GestureDetector(
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
                  'Чем заменить продукты',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: m),
                ),
              ),
              Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18, color: c.textMuted),
            ]),
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
                  Expanded(child: Text(alt, style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.45))),
                ]),
              )).toList(),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _CompactMacro extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CompactMacro({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: [
      TextSpan(text: '$label: ', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
      TextSpan(text: value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    ]));
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final ThemePalette colors;
  final TextInputType textInput;
  const _FormField({required this.ctrl, required this.hint, required this.icon, required this.colors, required this.textInput});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: textInput,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: colors.textMuted),
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NutritionChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(text: TextSpan(children: [
        TextSpan(text: '$label ', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
        TextSpan(text: value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
      ])),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _FoodEntry {
  final String name, mealType;
  final int grams, kcal;
  const _FoodEntry({required this.name, required this.grams, required this.kcal, required this.mealType});
}
