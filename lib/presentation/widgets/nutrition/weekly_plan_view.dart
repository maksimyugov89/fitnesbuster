import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

class WeeklyPlanView extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> meals;
  final int targetCal;
  final Map<String, String> mealIcons;
  final Map<String, String> mealLabels;
  final Map<String, Color> mealColors;
  final String Function(String) normalizeMealType;

  const WeeklyPlanView({
    super.key,
    required this.isLoading,
    required this.meals,
    required this.targetCal,
    required this.mealIcons,
    required this.mealLabels,
    required this.mealColors,
    required this.normalizeMealType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: colors.textMuted.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.tl('createMealPlanHint'),
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

    final dayNames = [
      AppLocalizations.tl('monday'),
      AppLocalizations.tl('tuesday'),
      AppLocalizations.tl('wednesday'),
      AppLocalizations.tl('thursday'),
      AppLocalizations.tl('friday'),
      AppLocalizations.tl('saturday'),
      AppLocalizations.tl('sunday'),
    ];
    final today = DateTime.now().weekday - 1;

    final shoppingList = <String>{};
    for (final meal in meals) {
      final foods = (meal['foods'] as List? ?? []).cast<String>();
      for (final f in foods) {
        shoppingList.add(f.split(',').first.trim());
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: 0.8),
                colors.accentPurple.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Image.asset(AppImages.calendar, width: 32, height: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.tl('weeklyMealPlanTitle'),
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      AppLocalizations.tlp('dailyRationSubtitle', {
                        'cal': targetCal.toString(),
                      }),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(7, (i) {
          final dayIdx = (today + i) % 7;
          final label = dayNames[dayIdx];
          final isToday = i == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isToday
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday
                    ? colors.primary.withValues(alpha: 0.4)
                    : colors.textPrimary.withValues(alpha: 0.06),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Row(
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.tl('today'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (isToday) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isToday ? colors.primary : colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$targetCal ${AppLocalizations.tl('kcalShort')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              initiallyExpanded: isToday,
              iconColor: colors.textMuted,
              collapsedIconColor: colors.textMuted,
              children: meals.map((meal) {
                final type = normalizeMealType(meal['type'] as String? ?? '');
                final time = meal['time'] as String? ?? '';
                final foods = (meal['foods'] as List? ?? []).cast<String>();
                final cal = (meal['calories'] as num?)?.toInt() ?? 0;
                final icon = mealIcons[type] ?? AppImages.snack;
                final label2 = mealLabels[type] ?? type;
                final mealColor = mealColors[type] ?? colors.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: mealColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Image.asset(
                            icon,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  label2,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$cal ${AppLocalizations.tl('kcalShort')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: mealColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textMuted,
                              ),
                            ),
                            if (foods.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                foods.take(3).join(', ') +
                                    (foods.length > 3 ? '...' : ''),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.success.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(AppImages.shoppingList, width: 26, height: 26),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.tl('weeklyShoppingList'),
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shoppingList
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
