import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/presentation/widgets/loading_shimmer.dart';
import 'package:fitnesbuster/presentation/widgets/segmented_tab_bar.dart';
import 'package:fitnesbuster/core/constants/app_colors.dart';
import 'package:fitnesbuster/domain/services/i_analytics_service.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
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
        title: Text(
          AppLocalizations.tl('challengesTitle'),
          style: AppTextStyles.titleL,
        ),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SegmentedTabBar(
            controller: _tabs,
            labels: [
              AppLocalizations.tl('myChallengesLabel'),
              AppLocalizations.tl('publicChallengesLabel'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildMyChallenges(colors), _buildPublicChallenges(colors)],
      ),
    );
  }

  Widget _buildMyChallenges(ThemePalette colors) {
    final authState = context.read<AuthBloc>().state;
    final myUid = authState is AuthStateAuthenticated ? authState.userId : null;
    return StreamBuilder<List<Challenge>>(
      stream: sl<ISocialService>().myChallengesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: LoadingShimmer.listView(4));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.tlp('challengeLoadFailed', {
                  'error': '${snap.error}',
                }),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final challenges = snap.data ?? [];
        if (challenges.isEmpty) {
          return _buildEmpty(
            colors,
            AppLocalizations.tl('challengeEmptyActiveTitle'),
            AppLocalizations.tl('challengeEmptyActiveBody'),
            action: _CreateChallengeInlineButton(
              colors: colors,
              onTap: () =>
                  _openCreateChallengeSheet(colors, initialIsPublic: false),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: challenges.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _CreateChallengeInlineButton(
                colors: colors,
                onTap: () =>
                    _openCreateChallengeSheet(colors, initialIsPublic: false),
              );
            }
            return _ChallengeCard(
              challenge: challenges[i - 1],
              colors: colors,
              showLeaderboard: true,
              currentUid: myUid,
              showManageAction: true,
            );
          },
        );
      },
    );
  }

  Widget _buildPublicChallenges(ThemePalette colors) {
    final authState = context.read<AuthBloc>().state;
    final myUid = authState is AuthStateAuthenticated ? authState.userId : null;
    return StreamBuilder<List<Challenge>>(
      stream: sl<ISocialService>().publicChallengesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: LoadingShimmer.listView(4));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.tlp('challengeLoadFailed', {
                  'error': '${snap.error}',
                }),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final all = snap.data ?? [];
        if (all.isEmpty) {
          return _buildEmptyPublic(colors);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: all.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final challenge = all[i];
            final isParticipant = challenge.participants.contains(myUid);
            return _ChallengeCard(
              challenge: challenge,
              colors: colors,
              showJoinButton: !isParticipant && challenge.isActive,
              isParticipant: isParticipant,
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty(
    ThemePalette colors,
    String title,
    String subtitle, {
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppImages.energy, width: 64, height: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPublic(ThemePalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppImages.achievements, width: 64, height: 64),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.tl('challengeEmptyPublicTitle'),
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.tl('challengeEmptyPublicBody'),
              style: TextStyle(fontSize: 13, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateChallengeSheet(
    ThemePalette colors, {
    required bool initialIsPublic,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateChallengeSheet(
        colors: colors,
        initialIsPublic: initialIsPublic,
      ),
    );
  }
}

class _CreateChallengeInlineButton extends StatelessWidget {
  final ThemePalette colors;
  final VoidCallback onTap;

  const _CreateChallengeInlineButton({
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          AppLocalizations.tl('challengeCreateTitle'),
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}

class _CreateChallengeSheet extends StatefulWidget {
  final ThemePalette colors;
  final bool initialIsPublic;

  const _CreateChallengeSheet({
    required this.colors,
    required this.initialIsPublic,
  });

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController(text: '3');
  final _duration = TextEditingController(text: '7');
  var _goalType = 'workout_count';
  late bool _isPublic;
  var _loading = false;

  List<_GoalOption> get _goalOptions => [
    _GoalOption(
      'workout_count',
      AppLocalizations.tl('socialWorkouts'),
      AppLocalizations.tl('challengeUnitTimes'),
    ),
    _GoalOption(
      'calories_burned',
      AppLocalizations.tl('socialKcal'),
      AppLocalizations.tl('socialKcal'),
    ),
    _GoalOption(
      'cardio_minutes',
      AppLocalizations.tl('socialCardioMin'),
      AppLocalizations.tl('minSuffix').replaceAll('{n}', ''),
    ),
    _GoalOption(
      'workout_streak',
      AppLocalizations.tl('socialDayStreak'),
      AppLocalizations.tl('challengeUnitDays'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isPublic = widget.initialIsPublic;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.tl('challengeCreateTitle'),
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel(
                  colors: colors,
                  text: AppLocalizations.tl('challengeNameLabel'),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _title,
                  maxLength: 60,
                  decoration: _inputDecoration(
                    colors,
                    AppLocalizations.tl('challengeNameHint'),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return AppLocalizations.tl('challengeNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _FieldLabel(
                  colors: colors,
                  text: AppLocalizations.tl('challengeDescriptionLabel'),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _description,
                  maxLength: 160,
                  minLines: 2,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    colors,
                    AppLocalizations.tl('challengeDescriptionHint'),
                  ),
                ),
                const SizedBox(height: 10),
                _FieldLabel(
                  colors: colors,
                  text: AppLocalizations.tl('challengeGoalLabel'),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _goalType,
                  dropdownColor: colors.surfaceCard,
                  decoration: _inputDecoration(colors, ''),
                  items: _goalOptions
                      .map(
                        (goal) => DropdownMenuItem(
                          value: goal.value,
                          child: Text(goal.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _goalType = value;
                      _target.text = switch (value) {
                        'calories_burned' => '1000',
                        'cardio_minutes' => '120',
                        'workout_streak' => '7',
                        _ => '3',
                      };
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        controller: _target,
                        colors: colors,
                        label: AppLocalizations.tl('challengeTargetLabel'),
                        hint: _currentGoal.unit,
                        min: 1,
                        max: 100000,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        controller: _duration,
                        colors: colors,
                        label: AppLocalizations.tl('challengeDaysLabel'),
                        hint: '1-365',
                        min: 1,
                        max: 365,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isPublic,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.primary,
                  title: Text(
                    AppLocalizations.tl('challengePublicTitle'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    _isPublic
                        ? AppLocalizations.tl('challengePublicEnabled')
                        : AppLocalizations.tl('challengePublicDisabled'),
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _loading ? null : _create,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.textOnPrimary,
                              ),
                            )
                          : Text(
                              AppLocalizations.tl('createChallengeBtn'),
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.textOnPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _GoalOption get _currentGoal =>
      _goalOptions.firstWhere((goal) => goal.value == _goalType);

  InputDecoration _inputDecoration(ThemePalette colors, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textMuted),
      counterStyle: TextStyle(color: colors.textMuted),
      filled: true,
      fillColor: colors.elevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary),
      ),
    );
  }

  Future<void> _create() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    try {
      await sl<ISocialService>().createChallenge(
        title: _title.text.trim(),
        description: _description.text.trim(),
        goalType: _goalType,
        targetValue: int.parse(_target.text),
        durationDays: int.parse(_duration.text),
        isPublic: _isPublic,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.tl('challengeCreated'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.tlp('challengeCreateFailed', {
              'error': e.toString(),
            }),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }
}

class _GoalOption {
  final String value;
  final String label;
  final String unit;

  const _GoalOption(this.value, this.label, this.unit);
}

class _FieldLabel extends StatelessWidget {
  final ThemePalette colors;
  final String text;

  const _FieldLabel({required this.colors, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colors.textMuted,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final ThemePalette colors;
  final String label;
  final String hint;
  final int min;
  final int max;

  const _NumberField({
    required this.controller,
    required this.colors,
    required this.label,
    required this.hint,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(colors: colors, text: label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted),
            filled: true,
            fillColor: colors.elevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.primary),
            ),
          ),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            if (parsed == null) {
              return AppLocalizations.tl('challengeNumberRequired');
            }
            if (parsed < min || parsed > max) return '$min-$max';
            return null;
          },
        ),
      ],
    );
  }
}

// ── Challenge card ─────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final ThemePalette colors;
  final bool showJoinButton;
  final bool showLeaderboard;
  final bool isParticipant;
  final String? currentUid;
  final bool showManageAction;

  const _ChallengeCard({
    required this.challenge,
    required this.colors,
    this.showJoinButton = false,
    this.showLeaderboard = false,
    this.isParticipant = false,
    this.currentUid,
    this.showManageAction = false,
  });

  bool get _isCreator =>
      currentUid != null && currentUid == challenge.createdBy;

  String get _goalEmoji => challenge.emoji.isNotEmpty ? challenge.emoji : '🎯';

  Color get _statusColor {
    if (!challenge.isActive) return Colors.grey;
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 2) return SemanticColors.difficultyAdvanced;
    if (daysLeft <= 5) return SemanticColors.difficultyIntermediate;
    return SemanticColors.difficultyBeginner;
  }

  String get _daysLabel {
    if (!challenge.isActive) {
      return AppLocalizations.tl('challengeCompletedState');
    }
    final d = challenge.endDate.difference(DateTime.now()).inDays;
    return d == 0
        ? AppLocalizations.tl('challengeLastDay')
        : AppLocalizations.tlp('challengeDaysLeft', {'days': '$d'});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showLeaderboard ? () => _openLeaderboard(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_goalEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppLocalizations.tlp('challengeCreatedBy', {
                          'name': challenge.creatorName,
                        }),
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _daysLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: AppLocalizations.tl('challengeGoalLabel'),
                    value: '${challenge.targetValue} ${challenge.goalLabel}',
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: AppLocalizations.tl('challengeParticipantsLabel'),
                    value: '${challenge.participants.length}',
                    colors: colors,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: AppLocalizations.tl('durationLabel'),
                    value: AppLocalizations.tlp('challengeDurationValue', {
                      'days': '${challenge.durationDays}',
                    }),
                    colors: colors,
                  ),
                ),
              ],
            ),
            if (challenge.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isParticipant) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.tl('challengeParticipating'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.success,
                    ),
                  ),
                ),
              ),
            ] else if (!challenge.isActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.textMuted.withValues(alpha: 0.15),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_clock_rounded,
                        size: 14,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.tl('challengeEnded'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (showJoinButton) ...[
              const SizedBox(height: 12),
              _JoinButton(
                challengeId: challenge.id,
                goalType: challenge.goalType,
                colors: colors,
              ),
            ],
            if (showLeaderboard) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.leaderboard_rounded,
                    size: 12,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.tl('leaderboardLabel')} →',
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ),
            ],
            if (showManageAction) ...[
              const SizedBox(height: 10),
              _isCreator
                  ? _DeleteChallengeButton(
                      challengeId: challenge.id,
                      colors: colors,
                    )
                  : _LeaveChallengeButton(
                      challengeId: challenge.id,
                      colors: colors,
                    ),
            ],
          ],
        ),
      ),
    );
  }

  void _openLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeaderboardSheet(challenge: challenge, colors: colors),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemePalette colors;
  const _Stat({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _JoinButton extends StatefulWidget {
  final String challengeId;
  final String goalType;
  final ThemePalette colors;
  const _JoinButton({
    required this.challengeId,
    required this.goalType,
    required this.colors,
  });

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _loading = false;
  bool _joined = false;
  bool _ended = false;

  @override
  Widget build(BuildContext context) {
    if (_joined) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.colors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            AppLocalizations.tl('challengeParticipating'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.colors.success,
            ),
          ),
        ),
      );
    }
    if (_ended) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.colors.textMuted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.colors.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_clock_rounded,
                size: 14,
                color: widget.colors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.tl('challengeEnded'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _loading ? null : _join,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.colors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.colors.textOnPrimary,
                  ),
                )
              : Text(
                  AppLocalizations.tl('joinChallengeBtn'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.colors.textOnPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _join() async {
    setState(() => _loading = true);
    try {
      await sl<ISocialService>().joinChallenge(widget.challengeId);
      try {
        sl<IAnalyticsService>()
            .logChallengeJoined(goalType: widget.goalType)
            .ignore();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _loading = false;
          _joined = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('challenge already ended') ||
            errStr.contains('failed-precondition')) {
          setState(() => _ended = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.tl('challengeAlreadyEnded'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: widget.colors.textMuted,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.tlp('genericErrorWithDetails', {
                  'error': e.toString(),
                }),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      }
    }
  }
}

// ── Delete / leave challenge ─────────────────────────────────────────────────────

class _DeleteChallengeButton extends StatefulWidget {
  final String challengeId;
  final ThemePalette colors;
  const _DeleteChallengeButton({
    required this.challengeId,
    required this.colors,
  });

  @override
  State<_DeleteChallengeButton> createState() => _DeleteChallengeButtonState();
}

class _DeleteChallengeButtonState extends State<_DeleteChallengeButton> {
  bool _loading = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tl('challengeDeleteConfirmTitle')),
        content: Text(AppLocalizations.tl('challengeDeleteConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.tl('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.tl('delete'),
              style: TextStyle(color: widget.colors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await sl<ISocialService>().deleteChallenge(widget.challengeId);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.tlp('genericErrorWithDetails', {
                'error': e.toString(),
              }),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _confirmAndDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.colors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.colors.error,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: widget.colors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.tl('challengeDeleteAction'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.colors.error,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LeaveChallengeButton extends StatefulWidget {
  final String challengeId;
  final ThemePalette colors;
  const _LeaveChallengeButton({
    required this.challengeId,
    required this.colors,
  });

  @override
  State<_LeaveChallengeButton> createState() => _LeaveChallengeButtonState();
}

class _LeaveChallengeButtonState extends State<_LeaveChallengeButton> {
  bool _loading = false;

  Future<void> _confirmAndLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.tl('challengeLeaveConfirmTitle')),
        content: Text(AppLocalizations.tl('challengeLeaveConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.tl('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.tl('challengeLeaveAction'),
              style: TextStyle(color: widget.colors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await sl<ISocialService>().leaveChallenge(widget.challengeId);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.tlp('genericErrorWithDetails', {
                'error': e.toString(),
              }),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _confirmAndLeave,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.colors.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.colors.textMuted.withValues(alpha: 0.15),
          ),
        ),
        child: Center(
          child: _loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.colors.textMuted,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: widget.colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.tl('challengeLeaveAction'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.colors.textMuted,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Leaderboard sheet ──────────────────────────────────────────────────────────

class _LeaderboardSheet extends StatelessWidget {
  final Challenge challenge;
  final ThemePalette colors;
  const _LeaderboardSheet({required this.challenge, required this.colors});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final myUid = authState is AuthStateAuthenticated ? authState.userId : null;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset(AppImages.achievements, width: 22, height: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.tlp('challengeGoalValue', {
                'value': '${challenge.targetValue} ${challenge.goalLabel}',
              }),
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<ChallengeParticipant>>(
              stream: sl<ISocialService>().challengeLeaderboardStream(
                challenge.id,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: LoadingShimmer.listView(4));
                }
                final participants = snap.data ?? [];
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: participants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = participants[i];
                    final isMe = p.uid == myUid;
                    final progress = (p.currentValue / challenge.targetValue)
                        .clamp(0.0, 1.0);
                    final medalIcon = switch (i) {
                      0 => AppImages.medalGold,
                      1 => AppImages.medalSilver,
                      2 => AppImages.medalBronze,
                      _ => null,
                    };
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? colors.primary.withValues(alpha: 0.08)
                            : colors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMe
                              ? colors.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: medalIcon != null
                                    ? Image.asset(
                                        medalIcon,
                                        width: 20,
                                        height: 20,
                                      )
                                    : Text(
                                        '${i + 1}.',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                              ),
                              Expanded(
                                child: Text(
                                  p.name +
                                      (isMe
                                          ? AppLocalizations.tl(
                                              'challengeYouSuffix',
                                            )
                                          : ''),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${p.currentValue} / ${challenge.targetValue}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: colors.primary.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: AlwaysStoppedAnimation(
                                progress >= 1.0
                                    ? colors.success
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
