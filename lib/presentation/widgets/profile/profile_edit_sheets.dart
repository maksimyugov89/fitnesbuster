import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/constants/avatar_presets.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/presentation/widgets/profile/profile_sheet_widgets.dart';
import 'package:fitnesbuster/domain/entities/body_measurement.dart';
import 'package:fitnesbuster/domain/entities/user_entities.dart';

void showProfileSuccess(BuildContext context, String msg) {
  final colors = AppTheme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      backgroundColor: colors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

// ── Edit Profile Sheet ────────────────────────────────────────────────────

class ProfileEditSheet extends StatefulWidget {
  final String name, email;
  final int avatarPresetIndex;
  final String avatarCustomPath;
  final void Function(String, String) onSave;
  final VoidCallback onAvatarTap;

  const ProfileEditSheet({
    super.key,
    required this.name,
    required this.email,
    required this.avatarPresetIndex,
    required this.avatarCustomPath,
    required this.onSave,
    required this.onAvatarTap,
  });

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Widget _buildAvatar(ThemePalette colors) {
    const size = 80.0;
    Widget circle;
    if (widget.avatarCustomPath.isNotEmpty) {
      circle = ClipOval(
        child: Image.file(
          File(widget.avatarCustomPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackCircle(size, colors),
        ),
      );
    } else if (widget.avatarPresetIndex >= 0 &&
        widget.avatarPresetIndex < kAvatarPresets.length) {
      final p = kAvatarPresets[widget.avatarPresetIndex];
      circle = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: p.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(child: Image.asset(p.iconAsset, width: 44, height: 44)),
      );
    } else {
      circle = _fallbackCircle(size, colors);
    }
    return Stack(
      children: [
        circle,
        Positioned(
          bottom: 0,
          right: 0,
          child: Semantics(
            label: AppLocalizations.of(context).changeAvatar,
            button: true,
            child: GestureDetector(
              onTap: widget.onAvatarTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: colors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackCircle(double size, ThemePalette colors) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: colors.primaryGradient,
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: colors.textOnPrimary,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return SheetWrapper(
      title: l10n.editProfileLabel,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Center(child: _buildAvatar(colors)),
            const SizedBox(height: 6),
            Semantics(
              label: l10n.changeAvatar,
              button: true,
              child: TextButton.icon(
                onPressed: widget.onAvatarTap,
                icon: Icon(
                  Icons.photo_camera_rounded,
                  size: 15,
                  color: colors.primary,
                ),
                label: Text(
                  l10n.changeAvatar,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SheetField(
              controller: _nameCtrl,
              label: l10n.nameLabel,
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v!.trim().isEmpty ? l10n.enterNameValidation : null,
            ),
            const SizedBox(height: 14),
            SheetField(
              controller: _emailCtrl,
              label: l10n.emailLabel,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.enterEmailValidation;
                }
                if (!RegExp(
                  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(v.trim())) {
                  return l10n.invalidEmailFormat;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SaveButton(
              onTap: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave(_nameCtrl.text.trim(), _emailCtrl.text.trim());
                  Navigator.of(context).pop();
                  showProfileSuccess(context, l10n.profileUpdated);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Body Params Sheet ─────────────────────────────────────────────────────

class BodyParamsSheet extends StatefulWidget {
  final double weight;
  final Future<BodyMeasurement?> Function() fetchLatestMeasurement;
  final void Function(double weight, BodyMeasurement measurement) onSave;

  const BodyParamsSheet({
    super.key,
    required this.weight,
    required this.fetchLatestMeasurement,
    required this.onSave,
  });

  @override
  State<BodyParamsSheet> createState() => _BodyParamsSheetState();
}

class _BodyParamsSheetState extends State<BodyParamsSheet> {
  late double _weight;
  late final TextEditingController _weightCtrl;
  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weight = widget.weight;
    _weightCtrl = TextEditingController(text: widget.weight.toStringAsFixed(1));
    widget.fetchLatestMeasurement().then((m) {
      if (!mounted || m == null) return;
      setState(() {
        if (m.chestCm != null) _chestCtrl.text = m.chestCm!.toStringAsFixed(1);
        if (m.waistCm != null) _waistCtrl.text = m.waistCm!.toStringAsFixed(1);
        if (m.hipsCm != null) _hipsCtrl.text = m.hipsCm!.toStringAsFixed(1);
      });
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetWrapper(
      title: l10n.bodyParamsLabel,
      iconAsset: AppImages.weightTracker,
      child: Column(
        children: [
          NumSlider(
            label: l10n.weightLabel,
            value: _weight,
            min: 30,
            max: 250,
            unit: l10n.kgUnit,
            decimals: 1,
            onChanged: (v) => setState(() {
              _weight = v;
              _weightCtrl.text = v.toStringAsFixed(1);
            }),
          ),
          const SizedBox(height: 12),
          MeasurementField(
            label: l10n.weightLabel,
            unit: l10n.kgUnit,
            controller: _weightCtrl,
            icon: Icons.monitor_weight_outlined,
            onChanged: (v) {
              if (v != null) setState(() => _weight = v.clamp(30, 250));
            },
          ),
          const SizedBox(height: 20),
          MeasurementField(
            label: AppLocalizations.tl('chest'),
            unit: 'см',
            controller: _chestCtrl,
            icon: Icons.circle_outlined,
          ),
          const SizedBox(height: 12),
          MeasurementField(
            label: AppLocalizations.tl('waist'),
            unit: 'см',
            controller: _waistCtrl,
            icon: Icons.circle_outlined,
          ),
          const SizedBox(height: 12),
          MeasurementField(
            label: AppLocalizations.tl('hips'),
            unit: 'см',
            controller: _hipsCtrl,
            icon: Icons.circle_outlined,
          ),
          const SizedBox(height: 24),
          SaveButton(
            onTap: () {
              final measurement = BodyMeasurement(
                date: DateTime.now(),
                chestCm: MeasurementField.parse(_chestCtrl.text),
                waistCm: MeasurementField.parse(_waistCtrl.text),
                hipsCm: MeasurementField.parse(_hipsCtrl.text),
              );
              widget.onSave(_weight, measurement);
              Navigator.of(context).pop();
              showProfileSuccess(context, AppLocalizations.tl('paramsSaved'));
            },
          ),
        ],
      ),
    );
  }
}

// ── Goal Edit Sheet ────────────────────────────────────────────────────────

class GoalEditSheet extends StatefulWidget {
  final String goal;
  final void Function(String goal) onSave;

  const GoalEditSheet({super.key, required this.goal, required this.onSave});

  @override
  State<GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<GoalEditSheet> {
  late String _selectedGoal;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.goal;
  }

  LinearGradient _gradient(int index, ThemePalette colors) {
    switch (index) {
      case 0:
        return LinearGradient(
          colors: [colors.accentOrange, colors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1:
        return LinearGradient(
          colors: [colors.accentPurple, const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [colors.primary, colors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return SheetWrapper(
      title: l10n.fitnessGoalLabel,
      child: Column(
        children: [
          ..._goalsData.asMap().entries.map((e) {
            final label = e.value['label'] as String;
            final emoji = e.value['emoji'] as String;
            final desc = e.value['desc'] as String;
            final gradient = _gradient(e.key, colors);
            final isSelected = _selectedGoal == label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGoal = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected ? gradient : null,
                    color: isSelected ? null : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? gradient.colors.first.withValues(alpha: 0.4)
                          : colors.textPrimary.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: gradient.colors.first.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Image.asset(emoji, width: 38, height: 38),
                      const SizedBox(width: 14),
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
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? colors.textPrimary.withValues(alpha: 0.75)
                                    : colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colors.textPrimary
                              : colors.surfaceLight,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : colors.textMuted,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: colors.background,
                                size: 14,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          SaveButton(
            onTap: () {
              widget.onSave(_selectedGoal);
              Navigator.of(context).pop();
              showProfileSuccess(context, l10n.save);
            },
          ),
        ],
      ),
    );
  }

  static const _goalsData = [
    {
      'label': 'Похудение веса',
      'emoji': AppImages.energy,
      'desc': 'Сжечь жир, сухое тело',
    },
    {
      'label': 'Набор массы',
      'emoji': AppImages.workoutsTab,
      'desc': 'Сила и мышечная масса',
    },
    {
      'label': 'Поддержание веса',
      'emoji': AppImages.balance,
      'desc': 'Держать форму и здоровье',
    },
    {
      'label': 'К пляжному сезону',
      'emoji': AppImages.relax,
      'desc': 'Подготовка к лету',
    },
    {
      'label': 'Спортивные рекорды',
      'emoji': AppImages.achievements,
      'desc': 'Максимальная производительность',
    },
  ];
}

// ── Training Experience Edit Sheet ───────────────────────────────────────────

class TrainingExperienceEditSheet extends StatefulWidget {
  final TrainingExperience experience;
  final ValueChanged<TrainingExperience> onSave;

  const TrainingExperienceEditSheet({
    super.key,
    required this.experience,
    required this.onSave,
  });

  @override
  State<TrainingExperienceEditSheet> createState() =>
      _TrainingExperienceEditSheetState();
}

class _TrainingExperienceEditSheetState
    extends State<TrainingExperienceEditSheet> {
  late TrainingExperience _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.experience;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    final options = [
      (
        TrainingExperience.novice,
        AppImages.beginner,
        l10n.experienceNovice,
        l10n.experienceNoviceDesc,
      ),
      (
        TrainingExperience.intermediate,
        AppImages.workoutsTab,
        l10n.experienceIntermediate,
        l10n.experienceIntermediateDesc,
      ),
      (
        TrainingExperience.experienced,
        AppImages.achievements,
        l10n.experienceExperienced,
        l10n.experienceExperiencedDesc,
      ),
    ];
    return SheetWrapper(
      title: l10n.trainingExperienceLabel,
      child: Column(
        children: [
          ...options.map((o) {
            final (value, emoji, label, desc) = o;
            final isSelected = _selected == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selected = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.textPrimary.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(emoji, width: 32, height: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          SaveButton(
            onTap: () {
              widget.onSave(_selected);
              Navigator.of(context).pop();
              showProfileSuccess(context, l10n.save);
            },
          ),
        ],
      ),
    );
  }
}

// ── NumSlider (shared form widget) ─────────────────────────────────────────

class NumSlider extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int decimals;
  final ValueChanged<double> onChanged;

  const NumSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    this.decimals = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.labelL),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                decimals == 0
                    ? '${value.round()} $unit'
                    : '${value.toStringAsFixed(decimals)} $unit',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.surfaceLight,
            thumbColor: colors.primary,
            overlayColor: colors.primary.withValues(alpha: 0.12),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

// ── Notifications Sheet ────────────────────────────────────────────────────

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});
  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _workoutReminder = true;
  bool _eveningSync = true;
  bool _mealReminder = false;
  bool _progressWeekly = true;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return SheetWrapper(
      title: context.l10n.notificationsLabel,
      iconAsset: AppImages.notifications,
      child: Column(
        children: [
          NotifToggle(
            label: AppLocalizations.tl('workoutReminder'),
            subtitle: AppLocalizations.tl('reminder30min'),
            value: _workoutReminder,
            onChanged: (v) => setState(() => _workoutReminder = v),
          ),
          Divider(color: colors.surfaceLight),
          NotifToggle(
            label: AppLocalizations.tl('eveningSync'),
            subtitle: AppLocalizations.tl('everyEvening22'),
            value: _eveningSync,
            onChanged: (v) => setState(() => _eveningSync = v),
          ),
          Divider(color: colors.surfaceLight),
          NotifToggle(
            label: AppLocalizations.tl('mealReminder'),
            subtitle: AppLocalizations.tl('threeTimesDay'),
            value: _mealReminder,
            onChanged: (v) => setState(() => _mealReminder = v),
          ),
          Divider(color: colors.surfaceLight),
          NotifToggle(
            label: AppLocalizations.tl('weeklyReport'),
            subtitle: AppLocalizations.tl('onSundays'),
            value: _progressWeekly,
            onChanged: (v) => setState(() => _progressWeekly = v),
          ),
          const SizedBox(height: 24),
          SaveButton(
            onTap: () {
              Navigator.of(context).pop();
              showProfileSuccess(context, AppLocalizations.tl('settingsSaved'));
            },
          ),
        ],
      ),
    );
  }
}

// ── Security Sheet ─────────────────────────────────────────────────────────

class SecuritySheet extends StatefulWidget {
  const SecuritySheet({super.key});
  @override
  State<SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends State<SecuritySheet> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureOld = true, _obscureNew = true;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return SheetWrapper(
      title: context.l10n.securityLabel,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SheetField(
              controller: _oldPassCtrl,
              label: AppLocalizations.tl('currentPassword'),
              icon: Icons.lock_outline_rounded,
              obscure: _obscureOld,
              suffix: Semantics(
                label: AppLocalizations.tl('toggleVisibility'),
                button: true,
                child: IconButton(
                  icon: Icon(
                    _obscureOld
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: colors.textMuted,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
              ),
              validator: (v) => v!.isEmpty
                  ? AppLocalizations.tl('enterCurrentPassword')
                  : null,
            ),
            const SizedBox(height: 14),
            SheetField(
              controller: _newPassCtrl,
              label: AppLocalizations.tl('newPassword'),
              icon: Icons.lock_rounded,
              obscure: _obscureNew,
              suffix: Semantics(
                label: AppLocalizations.tl('toggleVisibility'),
                button: true,
                child: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: colors.textMuted,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v!.isEmpty) return AppLocalizations.tl('enterNewPassword');
                if (v.length < 6) {
                  return AppLocalizations.tl('passwordMinLength');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SaveButton(
              label: AppLocalizations.tl('changePassword'),
              onTap: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  showProfileSuccess(
                    context,
                    AppLocalizations.tl('passwordChanged'),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
