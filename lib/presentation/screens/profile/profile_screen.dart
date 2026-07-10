import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/core/health/health_data_mapper.dart';
import 'package:fitnesbuster/core/utils/recent_rpe.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/core/constants/avatar_presets.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/workout_location_screen.dart';
import 'package:fitnesbuster/presentation/screens/profile/workout_settings_sheet.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_plan_screen.dart';
import 'package:fitnesbuster/presentation/widgets/profile/language_selection_sheet.dart';
import 'package:fitnesbuster/presentation/widgets/profile/theme_selection_sheet.dart';
import 'package:fitnesbuster/presentation/widgets/profile/profile_edit_sheets.dart';
import 'package:fitnesbuster/presentation/widgets/profile/avatar_picker_sheet.dart';
import 'package:fitnesbuster/presentation/widgets/profile/profile_misc_widgets.dart';
import 'package:fitnesbuster/core/localization/language_service.dart';
import 'package:fitnesbuster/core/theme/theme_service.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data loaded from authenticated Firebase user + Firestore profile
  String _name = '';
  String _email = '';
  double _weight = 0;
  double _height = 0;
  int _age = 0;
  String _gender = '';
  String _goal = '';
  WorkoutLocation _workoutLocation = WorkoutLocation.gym;
  RunningPreference _runningPreference = RunningPreference.withRunning;
  TrainingExperience _trainingExperience = TrainingExperience.novice;
  bool _dataLoaded = false;

  // ── Gamification ────────────────────────────────────────────────────────────
  UserLevel? _profileLevel;
  Set<String> _profileUnlocked = {};

  // ── Avatar ──────────────────────────────────────────────────────────────────
  int _avatarPresetIndex = -1; // -1 = use initials
  String _avatarCustomPath = ''; // non-empty = custom photo

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAvatar();
    _loadGamificationForProfile();
  }

  Future<void> _loadGamificationForProfile() async {
    final xp = await sl<IGamificationService>().getTotalXp();
    final unlocked = await sl<IGamificationService>().getUnlockedIds();
    if (!mounted) return;
    setState(() {
      _profileLevel = GamificationService.computeLevel(xp);
      _profileUnlocked = unlocked;
    });
  }

  // ── Avatar persistence ─────────────────────────────────────────────────────

  Future<void> _loadAvatar() async {
    final settings = sl<ISettingsRepository>();
    final mode = await settings.getAvatarMode() ?? 'initials';
    if (!mounted) return;
    if (mode == 'preset') {
      final idx = await settings.getAvatarPresetIndex() ?? -1;
      setState(() {
        _avatarPresetIndex = idx;
        _avatarCustomPath = '';
      });
    } else if (mode == 'custom') {
      final path = await settings.getAvatarCustomPath() ?? '';
      if (path.isNotEmpty && File(path).existsSync()) {
        setState(() {
          _avatarCustomPath = path;
          _avatarPresetIndex = -1;
        });
      }
    }
  }

  Future<void> _saveAvatarPreset(int index) async {
    final settings = sl<ISettingsRepository>();
    await settings.setAvatarMode('preset');
    await settings.setAvatarPresetIndex(index);
    await settings.removeAvatarCustomPath();
    if (mounted) {
      setState(() {
        _avatarPresetIndex = index;
        _avatarCustomPath = '';
      });
    }
  }

  Future<void> _saveAvatarCustom(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/avatar_custom.jpg';
    await File(sourcePath).copy(dest);
    final settings = sl<ISettingsRepository>();
    await settings.setAvatarMode('custom');
    await settings.setAvatarCustomPath(dest);
    await settings.setAvatarPresetIndex(-1);
    if (mounted) {
      setState(() {
        _avatarCustomPath = dest;
        _avatarPresetIndex = -1;
      });
    }
  }

  void _openAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPickerSheet(
        currentPresetIndex: _avatarPresetIndex,
        currentCustomPath: _avatarCustomPath,
        onPresetSelected: (i) {
          Navigator.of(context).pop();
          _saveAvatarPreset(i);
        },
        onCustomSelected: (path) {
          Navigator.of(context).pop();
          _saveAvatarCustom(path);
        },
      ),
    );
  }

  void _loadUserData() {
    // Step 1: show cached AuthBloc data immediately (no flicker)
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateAuthenticated) {
      final user = authState.user;
      setState(() {
        _name = user.name;
        _email = user.email;
        _weight = user.profile?.weight ?? 0;
        _height = user.profile?.height ?? 0;
        _age = user.profile?.age ?? 0;
        _gender = user.profile?.gender == Gender.male
            ? 'Мужской'
            : (user.profile?.gender == Gender.female ? 'Женский' : '');
        _goal = user.profile?.goal != null
            ? _fitnessGoalLabel(user.profile!.goal)
            : '';
        _dataLoaded = true;
      });
    }
    // Step 2: always refresh from Firestore to pick up onboarding data
    _refreshFromFirestore();
  }

  Future<void> _refreshFromFirestore() async {
    final uid =
        (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
    if (uid == null) return;
    try {
      final user = await sl<IUserRepository>().getUser(uid);
      if (!mounted) return;
      setState(() {
        if (user.name.isNotEmpty) _name = user.name;
        if (user.email.isNotEmpty) _email = user.email;
        if (user.profile != null) {
          _weight = user.profile!.weight;
          _height = user.profile!.height;
          _age = user.profile!.age;
          _gender = user.profile!.gender == Gender.male ? 'Мужской' : 'Женский';
          _goal = _fitnessGoalLabel(user.profile!.goal);
          if (user.profile!.workoutLocation != null) {
            _workoutLocation = _parseLocation(user.profile!.workoutLocation!);
          }
          if (user.profile!.runningPreference != null) {
            _runningPreference = _parseRunning(
              user.profile!.runningPreference!,
            );
          }
          _trainingExperience = user.profile!.trainingExperience;
        }
        _dataLoaded = true;
      });
      // Sync updated user back into AuthBloc so it stays consistent
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthStateAuthenticated) {
          context.read<AuthBloc>().add(AuthUserChanged(user: user));
        }
      }
    } catch (e) {
      appLogger.d('ProfileScreen: Firestore refresh failed', error: e);
    }
  }

  void _saveProfileToFirestore() async {
    try {
      final repo = sl<IUserRepository>();
      final authRepo = sl<IAuthRepository>();
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthStateAuthenticated) {
        final genderEnum = _gender == 'Мужской' ? Gender.male : Gender.female;
        final goalEnum = _fitnessGoalFromLabel(_goal);
        final profile = UserProfile(
          weight: _weight,
          height: _height,
          age: _age,
          gender: genderEnum,
          goal: goalEnum,
          intensity: IntensityLevel.balanced,
          activityLevel: ActivityLevel.moderatelyActive,
        );
        // Pass local _name and _email to Firestore
        final updatedUser = authState.user.copyWith(
          name: _name,
          email: _email,
          profile: profile,
        );
        await repo.updateProfile(updatedUser);
        // Also update Firebase Auth display name
        await authRepo.updateProfile(name: _name);
        // Update AuthBloc so navigation doesn't overwrite changes
        if (mounted) {
          context.read<AuthBloc>().add(AuthUserChanged(user: updatedUser));
        }
        // ignore: unnecessary_brace_in_string_interps — Cyrillic suffix requires braces
        appLogger.d('Профиль сохранен в Firestore: $_name, ${_weight}кг');
      }
    } catch (e) {
      appLogger.d('Ошибка сохранения профиля', error: e);
    }
  }

  WorkoutLocation _parseLocation(String s) {
    switch (s) {
      case 'outdoor':
        return WorkoutLocation.outdoor;
      case 'home':
        return WorkoutLocation.home;
      default:
        return WorkoutLocation.gym;
    }
  }

  RunningPreference _parseRunning(String s) => s == 'noRunning'
      ? RunningPreference.noRunning
      : RunningPreference.withRunning;

  FitnessGoal _fitnessGoalFromLabel(String label) {
    if (label == AppLocalizations.tl('goalMuscleMass')) {
      return FitnessGoal.gainWeight;
    }
    if (label == AppLocalizations.tl('goalMaintainWeight')) {
      return FitnessGoal.maintain;
    }
    if (label == AppLocalizations.tl('goalBeachSeason')) {
      return FitnessGoal.beachBody;
    }
    if (label == AppLocalizations.tl('goalSportsRecords')) {
      return FitnessGoal.sportPerformance;
    }
    return FitnessGoal.loseWeight;
  }

  String _fitnessGoalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.loseWeight:
        return AppLocalizations.tl('goalWeightLoss');
      case FitnessGoal.gainWeight:
        return AppLocalizations.tl('goalMuscleMass');
      case FitnessGoal.maintain:
        return AppLocalizations.tl('goalMaintainWeight');
      case FitnessGoal.beachBody:
        return AppLocalizations.tl('goalBeachSeason');
      case FitnessGoal.sportPerformance:
        return AppLocalizations.tl('goalSportsRecords');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            ProfileStatsRow(weight: _weight, height: _height, age: _age),
            const SizedBox(height: 20),
            ProfileCurrentProgram(
              goal: _localizeGoal(l10n, _goal),
              dataLoaded: _dataLoaded,
            ),
            const SizedBox(height: 20),
            _AchievementsSectionWidget(
              profileLevel: _profileLevel,
              unlockedIds: _profileUnlocked,
            ),
            const SizedBox(height: 24),
            _ProfileSection(
              title: l10n.yourDataLabel,
              items: [
                ProfileMenuItem(
                  icon: Icons.person_outline_rounded,
                  iconAsset: AppImages.personalData,
                  label: l10n.editProfileLabel,
                  color: colors.primary,
                  onTap: () => _openEditProfile(context),
                ),
                ProfileMenuItem(
                  icon: Icons.monitor_weight_outlined,
                  iconAsset: AppImages.weightTracker,
                  label: l10n.bodyParamsLabel,
                  color: colors.accentPurple,
                  onTap: () => _openBodyParams(context),
                ),
                ProfileMenuItem(
                  icon: Icons.flag_outlined,
                  iconAsset: AppImages.goal,
                  label: l10n.fitnessGoalLabel,
                  color: colors.accentOrange,
                  onTap: () => _openGoalEdit(context),
                ),
                ProfileMenuItem(
                  icon: Icons.location_on_outlined,
                  iconAsset: AppImages.location,
                  label: l10n.workoutLocationLabel,
                  color: colors.info,
                  onTap: () => _openWorkoutSettings(context),
                ),
                ProfileMenuItem(
                  icon: Icons.military_tech_outlined,
                  iconAsset: AppImages.achievements,
                  label: l10n.trainingExperienceLabel,
                  color: colors.accentPurple,
                  onTap: () => _openExperienceEdit(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: l10n.settingsLabel,
              items: [
                ProfileMenuItem(
                  icon: Icons.sync_rounded,
                  iconAsset: AppImages.bluetoothDevices,
                  label: l10n.healthConnectLabel,
                  color: const Color(0xFF10B981),
                  onTap: () => context.push('/health-sync'),
                ),
                ProfileMenuItem(
                  icon: Icons.notifications_outlined,
                  iconAsset: AppImages.notifications,
                  label: l10n.notificationsLabel,
                  color: colors.info,
                  onTap: () => _openNotifications(context),
                ),
                ProfileMenuItem(
                  icon: Icons.language_rounded,
                  iconAsset: AppImages.language,
                  label:
                      '${l10n.languageLabel} - ${LanguageService.current.nativeName}',
                  color: colors.accentPurple,
                  onTap: () => _openLanguageSelection(context),
                ),
                ProfileMenuItem(
                  icon: Icons.palette_outlined,
                  iconAsset: AppImages.appTheme,
                  label:
                      '${l10n.themeLabel} - ${ThemeService.current.displayName}',
                  color: colors.textSecondary,
                  onTap: () => _openThemeSelection(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: l10n.otherSectionLabel,
              items: [
                ProfileMenuItem(
                  icon: Icons.security_rounded,
                  iconAsset: AppImages.security,
                  label: l10n.securityLabel,
                  color: colors.warning,
                  onTap: () => _openSecurity(context),
                ),
                ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  iconAsset: AppImages.help,
                  label: l10n.helpSupportLabel,
                  color: colors.textMuted,
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.article_outlined,
                  iconAsset: AppImages.terms,
                  label: l10n.licensesLabel,
                  color: colors.textMuted,
                  onTap: () => _showLicenses(context),
                ),
                ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  iconAsset: AppImages.about,
                  label: l10n.aboutAppLabel,
                  color: colors.textMuted,
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LogoutButton(onTap: () => _confirmLogout(context)),
            const SizedBox(height: 12),
            DeleteAccountButton(onTap: () => _confirmDeleteAccount(context)),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'FitnesBuster v1.0.0',
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle(double size) {
    final colors = AppTheme.of(context);
    final fontSize = size * 0.4;

    if (_avatarCustomPath.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            File(_avatarCustomPath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _buildInitialsCircle(size, fontSize, colors),
          ),
        ),
      );
    }

    if (_avatarPresetIndex >= 0 && _avatarPresetIndex < kAvatarPresets.length) {
      final preset = kAvatarPresets[_avatarPresetIndex];
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: preset.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: preset.gradientColors.first.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            preset.iconAsset,
            width: size * 0.62,
            height: size * 0.62,
          ),
        ),
      );
    }

    return _buildInitialsCircle(size, fontSize, colors);
  }

  Widget _buildInitialsCircle(
    double size,
    double fontSize,
    ThemePalette colors,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: colors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: colors.textOnPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = AppTheme.of(context);
    return Row(
      children: [
        Stack(
          children: [
            _buildAvatarCircle(80),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _openAvatarPicker(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: colors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _email,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _dataLoaded ? context.l10n.activeProgram12week : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Actions ---

  void _openEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileEditSheet(
        name: _name,
        email: _email,
        avatarPresetIndex: _avatarPresetIndex,
        avatarCustomPath: _avatarCustomPath,
        onSave: (name, email) {
          setState(() {
            _name = name;
            _email = email;
          });
          _saveProfileToFirestore();
        },
        onAvatarTap: () {
          Navigator.of(context).pop();
          _openAvatarPicker(context);
        },
      ),
    );
  }

  void _openBodyParams(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final uid = authState is AuthStateAuthenticated ? authState.user.id : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BodyParamsSheet(
        weight: _weight,
        fetchLatestMeasurement: () async {
          if (uid == null) return null;
          final list = await sl<IUserRepository>().getMeasurements(uid);
          return list.isNotEmpty ? list.first : null;
        },
        onSave: (w, measurement) {
          setState(() => _weight = w);
          _saveProfileToFirestore();
          if (uid != null && measurement.hasData) {
            sl<IUserRepository>().saveMeasurement(
              userId: uid,
              measurement: measurement,
            );
          }
        },
      ),
    );
  }

  void _openGoalEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalEditSheet(
        goal: _goal,
        onSave: (g) {
          setState(() => _goal = g);
          _saveGoalAndRegeneratePlans(g);
        },
      ),
    );
  }

  void _openExperienceEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrainingExperienceEditSheet(
        experience: _trainingExperience,
        onSave: (exp) {
          setState(() => _trainingExperience = exp);
          _saveExperienceAndRegenerate(exp);
        },
      ),
    );
  }

  // Сохраняет стаж в Firestore и перегенерирует только тренировочный план
  // (стаж влияет на выбор методологии/объёма, не на питание).
  void _saveExperienceAndRegenerate(TrainingExperience exp) async {
    final uid =
        (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
    if (uid == null) return;
    try {
      await sl<IUserRepository>().updateTrainingExperience(
        userId: uid,
        trainingExperience: exp,
      );
      final freshUser = await sl<IUserRepository>().getUser(uid);
      if (!mounted) return;
      final profile = freshUser.profile;
      if (profile != null) {
        await _regeneratePlans(profile, includeMeal: false);
      }
    } catch (e) {
      appLogger.d('Training experience save error', error: e);
    }
  }

  void _openWorkoutSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutSettingsSheet(
        currentLocation: _workoutLocation,
        currentRunning: _runningPreference,
        onSave: (loc, run) {
          setState(() {
            _workoutLocation = loc;
            _runningPreference = run;
          });
          _saveWorkoutSettingsAndRegenerate(loc, run);
        },
      ),
    );
  }

  // Сохраняет новую цель в Firestore (точечное обновление) и запускает AI.
  void _saveGoalAndRegeneratePlans(String goalLabel) async {
    final uid =
        (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
    if (uid == null) return;
    try {
      final goalEnum = _fitnessGoalFromLabel(goalLabel);
      await sl<IUserRepository>().updateGoal(userId: uid, goal: goalEnum);
      // Читаем свежий профиль — в нём все поля (medicalRestrictions, location и т.д.)
      final freshUser = await sl<IUserRepository>().getUser(uid);
      if (!mounted) return;
      final profile = freshUser.profile;
      if (profile != null) {
        // Цель влияет и на тренировки, и на питание — перегенерируем оба плана
        await _regeneratePlans(profile, includeMeal: true);
      }
    } catch (e) {
      appLogger.d('Goal save error', error: e);
    }
  }

  // Сохраняет место/бег в Firestore и запускает AI только для тренировочного плана.
  void _saveWorkoutSettingsAndRegenerate(
    WorkoutLocation loc,
    RunningPreference run,
  ) async {
    final uid =
        (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
    if (uid == null) return;
    try {
      appLogger.d(
        '[WorkoutSettings] Saving location=${loc.name} running=${run.name}',
      );
      await sl<IUserRepository>().updateWorkoutSettings(
        userId: uid,
        location: loc.name,
        running: run.name,
      );
      final freshUser = await sl<IUserRepository>().getUser(uid);
      if (!mounted) return;
      final profile = freshUser.profile;
      appLogger.d(
        '[WorkoutSettings] Profile fetched, profile=${profile != null ? "OK" : "NULL"}',
      );
      if (profile != null) {
        await _regeneratePlans(profile, includeMeal: false);
      } else {
        appLogger.d('[WorkoutSettings] SKIP regeneration: profile is null');
      }
    } catch (e) {
      appLogger.d('WorkoutSettings save error', error: e);
    }
  }

  /// Best-effort чтение текущих показаний с устройства (сон/HRV/пульс) для
  /// передачи в AI как `recentHealth`; при отсутствии данных возвращает null.
  Future<HealthData?> _readRecentHealth() async {
    try {
      final hc = sl<IHealthConnectService>();
      await hc.initialize();
      final synced = await hc.readAllToday();
      return healthDataFromSynced(synced);
    } catch (e) {
      appLogger.d('[ProfileScreen] readRecentHealth failed', error: e);
      return null;
    }
  }

  // Показывает диалог прогресса, вызывает DeepSeek, сохраняет результат в Firestore.
  Future<void> _regeneratePlans(
    UserProfile profile, {
    bool includeMeal = false,
  }) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiProgressDialog(),
    );
    try {
      final uid =
          (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
      if (uid == null) return;
      final aiService = sl<IDeepSeekService>();
      final repo = sl<IUserRepository>();
      final recentHealth = await _readRecentHealth();
      final avgRpe = await recentAverageRpe();
      final doms = await todayDomsLevel();
      if (includeMeal) {
        final workoutJson = await aiService.generateWorkoutPlan(
          profile,
          recentHealth: recentHealth,
          recentAvgRpe: avgRpe,
          domsLevel: doms,
        );
        final mealJson = await aiService.generateMealPlan(profile);
        await repo.saveAiPlans(
          userId: uid,
          workoutPlanJson: workoutJson,
          mealPlanJson: mealJson,
        );
      } else {
        final workoutJson = await aiService.generateWorkoutPlan(
          profile,
          recentHealth: recentHealth,
          recentAvgRpe: avgRpe,
          domsLevel: doms,
        );
        appLogger.d(
          '[Regenerate] Workout plan generated, length=${workoutJson.length}',
        );
        await repo.updateWorkoutPlan(userId: uid, workoutPlanJson: workoutJson);
        appLogger.d('[Regenerate] Workout plan saved to HiveCache + Firestore');
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      WorkoutPlanScreen.planVersion.value++;
      showProfileSuccess(
        context,
        includeMeal
            ? AppLocalizations.tl('programAndMealsUpdated')
            : AppLocalizations.tl('workoutProgramUpdated'),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final colors = AppTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.tl('planUpdateFailed'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      appLogger.d('AI regeneration error', error: e);
    }
  }

  void _openLanguageSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageSelectionSheet(),
    );
  }

  void _openThemeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemeSelectionSheet(),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationsSheet(
        onRequestPermission: () => sl<SocialService>().requestFcmPermission(),
      ),
    );
  }

  void _openSecurity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SecuritySheet(),
    );
  }

  void _showLicenses(BuildContext context) {
    final colors = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                context.l10n.licensesLabel,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _LicenseBlock(
                title: 'Z-Anatomy',
                body:
                    'Анатомические 3D-модели в приложении созданы на основе проекта Z-Anatomy и адаптированы для использования в FitnesBuster.\n\n'
                    '© Z-Anatomy Project\n'
                    'Лицензия: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)\n'
                    'https://www.z-anatomy.com/\n\n'
                    'Внесённые изменения: модели экспортированы в формат GLB, применено Draco-сжатие, '
                    'добавлена двусторонняя подсветка мышц и X-ray эффект для нужд приложения.\n\n'
                    'Производные материалы распространяются на условиях CC BY-SA 4.0.',
                colors: colors,
              ),
              const SizedBox(height: 20),
              _LicenseBlock(
                title: 'Прочие компоненты',
                body:
                    'Приложение использует пакеты с открытым исходным кодом. '
                    'Полный список лицензий доступен в исходном коде проекта (pubspec.yaml).',
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final colors = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'FitnesBuster',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FitnesBuster — твой персональный AI-тренер и диетолог в смартфоне. '
                'Приложение генерирует персонализированные тренировочные программы '
                'на основе твоего профиля, целей, уровня подготовки, доступного '
                'оборудования и медицинских ограничений.\n\n'
                'Встроенный AI-нутрициолог составляет детальные планы питания '
                'с точной граммовкой, таймингом приёмов пищи и расчётом макронутриентов. '
                'Приложение учитывает данные о сне, сердечном ритме и дневной активности '
                'через интеграцию с Health Connect.\n\n'
                'Поддерживаются все популярные форматы тренировок: зал, улица, дом. '
                'Встроенный таймер с голосовым сопровождением, отслеживание подходов, '
                'весов и личных рекордов. Система испытательных недель калибрует '
                'нагрузку под реальные возможности пользователя.\n\n'
                'Челленджи, еженедельные дебрифы и анализ прогресса по замерам тела '
                'помогают сохранять мотивацию и видеть результаты.',
                style: TextStyle(
                  color: colors.textSecondary,
                  height: 1.55,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 1,
                color: colors.textMuted.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                'Разработчик: Югов Максим',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text('OK', style: TextStyle(color: colors.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.logoutTitle,
          style: TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          l10n.logoutBody,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              l10n.logoutBtn,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localizeGoal(AppLocalizations l10n, String goal) {
    return switch (goal) {
      'Похудение веса' => l10n.goalWeightLoss,
      'Набор массы' => l10n.goalMuscleMass,
      'Поддержание веса' => l10n.goalMaintainWeight,
      'К пляжному сезону' => l10n.goalBeachSeason,
      'Спортивные рекорды' => l10n.goalSportsRecords,
      _ => goal,
    };
  }

  void _confirmDeleteAccount(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.deleteAccountBtn,
          style: TextStyle(
            fontFamily: 'Syne',
            fontWeight: FontWeight.w800,
            color: colors.error,
          ),
        ),
        content: Text(
          l10n.deleteAccountConfirm,
          style: TextStyle(color: colors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _handleDeleteAccount(context);
            },
            child: Text(
              l10n.delete,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String? errorMessage;
    try {
      await sl<IAuthRepository>().deleteAccount();
      // Firebase Auth flips to signed-out here; AuthBloc's userChanges
      // subscription picks it up and the router redirects to /login.
    } catch (e, st) {
      appLogger.w(
        'ProfileScreen: deleteAccount failed',
        error: e,
        stackTrace: st,
      );
      errorMessage = AppLocalizations.tl('genericError');
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (errorMessage != null) {
      final colors = AppTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

// ── Extracted StatelessWidget helpers ────────────────────────────────────────

class _LicenseBlock extends StatelessWidget {
  final String title;
  final String body;
  final ThemePalette colors;
  const _LicenseBlock({
    required this.title,
    required this.body,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textMuted.withValues(alpha: 0.15)),
      ),
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
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  final double weight;
  final double height;
  final int age;
  const ProfileStatsRow({
    super.key,
    required this.weight,
    required this.height,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: StatBox(
            label: l10n.weightLabel,
            number: weight.toStringAsFixed(1),
            unit: l10n.dashboardKg,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBox(
            label: 'Рост',
            number: '${height.toInt()}',
            unit: l10n.cmUnit,
            color: colors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBox(
            label: 'BMI',
            number: height > 0
                ? (weight / ((height / 100) * (height / 100))).toStringAsFixed(
                    1,
                  )
                : '-',
            unit: '',
            color: colors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBox(
            label: l10n.ageLabel,
            number: '$age',
            unit: l10n.yearsUnit,
            color: colors.accentOrange,
          ),
        ),
      ],
    );
  }
}

class ProfileCurrentProgram extends StatelessWidget {
  final String goal;
  final bool dataLoaded;
  const ProfileCurrentProgram({
    super.key,
    required this.goal,
    required this.dataLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accentPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: colors.accentPurple,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.activeProgramLabel,
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  goal,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0,
                    backgroundColor: colors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.accentPurple,
                    ),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dataLoaded ? context.l10n.fillProfileProgress : '',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/workout'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: colors.accentPurple,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSectionWidget extends StatelessWidget {
  final UserLevel? profileLevel;
  final Set<String> unlockedIds;
  const _AchievementsSectionWidget({
    required this.profileLevel,
    required this.unlockedIds,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final lvl = profileLevel;
    final unlocked = unlockedIds;

    // Pick up to 6 most-recently unlocked achievements to show as badges
    final allIds = GamificationService.allAchievements
        .map((a) => a.id)
        .toList();
    final unlockedOrdered = allIds
        .where((id) => unlocked.contains(id))
        .toList();
    final preview = unlockedOrdered.take(6).map((id) {
      return GamificationService.allAchievements.firstWhere((a) => a.id == id);
    }).toList();

    return GestureDetector(
      onTap: () => context.push(AppRouter.achievements),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary.withValues(alpha: 0.12), colors.elevated],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  lvl?.icon ?? AppImages.levelIcons.first,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lvl != null
                            ? 'Ур. ${lvl.level} · ${lvl.name}'
                            : 'Загрузка...',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (lvl != null)
                        Text(
                          '${lvl.totalXp} XP · ${unlocked.length} / ${GamificationService.allAchievements.length} значков',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      context.l10n.allBadgesBtn,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
            if (lvl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: lvl.progress,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  minHeight: 4,
                ),
              ),
            ],
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: preview
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.asset(
                          a.icon,
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.earnBadgesHint,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<ProfileMenuItem> items;
  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleM),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      GestureDetector(
                        onTap: e.value.onTap ?? () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: e.value.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: e.value.iconAsset != null
                                    ? AppIcon(
                                        asset: e.value.iconAsset!,
                                        glowColor: e.value.color,
                                        size: 42,
                                      )
                                    : Icon(
                                        e.value.icon,
                                        color: e.value.color,
                                        size: 26,
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  e.value.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (e.key < items.length - 1)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.04),
                          indent: 66,
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String? iconAsset;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const ProfileMenuItem({
    required this.icon,
    this.iconAsset,
    required this.label,
    required this.color,
    this.onTap,
  });
}
