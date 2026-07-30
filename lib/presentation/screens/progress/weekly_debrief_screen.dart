import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/core/ai/ai_exception.dart';
import 'package:fitnesbuster/core/cache/hive_cache.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/data/models/weekly_debrief.dart';
import 'package:fitnesbuster/data/repositories/pr_repository.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

class WeeklyDebriefScreen extends StatefulWidget {
  const WeeklyDebriefScreen({super.key});

  @override
  State<WeeklyDebriefScreen> createState() => _WeeklyDebriefScreenState();
}

class _WeeklyDebriefScreenState extends State<WeeklyDebriefScreen> {
  WeeklyDebrief? _debrief;
  bool _isLoading = false;
  String? _error;
  UserProfile? _profile;
  String? _uid;
  late final String _weekStart;

  @override
  void initState() {
    super.initState();
    try {
      sl<IAnalyticsService>().logAiDebriefViewed().ignore();
    } catch (_) {}
    final authState = context.read<AuthBloc>().state;
    _uid = authState is AuthStateAuthenticated ? authState.userId : null;
    _weekStart = _currentWeekStart();
    if (authState is AuthStateAuthenticated) {
      _profile = authState.user.profile;
    }
    if (_uid != null) {
      _debrief = HiveCache.getDebrief(_uid!, _weekStart);
      if (_debrief == null) {
        _generate();
      }
    }
  }

  String _currentWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return dateKey(monday);
  }

  Future<void> _generate() async {
    final profile = _profile;
    if (profile == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final settings = sl<ISettingsRepository>();

      final dailyWorkoutKcal = <int>[];
      final dailyWaterMl = <int>[];
      final dailyEatenCal = <int>[];
      int workoutsDone = 0;

      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final k = dateKey(day);
        final done = await settings.getWorkoutDone(k);
        final kcal = await settings.getWorkoutKcal(k);
        final water = await settings.getWaterMl(k);
        final eaten = await settings.getEatenCal(k);
        if (done) {
          workoutsDone++;
        }
        dailyWorkoutKcal.add(kcal);
        dailyWaterMl.add(water);
        dailyEatenCal.add(eaten);
      }

      final allPrs = await PrRepository().getAll();
      final weekPrNames = allPrs
          .where(
            (r) =>
                !r.date.isBefore(monday) &&
                r.date.isBefore(monday.add(const Duration(days: 7))),
          )
          .map((r) => r.exerciseName)
          .toSet()
          .toList();

      final calTarget = _profile?.dailyCalorieTarget.toInt() ?? 2000;

      final raw = await sl<IDeepSeekService>().generateWeeklyDebrief(
        profile: profile,
        workoutsDone: workoutsDone,
        dailyWorkoutKcal: dailyWorkoutKcal,
        dailyWaterMl: dailyWaterMl,
        dailyEatenCal: dailyEatenCal,
        dailyCalTarget: calTarget,
        dailyWaterTarget: 2500,
        weekPrNames: weekPrNames,
      );

      final debrief = WeeklyDebrief.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      await HiveCache.saveDebrief(_uid!, _weekStart, debrief);

      if (mounted) {
        setState(() {
          _debrief = debrief;
          _isLoading = false;
        });
      }
    } on AiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.tl('weeklyDebriefTitle')),
        centerTitle: true,
        actions: [
          if (_debrief != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : () => _generate(),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(colors)),
    );
  }

  Widget _buildBody(ThemePalette colors) {
    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.tl('weeklyDebriefProfileRequired'),
              style: TextStyle(fontSize: 15, color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.tl('weeklyDebriefAnalyzing'),
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _generate(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.tl('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_debrief == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _ScoreHeader(debrief: _debrief!, colors: colors),
        const SizedBox(height: 16),
        _SummaryCard(
          icon: AppImages.workoutsTab,
          title: AppLocalizations.tl('workoutsTitle'),
          text: _debrief!.workoutSummary,
          colors: colors,
          accentColor: colors.primary,
        ),
        const SizedBox(height: 10),
        _SummaryCard(
          icon: AppImages.nutritionTab,
          title: AppLocalizations.tl('nutritionTitle'),
          text: _debrief!.nutritionSummary,
          colors: colors,
          accentColor: colors.accent,
        ),
        const SizedBox(height: 16),
        _BulletSection(
          label: AppLocalizations.tl('achievementsTitle'),
          icon: AppImages.achievements,
          items: _debrief!.highlights,
          color: colors.success,
          colors: colors,
        ),
        const SizedBox(height: 12),
        _BulletSection(
          label: AppLocalizations.tl('weeklyDebriefGrowthAreas'),
          icon: AppImages.trend,
          items: _debrief!.improvements,
          color: colors.accentOrange,
          colors: colors,
        ),
        const SizedBox(height: 16),
        _FocusCard(text: _debrief!.nextWeekFocus, colors: colors),
        const SizedBox(height: 12),
        _BulletSection(
          label: AppLocalizations.tl('recoveryTitle'),
          icon: AppImages.sleep,
          items: _debrief!.recoveryTips,
          color: colors.primary,
          colors: colors,
        ),
      ],
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final WeeklyDebrief debrief;
  final ThemePalette colors;

  const _ScoreHeader({required this.debrief, required this.colors});

  Color get _scoreColor {
    if (debrief.overallScore >= 8) {
      return colors.success;
    }
    if (debrief.overallScore >= 5) {
      return colors.accentOrange;
    }
    return colors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.tl('weeklyDebriefSummary'),
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.tlp('workoutsWeekCount', {
                        'done':
                            '${(debrief.workoutAdherence * 7 / 100).round()}',
                      }),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: debrief.workoutAdherence / 100,
                        backgroundColor: colors.elevated,
                        color: _scoreColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _scoreColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${debrief.overallScore}/10',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
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

class _SummaryCard extends StatelessWidget {
  final String icon;
  final String title;
  final String text;
  final ThemePalette colors;
  final Color accentColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.colors,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(asset: icon, glowColor: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String label;
  final String icon;
  final List<String> items;
  final Color color;
  final ThemePalette colors;

  const _BulletSection({
    required this.label,
    required this.icon,
    required this.items,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              AppIcon(asset: icon, glowColor: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String text;
  final ThemePalette colors;

  const _FocusCard({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.12),
            colors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.center_focus_strong_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tl('weeklyDebriefNextWeekFocus'),
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
