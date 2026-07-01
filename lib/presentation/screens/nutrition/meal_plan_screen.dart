import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/data/models/ai_meal_plan.dart';
import 'package:fitnesbuster/presentation/widgets/loading_shimmer.dart';
import 'package:fitnesbuster/presentation/screens/nutrition/meal_constants.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});
  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _loading = true;
  String? _error;
  AiMealPlan? _plan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthStateAuthenticated) {
        setState(() {
          _loading = false;
          _error = 'Не авторизован';
        });
        return;
      }
      final uid = authState.userId;
      final plans = await sl<IUserRepository>().getAiPlans(uid);
      final jsonStr = plans['mealPlan'];
      if (jsonStr == null) {
        setState(() {
          _loading = false;
          _error = 'План питания ещё не сгенерирован.\nПройдите онбординг.';
        });
        return;
      }
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final plan = AiMealPlan.fromJson(data);
      if (mounted) {
        setState(() {
          _loading = false;
          _plan = plan;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = AppLocalizations.tl(
            'loadErrorMsg',
          ).replaceAll('{error}', e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: _loading
                  ? Center(child: LoadingShimmer.cards(3))
                  : _error != null
                  ? _buildError(colors)
                  : _buildContent(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemePalette colors) {
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
                color: colors.surfaceCard,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Питание', style: AppTextStyles.displayM),
              Text(
                'ИИ-план питания на день',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemePalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_rounded,
              size: 64,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 15, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemePalette colors) {
    final plan = _plan!;
    final waterLiters = (plan.waterTargetMl / 1000).toStringAsFixed(1);
    final targets = plan.dailyTargets;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      children: [
        // ── Summary card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Суточные цели', style: AppTextStyles.titleM),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Target(
                    label: 'Калории',
                    value: '${plan.totalCalories}',
                    unit: 'ккал',
                    color: colors.accentOrange,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colors.textPrimary.withValues(alpha: 0.08),
                  ),
                  _Target(
                    label: 'Приёмов пищи',
                    value: '${plan.meals.length}',
                    unit: 'раз',
                    color: colors.primary,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colors.textPrimary.withValues(alpha: 0.08),
                  ),
                  _Target(
                    label: 'Вода',
                    value: waterLiters,
                    unit: 'л',
                    color: colors.info,
                  ),
                ],
              ),
              // ── Macro row (only if targets provided) ──
              if (!targets.isEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroTarget(
                      label: 'Белки',
                      grams: targets.protein,
                      color: colors.primary,
                    ),
                    _MacroTarget(
                      label: 'Углеводы',
                      grams: targets.carbs,
                      color: colors.accentOrange,
                    ),
                    _MacroTarget(
                      label: 'Жиры',
                      grams: targets.fat,
                      color: colors.success,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Рекомендуемый план', style: AppTextStyles.titleM),
        const SizedBox(height: 12),

        ...plan.meals.map((meal) => _buildMealCard(colors, meal)),

        const SizedBox(height: 12),

        // ── Water card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.info.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вода',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$waterLiters л в день — пейте равномерно в течение дня',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Supplements ──
        if (plan.supplements.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Спортивное питание', style: AppTextStyles.titleM),
          const SizedBox(height: 12),
          ...plan.supplements.map((s) => _buildSupplementCard(colors, s)),
        ],

        // ── Recommendations ──
        if (plan.recommendations.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Советы по питанию', style: AppTextStyles.titleM),
          const SizedBox(height: 12),
          ...plan.recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
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

  Widget _buildMealCard(ThemePalette colors, AiMeal meal) {
    final normalizedType = meal.type.replaceAll(' ', '').toLowerCase();
    final icon = mealIcons[normalizedType] ?? '🍽️';
    final label = mealLabels[normalizedType] ?? meal.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      meal.time,
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${meal.calories} ккал',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          if (meal.foods.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...meal.foods.map(
              (food) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: colors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        food,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // ── Macros per meal ──
          if (!meal.macros.isEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _InlineMacro(
                  label: 'Б',
                  grams: meal.macros.protein,
                  color: colors.primary,
                ),
                const SizedBox(width: 10),
                _InlineMacro(
                  label: 'У',
                  grams: meal.macros.carbs,
                  color: colors.accentOrange,
                ),
                const SizedBox(width: 10),
                _InlineMacro(
                  label: 'Ж',
                  grams: meal.macros.fat,
                  color: colors.success,
                ),
                if (meal.macros.fiber > 0) ...[
                  const SizedBox(width: 10),
                  _InlineMacro(
                    label: 'Кл',
                    grams: meal.macros.fiber,
                    color: colors.textMuted,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplementCard(ThemePalette colors, AiSupplement s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💊', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s.name,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (s.dose.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentPurple.withValues(alpha: 0.15),
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
                if (s.timing.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.timing,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
                if (s.purpose.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _Target extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _Target({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 10, color: colors.textMuted)),
      ],
    );
  }
}

class _MacroTarget extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;
  const _MacroTarget({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
        const SizedBox(height: 2),
        Text(
          '$gramsг',
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InlineMacro extends StatelessWidget {
  final String label;
  final int grams;
  final Color color;
  const _InlineMacro({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
          ),
          TextSpan(
            text: '$gramsг',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
