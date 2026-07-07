import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/workout_location_screen.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

class WorkoutSettingsSheet extends StatefulWidget {
  final WorkoutLocation currentLocation;
  final RunningPreference currentRunning;
  final Function(WorkoutLocation, RunningPreference) onSave;

  const WorkoutSettingsSheet({
    super.key,
    required this.currentLocation,
    required this.currentRunning,
    required this.onSave,
  });

  @override
  State<WorkoutSettingsSheet> createState() => _WorkoutSettingsSheetState();
}

class _WorkoutSettingsSheetState extends State<WorkoutSettingsSheet> {
  late WorkoutLocation _location;
  late RunningPreference _running;

  @override
  void initState() {
    super.initState();
    _location = widget.currentLocation;
    _running = widget.currentRunning;
  }

  bool get _hasChanges =>
      _location != widget.currentLocation || _running != widget.currentRunning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.workoutSettingsTitle, style: AppTextStyles.titleL),
            const SizedBox(height: 6),
            Text(
              l10n.workoutSettingsSubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            // Location selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.locationSectionLabel,
                style: AppTextStyles.labelL,
              ),
            ),
            const SizedBox(height: 12),
            ..._locationOptions(context).map((opt) => _buildLocationRow(opt)),

            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.runningExercisesLabel,
                style: AppTextStyles.labelL,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRunOption(
                    RunningPreference.withRunning,
                    AppImages.running,
                    l10n.withRunningLabel,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRunOption(
                    RunningPreference.noRunning,
                    null,
                    l10n.withoutRunningLabel,
                    AppColors.accentOrange,
                  ),
                ),
              ],
            ),

            if (_running == RunningPreference.noRunning) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Кардио через берпи, прыжки и функциональные комплексы',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_hasChanges) ...[
              const SizedBox(height: 20),
              if (_location != widget.currentLocation)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Смена места тренировок пересоздаст программу под новое оборудование. Текущий прогресс сохранится.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _hasChanges ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanges
                      ? AppColors.primary
                      : AppColors.surfaceLight,
                  foregroundColor: _hasChanges
                      ? AppColors.textOnPrimary
                      : AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _hasChanges ? l10n.applyChangesBtn : l10n.noChangesLabel,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(_LocOpt opt) {
    final isSel = _location == opt.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _location = opt.value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSel
                ? opt.color.withValues(alpha: 0.1)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel ? opt.color : Colors.white.withValues(alpha: 0.06),
              width: isSel ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Image.asset(opt.iconAsset, width: 28, height: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSel ? opt.color : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      opt.sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSel)
                Icon(Icons.check_circle_rounded, color: opt.color, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunOption(
    RunningPreference val,
    String? iconAsset,
    String label,
    Color color,
  ) {
    final isSel = _running == val;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _running = val);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? color : Colors.white.withValues(alpha: 0.06),
            width: isSel ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconAsset != null
                ? Image.asset(iconAsset, width: 24, height: 24)
                : Icon(Icons.block_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSel ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    widget.onSave(_location, _running);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Программа будет обновлена',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<_LocOpt> _locationOptions(BuildContext context) {
    final l10n = context.l10n;
    return [
      _LocOpt(
        WorkoutLocation.gym,
        AppImages.workoutsTab,
        l10n.gymLocation,
        l10n.gymLocationSub,
        AppColors.accentPurple,
      ),
      _LocOpt(
        WorkoutLocation.outdoor,
        AppImages.running,
        l10n.stadiumLocation,
        l10n.stadiumLocationSub,
        AppColors.success,
      ),
      _LocOpt(
        WorkoutLocation.home,
        AppImages.home,
        l10n.homeLocation,
        l10n.homeLocationSub,
        AppColors.accentOrange,
      ),
    ];
  }
}

class _LocOpt {
  final WorkoutLocation value;
  final String iconAsset, title, sub;
  final Color color;
  const _LocOpt(this.value, this.iconAsset, this.title, this.sub, this.color);
}
