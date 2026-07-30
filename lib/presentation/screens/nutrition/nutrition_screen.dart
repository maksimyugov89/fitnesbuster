import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/data/models/ai_meal_plan.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/barcode_scanner_screen.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/meal_card.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/daily_progress_card.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/nutrition_header.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/weekly_plan_view.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/barcode_scan_card.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/meal_progress_bar.dart';
import 'package:fitnesbuster/presentation/widgets/nutrition/added_food_tile.dart';
import 'package:fitnesbuster/presentation/widgets/segmented_tab_bar.dart';
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
    'breakfast': AppImages.breakfast,
    'lunch': AppImages.lunch,
    'dinner': AppImages.dinner,
    'snack': AppImages.snack,
    'pre_workout': AppImages.workoutsTab,
    'post_workout': AppImages.energy,
    'evening_snack': AppImages.dinner,
    'morning_snack': AppImages.snack,
  };
  Map<String, String> get _mealLabels => {
    'breakfast': AppLocalizations.tl('breakfast'),
    'lunch': AppLocalizations.tl('lunch'),
    'dinner': AppLocalizations.tl('dinner'),
    'snack': AppLocalizations.tl('snack'),
    'pre_workout': AppLocalizations.tl('mealPreWorkout'),
    'post_workout': AppLocalizations.tl('mealPostWorkout'),
    'evening_snack': AppLocalizations.tl('mealEveningSnack'),
    'morning_snack': AppLocalizations.tl('mealMorningSnack'),
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
  int get _planCaloriesEaten => _completedMeals.fold(
    0,
    (s, i) => i < _meals.length
        ? s + ((_meals[i]['calories'] as num?)?.toInt() ?? 0)
        : s,
  );
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
    final prev = _waterIntakeMl;
    final next = (_waterIntakeMl + ml).clamp(0, _waterTargetMl * 2);
    setState(() => _waterIntakeMl = next);
    await sl<ISettingsRepository>().setWaterMl(todayKey(), next);
    if (prev < _waterTargetMl && next >= _waterTargetMl) {
      try {
        sl<IAnalyticsService>()
            .logDailyTaskCompleted(taskType: 'water')
            .ignore();
      } catch (_) {}
    }
  }

  String _normalizeMealType(String raw) =>
      raw.replaceAll(' ', '').toLowerCase();

  void _toggleMealCompletion(int index) {
    if (_completedMeals.contains(index)) {
      HapticFeedback.lightImpact();
      setState(() => _completedMeals.remove(index));
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _completedMeals.add(index));
    }
    _saveProgress();
  }

  // ── Persist completion + eaten calories ───────────────────────────────────
  Future<void> _saveProgress() async {
    final settings = sl<ISettingsRepository>();
    final k = todayKey();
    await settings.setMealsDone(k, _completedMeals.map((i) => '$i').toList());
    await settings.setEatenCal(k, _totalEaten);
    if (_targetCal > 0) await settings.setTargetCal(k, _targetCal);
    final foods = _addedFoods
        .map(
          (f) => jsonEncode({
            'name': f.name,
            'grams': f.grams,
            'kcal': f.kcal,
            'type': f.mealType,
          }),
        )
        .toList();
    await settings.setManualFoods(k, foods);
  }

  Future<void> _loadMealCompletion() async {
    final k = todayKey();
    final raw = await sl<ISettingsRepository>().getMealsDone(k);
    final done = raw
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .where((i) => i < _meals.length)
        .toSet();
    if (mounted && done.isNotEmpty) {
      setState(() => _completedMeals.addAll(done));
    }
  }

  Future<void> _loadAddedFoods() async {
    final k = todayKey();
    final raw = await sl<ISettingsRepository>().getManualFoods(k);
    final foods = raw
        .map((s) {
          try {
            final m = jsonDecode(s) as Map<String, dynamic>;
            return _FoodEntry(
              name: m['name'] as String,
              grams: (m['grams'] as num).toInt(),
              kcal: (m['kcal'] as num).toInt(),
              mealType: m['type'] as String,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<_FoodEntry>()
        .toList();
    if (mounted && foods.isNotEmpty) setState(() => _addedFoods.addAll(foods));
  }

  Future<void> _loadMealPlan() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthStateAuthenticated) {
        if (mounted) {
          setState(() => _mealLoading = false);
        }
        return;
      }
      final uid = authState.userId;
      final plans = await sl<UserRepository>().getAiPlans(uid);
      final jsonStr = plans['mealPlan'];
      if (jsonStr == null) {
        if (mounted) {
          setState(() => _mealLoading = false);
        }
        return;
      }
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final meals = (data['meals'] as List).cast<Map<String, dynamic>>();
      final water = (data['water_target_ml'] as num?)?.toInt() ?? 2500;
      final recs =
          (data['recommendations'] as List? ??
                  data['daily_tips'] as List? ??
                  [])
              .cast<String>();
      final totalCal = meals.fold(
        0,
        (s, m) => s + ((m['calories'] as num?)?.toInt() ?? 0),
      );
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
      if (mounted) {
        setState(() => _mealLoading = false);
      }
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
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            NutritionHeader(
              completedCount: _completedMeals.length,
              totalMeals: _meals.length,
              onShoppingListTap: () => context.push(AppRouter.shoppingList),
            ),
            DailyProgressCard(
              totalEaten: _totalEaten,
              targetCal: _targetCal,
              manualCalories: _manualCaloriesEaten,
              hasAddedFoods: _addedFoods.isNotEmpty,
            ),
            SegmentedTabBar(
              controller: _tabCtrl,
              labels: [
                AppLocalizations.tl('todayTabLabel'),
                AppLocalizations.tl('weeklyTabLabel'),
                AppLocalizations.tl('addFoodTabLabel'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildMealPlan(colors),
                  WeeklyPlanView(
                    isLoading: _mealLoading,
                    meals: _meals,
                    targetCal: _targetCal,
                    mealIcons: _mealIcons,
                    mealLabels: _mealLabels,
                    mealColors: _mealColors,
                    normalizeMealType: _normalizeMealType,
                  ),
                  _buildAddFood(colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Meal Plan Tab ────────────────────────────────────────────────────────

  Widget _buildMealPlan(ThemePalette colors) {
    if (_mealLoading) return const Center(child: CircularProgressIndicator());
    if (_meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_rounded,
                size: 64,
                color: colors.textMuted.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.tl('noPlanError'),
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Progress bar across all meals
        MealProgressBar(
          meals: _meals,
          completedMeals: _completedMeals,
          mealIcons: _mealIcons,
          mealColors: _mealColors,
          normalizeMealType: _normalizeMealType,
        ),
        const SizedBox(height: 16),

        // Meal cards
        ..._meals.asMap().entries.map((e) {
          final type = _normalizeMealType(e.value['type'] as String? ?? '');
          return MealCard(
            meal: e.value,
            isDone: _completedMeals.contains(e.key),
            mealLabel: _mealLabels[type] ?? type,
            mealIcon: _mealIcons[type] ?? AppImages.snack,
            mealColor: _mealColors[type] ?? colors.primary,
            onToggle: () => _toggleMealCompletion(e.key),
          );
        }),
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
          Text(
            AppLocalizations.tl('supplementsSportLabel'),
            style: AppTextStyles.titleM,
          ),
          const SizedBox(height: 10),
          ..._supplements.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentPurple.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(AppImages.supplements, width: 20, height: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (s.dose.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accentPurple.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s.dose,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accentPurple,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (s.timing.isNotEmpty)
                          Text(
                            s.timing,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                        if (s.purpose.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            s.purpose,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Recommendations
        if (_mealRecs.isNotEmpty) ...[
          Text(
            AppLocalizations.tl('nutritionTipsLabel'),
            style: AppTextStyles.titleM,
          ),
          const SizedBox(height: 10),
          ..._mealRecs.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Add Food Tab ─────────────────────────────────────────────────────────

  Widget _buildAddFood(ThemePalette colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Barcode scan
        BarcodeScanCard(onTap: _openBarcodeScanner),
        const SizedBox(height: 16),

        // Manual entry
        _ManualFoodForm(
          colors: colors,
          onAdd: (entry) {
            setState(() => _addedFoods.insert(0, entry));
            _saveProgress();
          },
        ),
        const SizedBox(height: 20),

        // Added foods list
        if (_addedFoods.isNotEmpty) ...[
          Row(
            children: [
              Text(
                AppLocalizations.tl('addedFood'),
                style: AppTextStyles.titleM,
              ),
              const Spacer(),
              Text(
                AppLocalizations.tlp('foodDiaryCalories', {
                  'calories': '$_manualCaloriesEaten',
                }),
                style: TextStyle(
                  fontSize: 13,
                  color: colors.accentOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._addedFoods.asMap().entries.map(
            (e) => AddedFoodTile(
              name: e.value.name,
              mealType: e.value.mealType,
              grams: e.value.grams,
              kcal: e.value.kcal,
              onDelete: () {
                setState(() => _addedFoods.removeAt(e.key));
                _saveProgress();
              },
            ),
          ),
        ],
      ],
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: done
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey(true),
                        color: Colors.greenAccent,
                        size: 26,
                      )
                    : Image.asset(
                        AppImages.water,
                        key: const ValueKey(false),
                        width: 26,
                        height: 26,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.tl('waterTitle'),
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        done
                            ? AppLocalizations.tl('goalReachedMsg')
                            : AppLocalizations.tlp('waterDrunkOf', {
                                'drunk': intakeLiters,
                                'total': targetLiters,
                              }),
                        key: ValueKey('$intakeMl/$targetMl'),
                        style: TextStyle(
                          fontSize: 12,
                          color: done ? c.info : c.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Undo last 200 ml
              if (intakeMl > 0)
                Semantics(
                  label: AppLocalizations.tlp('waterAdjustment', {
                    'amount': '−200',
                  }),
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onAdd(-200);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: c.elevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '−200',
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Progress bar ──
          Stack(
            children: [
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
                    valueColor: AlwaysStoppedAnimation(
                      done ? c.info : c.info.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
              if (!done)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        AppLocalizations.tlp('waterRemaining', {
                          'ml': '$remaining',
                        }),
                        style: TextStyle(
                          fontSize: 9,
                          color: c.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Quick-add buttons ──
          Row(
            children: [
              ..._quickAmounts.map(
                (ml) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Semantics(
                      label: AppLocalizations.tlp('waterAdjustment', {
                        'amount': '+$ml',
                      }),
                      button: true,
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
                            border: Border.all(
                              color: c.info.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+$ml',
                                style: TextStyle(
                                  fontFamily: 'Syne',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: c.info,
                                ),
                              ),
                              Text(
                                AppLocalizations.tl('mlUnit'),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: c.info.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
  String _mealType = 'breakfast';

  static const _mealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gramsCtrl.dispose();
    _kcalCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final grams = int.tryParse(_gramsCtrl.text.trim()) ?? 0;
    final kcal = int.tryParse(_kcalCtrl.text.trim()) ?? 0;
    if (name.isEmpty || grams <= 0) return;
    widget.onAdd(
      _FoodEntry(name: name, grams: grams, kcal: kcal, mealType: _mealType),
    );
    _nameCtrl.clear();
    _gramsCtrl.clear();
    _kcalCtrl.clear();
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tl('enterManually'),
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Meal type chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _mealTypes
                  .map(
                    (t) => Semantics(
                      label: AppLocalizations.tl(t),
                      button: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _mealType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _mealType == t ? c.primary : c.elevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            AppLocalizations.tl(t),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _mealType == t
                                  ? c.textOnPrimary
                                  : c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Food name
          _FormField(
            ctrl: _nameCtrl,
            hint: AppLocalizations.tl('productNameHint'),
            icon: Icons.fastfood_rounded,
            colors: c,
            textInput: TextInputType.text,
          ),
          const SizedBox(height: 10),

          // Grams + Kcal in a row
          Row(
            children: [
              Expanded(
                child: _FormField(
                  ctrl: _gramsCtrl,
                  hint: AppLocalizations.tl('gramsHint'),
                  icon: Icons.scale_rounded,
                  iconAsset: AppImages.foodScale,
                  colors: c,
                  textInput: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FormField(
                  ctrl: _kcalCtrl,
                  hint: AppLocalizations.tl('caloriesHint'),
                  icon: Icons.local_fire_department_rounded,
                  iconAsset: AppImages.calorieCounter,
                  colors: c,
                  textInput: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: AppLocalizations.tl('add'),
              button: true,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  AppLocalizations.tl('add'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form field ───────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final String? iconAsset;
  final ThemePalette colors;
  final TextInputType textInput;
  const _FormField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.iconAsset,
    required this.colors,
    required this.textInput,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: textInput,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        prefixIcon: iconAsset != null
            ? AppIcon(asset: iconAsset!, glowColor: colors.primary, size: 20)
            : Icon(icon, size: 18, color: colors.textMuted),
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

// ─── Data models ──────────────────────────────────────────────────────────────

class _FoodEntry {
  final String name, mealType;
  final int grams, kcal;
  const _FoodEntry({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.mealType,
  });
}
