import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/presentation/screens/onboarding/workout_location_screen.dart';
import 'package:fitnesbuster/presentation/screens/profile/workout_settings_sheet.dart';
import 'package:fitnesbuster/presentation/screens/workout/workout_plan_screen.dart';
import 'package:fitnesbuster/presentation/widgets/language_selection_sheet.dart';
import 'package:fitnesbuster/presentation/widgets/theme_selection_sheet.dart';
import 'package:fitnesbuster/core/localization/language_service.dart';
import 'package:fitnesbuster/core/theme/theme_service.dart';
import 'package:fitnesbuster/core/services/gamification_service.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

// ── Preset avatar definitions ────────────────────────────────────────────────
class _AvatarPreset {
  final String emoji;
  final String label;
  final List<Color> gradientColors;
  const _AvatarPreset(this.emoji, this.label, this.gradientColors);
}

const List<_AvatarPreset> _kPresets = [
  _AvatarPreset('🏋️', 'Атлет',      [Color(0xFF6C63FF), Color(0xFF3D5AFE)]),
  _AvatarPreset('🏃', 'Бегун',      [Color(0xFF00BFA5), Color(0xFF00695C)]),
  _AvatarPreset('🧘', 'Йога',       [Color(0xFFAB47BC), Color(0xFF6A1B9A)]),
  _AvatarPreset('🚴', 'Велосипед',  [Color(0xFFFF7043), Color(0xFFBF360C)]),
  _AvatarPreset('🥊', 'Бокс',       [Color(0xFFEF5350), Color(0xFFB71C1C)]),
  _AvatarPreset('🏊', 'Плавание',   [Color(0xFF29B6F6), Color(0xFF01579B)]),
  _AvatarPreset('🧗', 'Скалолаз',   [Color(0xFFFFCA28), Color(0xFFE65100)]),
  _AvatarPreset('🤸', 'Гимнастика', [Color(0xFFEC407A), Color(0xFF880E4F)]),
  _AvatarPreset('⚡', 'Энергия',    [Color(0xFF26C6DA), Color(0xFF006064)]),
  _AvatarPreset('🏆', 'Чемпион',    [Color(0xFF66BB6A), Color(0xFF1B5E20)]),
];

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
  bool _dataLoaded = false;

  // ── Gamification ────────────────────────────────────────────────────────────
  UserLevel? _profileLevel;
  Set<String> _profileUnlocked = {};

  // ── Avatar ──────────────────────────────────────────────────────────────────
  int _avatarPresetIndex = -1;   // -1 = use initials
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
      setState(() { _avatarPresetIndex = idx; _avatarCustomPath = ''; });
    } else if (mode == 'custom') {
      final path = await settings.getAvatarCustomPath() ?? '';
      if (path.isNotEmpty && File(path).existsSync()) {
        setState(() { _avatarCustomPath = path; _avatarPresetIndex = -1; });
      }
    }
  }

  Future<void> _saveAvatarPreset(int index) async {
    final settings = sl<ISettingsRepository>();
    await settings.setAvatarMode('preset');
    await settings.setAvatarPresetIndex(index);
    await settings.removeAvatarCustomPath();
    if (mounted) setState(() { _avatarPresetIndex = index; _avatarCustomPath = ''; });
  }

  Future<void> _saveAvatarCustom(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/avatar_custom.jpg';
    await File(sourcePath).copy(dest);
    final settings = sl<ISettingsRepository>();
    await settings.setAvatarMode('custom');
    await settings.setAvatarCustomPath(dest);
    await settings.setAvatarPresetIndex(-1);
    if (mounted) setState(() { _avatarCustomPath = dest; _avatarPresetIndex = -1; });
  }

  void _openAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPickerSheet(
        currentPresetIndex: _avatarPresetIndex,
        currentCustomPath: _avatarCustomPath,
        onPresetSelected: (i) { Navigator.of(context).pop(); _saveAvatarPreset(i); },
        onCustomSelected: (path) { Navigator.of(context).pop(); _saveAvatarCustom(path); },
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
        _gender = user.profile?.gender == Gender.male ? 'Мужской' : (user.profile?.gender == Gender.female ? 'Женский' : '');
        _goal = user.profile?.goal != null ? _fitnessGoalLabel(user.profile!.goal) : '';
        _dataLoaded = true;
      });
    }
    // Step 2: always refresh from Firestore to pick up onboarding data
    _refreshFromFirestore();
  }

  Future<void> _refreshFromFirestore() async {
    final uid = (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
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
            _runningPreference = _parseRunning(user.profile!.runningPreference!);
          }
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
          weight: _weight, height: _height, age: _age,
          gender: genderEnum, goal: goalEnum,
          intensity: IntensityLevel.balanced,
          activityLevel: ActivityLevel.moderatelyActive,
        );
        // Pass local _name and _email to Firestore
        final updatedUser = authState.user.copyWith(
          name: _name, email: _email, profile: profile,
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
      case 'outdoor': return WorkoutLocation.outdoor;
      case 'home': return WorkoutLocation.home;
      default: return WorkoutLocation.gym;
    }
  }

  RunningPreference _parseRunning(String s) =>
      s == 'noRunning' ? RunningPreference.noRunning : RunningPreference.withRunning;

  FitnessGoal _fitnessGoalFromLabel(String label) {
    if (label == AppLocalizations.tl('goalMuscleMass')) return FitnessGoal.gainWeight;
    if (label == AppLocalizations.tl('goalMaintainWeight')) return FitnessGoal.maintain;
    if (label == AppLocalizations.tl('goalBeachSeason')) return FitnessGoal.beachBody;
    if (label == AppLocalizations.tl('goalSportsRecords')) return FitnessGoal.sportPerformance;
    return FitnessGoal.loseWeight;
  }

  String _fitnessGoalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.loseWeight: return AppLocalizations.tl('goalWeightLoss');
      case FitnessGoal.gainWeight: return AppLocalizations.tl('goalMuscleMass');
      case FitnessGoal.maintain: return AppLocalizations.tl('goalMaintainWeight');
      case FitnessGoal.beachBody: return AppLocalizations.tl('goalBeachSeason');
      case FitnessGoal.sportPerformance: return AppLocalizations.tl('goalSportsRecords');
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
            _StatsRowWidget(weight: _weight, height: _height, age: _age),
            const SizedBox(height: 20),
            _CurrentProgramWidget(goal: _localizeGoal(l10n, _goal), dataLoaded: _dataLoaded),
            const SizedBox(height: 20),
            _AchievementsSectionWidget(profileLevel: _profileLevel, unlockedIds: _profileUnlocked),
            const SizedBox(height: 24),
            _ProfileSection(title: l10n.yourDataLabel, items: [
              _MenuItem(icon: Icons.person_outline_rounded, label: l10n.editProfileLabel, color: colors.primary, onTap: () => _openEditProfile(context)),
              _MenuItem(icon: Icons.monitor_weight_outlined, label: l10n.bodyParamsLabel, color: colors.accentPurple, onTap: () => _openBodyParams(context)),
              _MenuItem(icon: Icons.flag_outlined, label: l10n.fitnessGoalLabel, color: colors.accentOrange, onTap: () => _openGoalEdit(context)),
              _MenuItem(icon: Icons.location_on_outlined, label: l10n.workoutLocationLabel, color: colors.info, onTap: () => _openWorkoutSettings(context)),
            ]),
            const SizedBox(height: 16),
            _ProfileSection(title: l10n.settingsLabel, items: [
              _MenuItem(icon: Icons.sync_rounded, label: l10n.healthConnectLabel, color: const Color(0xFF10B981), onTap: () => context.push('/health-sync')),
              _MenuItem(icon: Icons.notifications_outlined, label: l10n.notificationsLabel, color: colors.info, onTap: () => _openNotifications(context)),
              _MenuItem(icon: Icons.language_rounded, label: '${l10n.languageLabel} - ${LanguageService.current.nativeName}', color: colors.accentPurple, onTap: () => _openLanguageSelection(context)),
              _MenuItem(icon: Icons.palette_outlined, label: '${l10n.themeLabel} - ${ThemeService.current.displayName}', color: colors.textSecondary, onTap: () => _openThemeSelection(context)),
            ]),
            const SizedBox(height: 16),
            _ProfileSection(title: l10n.otherSectionLabel, items: [
              _MenuItem(icon: Icons.security_rounded, label: l10n.securityLabel, color: colors.warning, onTap: () => _openSecurity(context)),
              _MenuItem(icon: Icons.help_outline_rounded, label: l10n.helpSupportLabel, color: colors.textMuted, onTap: () {}),
              _MenuItem(icon: Icons.article_outlined, label: l10n.licensesLabel, color: colors.textMuted, onTap: () => _showLicenses(context)),
              _MenuItem(icon: Icons.info_outline_rounded, label: l10n.aboutAppLabel, color: colors.textMuted, onTap: () => _showAbout(context)),
            ]),
            const SizedBox(height: 16),
            _LogoutButton(onTap: () => _confirmLogout(context)),
            const SizedBox(height: 12),
            _DeleteAccountButton(onTap: () => _confirmDeleteAccount(context)),
            const SizedBox(height: 24),
            Center(child: Text('FitnesBuster v1.0.0', style: TextStyle(fontSize: 11, color: colors.textMuted))),
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
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2)],
        ),
        child: ClipOval(
          child: Image.file(File(_avatarCustomPath), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitialsCircle(size, fontSize, colors)),
        ),
      );
    }

    if (_avatarPresetIndex >= 0 && _avatarPresetIndex < _kPresets.length) {
      final preset = _kPresets[_avatarPresetIndex];
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: preset.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: preset.gradientColors.first.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 2)],
        ),
        child: Center(child: Text(preset.emoji, style: TextStyle(fontSize: fontSize * 1.1))),
      );
    }

    return _buildInitialsCircle(size, fontSize, colors);
  }

  Widget _buildInitialsCircle(double size, double fontSize, ThemePalette colors) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: colors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 4)],
      ),
      child: Center(child: Text(
        _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
        style: TextStyle(fontFamily: 'Syne', fontSize: fontSize, fontWeight: FontWeight.w800, color: colors.textOnPrimary),
      )),
    );
  }

  Widget _buildHeader() {
    final colors = AppTheme.of(context);
    return Row(
      children: [
        Stack(children: [
          _buildAvatarCircle(80),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: () => _openAvatarPicker(context),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.background, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
                ),
                child: Icon(Icons.camera_alt_rounded, size: 14, color: colors.textOnPrimary),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_name, style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(_email, style: TextStyle(fontSize: 13, color: colors.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(_dataLoaded ? context.l10n.activeProgram12week : '', style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w700)),
          ),
        ])),
      ],
    );
  }

  // --- Actions ---

  void _openEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        name: _name, email: _email,
        avatarPresetIndex: _avatarPresetIndex,
        avatarCustomPath: _avatarCustomPath,
        onSave: (name, email) {
          setState(() { _name = name; _email = email; });
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BodyParamsSheet(
        weight: _weight, height: _height, age: _age, gender: _gender,
        onSave: (w, h, a, g) {
          setState(() { _weight = w; _height = h; _age = a; _gender = g; });
          _saveProfileToFirestore();
        },
      ),
    );
  }

  void _openGoalEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalEditSheet(
        currentGoal: _goal,
        onSave: (g) {
          setState(() => _goal = g);
          _saveGoalAndRegeneratePlans(g);
        },
      ),
    );
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
    final uid = (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
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
  void _saveWorkoutSettingsAndRegenerate(WorkoutLocation loc, RunningPreference run) async {
    final uid = (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
    if (uid == null) return;
    try {
      appLogger.d('[WorkoutSettings] Saving location=${loc.name} running=${run.name}');
      await sl<IUserRepository>().updateWorkoutSettings(
        userId: uid, location: loc.name, running: run.name,
      );
      final freshUser = await sl<IUserRepository>().getUser(uid);
      if (!mounted) return;
      final profile = freshUser.profile;
      appLogger.d('[WorkoutSettings] Profile fetched, profile=${profile != null ? "OK" : "NULL"}');
      if (profile != null) {
        await _regeneratePlans(profile, includeMeal: false);
      } else {
        appLogger.d('[WorkoutSettings] SKIP regeneration: profile is null');
      }
    } catch (e) {
      appLogger.d('WorkoutSettings save error', error: e);
    }
  }

  // Показывает диалог прогресса, вызывает DeepSeek, сохраняет результат в Firestore.
  Future<void> _regeneratePlans(UserProfile profile, {bool includeMeal = false}) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AiProgressDialog(),
    );
    try {
      final uid = (context.read<AuthBloc>().state as AuthStateAuthenticated?)?.user.id;
      if (uid == null) return;
      final aiService = sl<IDeepSeekService>();
      final repo = sl<IUserRepository>();
      if (includeMeal) {
        final workoutJson = await aiService.generateWorkoutPlan(profile);
        final mealJson = await aiService.generateMealPlan(profile);
        await repo.saveAiPlans(
          userId: uid, workoutPlanJson: workoutJson, mealPlanJson: mealJson,
        );
      } else {
        final workoutJson = await aiService.generateWorkoutPlan(profile);
        appLogger.d('[Regenerate] Workout plan generated, length=${workoutJson.length}');
        await repo.updateWorkoutPlan(userId: uid, workoutPlanJson: workoutJson);
        appLogger.d('[Regenerate] Workout plan saved to HiveCache + Firestore');
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      WorkoutPlanScreen.planVersion.value++;
      _showSuccess(
        context,
        includeMeal ? AppLocalizations.tl('programAndMealsUpdated') : AppLocalizations.tl('workoutProgramUpdated'),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final colors = AppTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(AppLocalizations.tl('planUpdateFailed'), style: TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
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
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _openSecurity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SecuritySheet(),
    );
  }

  void _showLicenses(BuildContext context) {
    final colors = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: colors.textMuted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            Text(context.l10n.licensesLabel, style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 24),
            _LicenseBlock(
              title: 'Z-Anatomy',
              body: 'Анатомические 3D-модели в приложении созданы на основе проекта Z-Anatomy и адаптированы для использования в FitnesBuster.\n\n'
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
              body: 'Приложение использует пакеты с открытым исходным кодом. '
                  'Полный список лицензий доступен в исходном коде проекта (pubspec.yaml).',
              colors: colors,
            ),
          ]),
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
              child: Text('FitnesBuster', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: colors.textPrimary), softWrap: false, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text('v1.0.0', style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w500)),
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
                style: TextStyle(color: colors.textSecondary, height: 1.55, fontSize: 13),
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
                style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text('OK', style: TextStyle(color: colors.primary)))],
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
        title: Text('Выйти?', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: colors.textPrimary)),
        content: Text('Данные сохранятся и вы сможете войти снова.', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(l10n.cancel, style: TextStyle(color: colors.textMuted))),
          TextButton(onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            }, child: Text(l10n.logoutBtn, style: TextStyle(color: colors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  String _localizeGoal(AppLocalizations l10n, String goal) {
    return switch (goal) {
      'Похудение веса'    => l10n.goalWeightLoss,
      'Набор массы'       => l10n.goalMuscleMass,
      'Поддержание веса'  => l10n.goalMaintainWeight,
      'К пляжному сезону' => l10n.goalBeachSeason,
      'Спортивные рекорды'=> l10n.goalSportsRecords,
      _                   => goal,
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
        title: Text(l10n.deleteAccountConfirm, style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, color: colors.error)),
        content: Text('Это действие необратимо. Все данные, история и тренировки будут удалены навсегда.', style: TextStyle(color: colors.textSecondary, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(l10n.cancel, style: TextStyle(color: colors.textMuted))),
          TextButton(onPressed: () { context.go('/login'); }, child: Text(l10n.delete, style: TextStyle(color: colors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ── Extracted StatelessWidget helpers ────────────────────────────────────────

class _LicenseBlock extends StatelessWidget {
  final String title;
  final String body;
  final ThemePalette colors;
  const _LicenseBlock({required this.title, required this.body, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textMuted.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 10),
        Text(body, style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.6)),
      ]),
    );
  }
}

class _StatsRowWidget extends StatelessWidget {
  final double weight;
  final double height;
  final int age;
  const _StatsRowWidget({required this.weight, required this.height, required this.age});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(children: [
      Expanded(child: _StatBox(label: l10n.weightLabel, value: '${weight.toStringAsFixed(1)} ${l10n.dashboardKg}')),
      const SizedBox(width: 10),
      Expanded(child: _StatBox(label: l10n.onbHeightTitle, value: '${height.toInt()} ${l10n.cmUnit}')),
      const SizedBox(width: 10),
      Expanded(child: _StatBox(label: 'BMI', value: height > 0 ? (weight / ((height / 100) * (height / 100))).toStringAsFixed(1) : '-')),
      const SizedBox(width: 10),
      Expanded(child: _StatBox(label: l10n.ageLabel, value: '$age ${l10n.yearsUnit}')),
    ]);
  }
}

class _CurrentProgramWidget extends StatelessWidget {
  final String goal;
  final bool dataLoaded;
  const _CurrentProgramWidget({required this.goal, required this.dataLoaded});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accentPurple.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.bolt_rounded, color: colors.accentPurple, size: 16),
            const SizedBox(width: 6),
            Text(context.l10n.activeProgramLabel, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          ]),
          const SizedBox(height: 6),
          Text(goal, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: 0, backgroundColor: colors.surfaceLight, valueColor: AlwaysStoppedAnimation<Color>(colors.accentPurple), minHeight: 5),
          ),
          const SizedBox(height: 4),
          Text(dataLoaded ? context.l10n.fillProfileProgress : '', style: TextStyle(fontSize: 11, color: colors.textMuted)),
        ])),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.go('/workout'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentPurple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.arrow_forward_rounded, color: colors.accentPurple, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _AchievementsSectionWidget extends StatelessWidget {
  final UserLevel? profileLevel;
  final Set<String> unlockedIds;
  const _AchievementsSectionWidget({required this.profileLevel, required this.unlockedIds});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final lvl = profileLevel;
    final unlocked = unlockedIds;

    // Pick up to 6 most-recently unlocked achievements to show as badges
    final allIds = GamificationService.allAchievements.map((a) => a.id).toList();
    final unlockedOrdered = allIds.where((id) => unlocked.contains(id)).toList();
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              lvl?.emoji ?? '🌱',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                lvl != null ? 'Ур. ${lvl.level} · ${lvl.name}' : 'Загрузка...',
                style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              if (lvl != null)
                Text(
                  '${lvl.totalXp} XP · ${unlocked.length} / ${GamificationService.allAchievements.length} значков',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
            ])),
            Row(children: [
              Text(context.l10n.allBadgesBtn, style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, color: colors.primary, size: 18),
            ]),
          ]),
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
            Row(children: preview.map((a) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(a.emoji, style: const TextStyle(fontSize: 22)),
            )).toList()),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.earnBadgesHint,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.titleM),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: items.asMap().entries.map((e) => Column(children: [
            GestureDetector(
              onTap: e.value.onTap ?? () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: e.value.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(e.value.icon, color: e.value.color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(e.value.label, style: TextStyle(fontSize: 15, color: colors.textPrimary, fontWeight: FontWeight.w500))),
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
                ]),
              ),
            ),
            if (e.key < items.length - 1)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.04), indent: 66),
          ])).toList(),
        ),
      ),
    ]);
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.error.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout_rounded, color: colors.error, size: 20),
          const SizedBox(width: 10),
          Text(l10n.logoutBtn, style: TextStyle(color: colors.error, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteAccountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Text(l10n.deleteAccountBtn, style: TextStyle(color: colors.textMuted, fontSize: 13, decoration: TextDecoration.underline)),
      ),
    );
  }
}

// --- Edit Profile Sheet ---
class _EditProfileSheet extends StatefulWidget {
  final String name, email;
  final int avatarPresetIndex;
  final String avatarCustomPath;
  final Function(String, String) onSave;
  final VoidCallback onAvatarTap;

  const _EditProfileSheet({
    required this.name,
    required this.email,
    required this.avatarPresetIndex,
    required this.avatarCustomPath,
    required this.onSave,
    required this.onAvatarTap,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
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
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Widget _buildAvatar(ThemePalette colors) {
    const size = 80.0;
    Widget circle;

    if (widget.avatarCustomPath.isNotEmpty) {
      circle = ClipOval(
        child: Image.file(File(widget.avatarCustomPath),
            width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackCircle(size, colors)),
      );
    } else if (widget.avatarPresetIndex >= 0 && widget.avatarPresetIndex < _kPresets.length) {
      final p = _kPresets[widget.avatarPresetIndex];
      circle = Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: p.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 34))),
      );
    } else {
      circle = _fallbackCircle(size, colors);
    }

    return Stack(children: [
      circle,
      Positioned(bottom: 0, right: 0, child: GestureDetector(
        onTap: widget.onAvatarTap,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle, border: Border.all(color: colors.surface, width: 2)),
          child: Icon(Icons.edit_rounded, size: 12, color: colors.textOnPrimary),
        ),
      )),
    ]);
  }

  Widget _fallbackCircle(double size, ThemePalette colors) => Container(
    width: size, height: size,
    decoration: BoxDecoration(gradient: colors.primaryGradient, shape: BoxShape.circle),
    child: Center(child: Text(
      widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U',
      style: TextStyle(fontFamily: 'Syne', fontSize: 32, fontWeight: FontWeight.w800, color: colors.textOnPrimary),
    )),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return _SheetWrapper(
      title: l10n.editProfileLabel,
      child: Form(
        key: _formKey,
        child: Column(children: [
          Center(child: _buildAvatar(colors)),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: widget.onAvatarTap,
            icon: Icon(Icons.photo_camera_rounded, size: 15, color: colors.primary),
            label: Text(l10n.changeAvatar, style: TextStyle(fontSize: 13, color: colors.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          _SheetField(controller: _nameCtrl, label: l10n.nameLabel, icon: Icons.person_outline_rounded, validator: (v) => v!.trim().isEmpty ? l10n.enterNameValidation : null),
          const SizedBox(height: 14),
          _SheetField(
            controller: _emailCtrl,
            label: l10n.emailLabel,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.enterEmailValidation;
              if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) return l10n.invalidEmailFormat;
              return null;
            },
          ),
          const SizedBox(height: 24),
          _SaveButton(onTap: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(_nameCtrl.text.trim(), _emailCtrl.text.trim());
              Navigator.of(context).pop();
              _showSuccess(context, l10n.profileUpdated);
            }
          }),
        ]),
      ),
    );
  }
}

// --- Body Params Sheet ---
class _BodyParamsSheet extends StatefulWidget {
  final double weight, height;
  final int age;
  final String gender;
  final Function(double, double, int, String) onSave;
  const _BodyParamsSheet({required this.weight, required this.height, required this.age, required this.gender, required this.onSave});
  @override State<_BodyParamsSheet> createState() => _BodyParamsSheetState();
}

class _BodyParamsSheetState extends State<_BodyParamsSheet> {
  late double _weight;
  late double _height;
  late int _age;
  late String _gender;

  @override
  void initState() {
    super.initState();
    _weight = widget.weight; _height = widget.height;
    _age = widget.age; _gender = widget.gender;
  }

  double get _bmi {
    if (_height <= 0) return 0;
    final h = _height / 100;
    return _weight / (h * h);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return _SheetWrapper(
      title: l10n.bodyParamsSheetTitle,
      child: Column(children: [
        // Gender
        Row(children: [l10n.genderMale, l10n.genderFemale].map((g) {
          final sel = _gender == g;
          return Expanded(child: Padding(
            padding: EdgeInsets.only(right: g == l10n.genderMale ? 8 : 0, left: g == l10n.genderFemale ? 8 : 0),
            child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _gender = g); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: sel ? colors.primary.withValues(alpha: 0.15) : colors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? colors.primary : Colors.white.withValues(alpha: 0.06), width: sel ? 2 : 1),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(g == l10n.genderMale ? '👨' : '👩', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(g, style: TextStyle(color: sel ? colors.primary : colors.textSecondary, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 20),
        _NumSlider(label: l10n.weightLabel, value: _weight, min: 40, max: 200, unit: l10n.dashboardKg, onChanged: (v) => setState(() => _weight = v)),
        const SizedBox(height: 16),
        _NumSlider(label: l10n.onbHeightTitle, value: _height, min: 140, max: 220, unit: l10n.cmUnit, onChanged: (v) => setState(() => _height = v)),
        const SizedBox(height: 16),
        _NumSlider(label: l10n.ageLabel, value: _age.toDouble(), min: 14, max: 80, unit: l10n.yearsUnit, decimals: 0, onChanged: (v) => setState(() => _age = v.round())),
        const SizedBox(height: 16),
        // BMI live
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bmiColor(_bmi).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _bmiColor(_bmi).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Text('BMI: ${_bmi.toStringAsFixed(1)}', style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: _bmiColor(_bmi))),
            const SizedBox(width: 12),
            Text(_bmiLabel(l10n, _bmi), style: TextStyle(color: _bmiColor(_bmi), fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 24),
        _SaveButton(onTap: () {
          widget.onSave(_weight, _height, _age, _gender);
          Navigator.of(context).pop();
          _showSuccess(context, 'Параметры сохранены');
        }),
      ]),
    );
  }

  Color _bmiColor(double bmi) {
    final colors = AppTheme.of(context);
    if (bmi < 18.5) return colors.info;
    if (bmi < 25) return colors.success;
    if (bmi < 30) return colors.warning;
    return colors.error;
  }

  String _bmiLabel(AppLocalizations l10n, double bmi) {
    if (bmi < 18.5) return l10n.bmiUnderweight;
    if (bmi < 25) return '${l10n.bmiNormal} 💪';
    if (bmi < 30) return l10n.bmiOverweight;
    return l10n.bmiObese;
  }
}

// --- Goal Edit Sheet ---
class _GoalEditSheet extends StatefulWidget {
  final String currentGoal;
  final Function(String) onSave;
  const _GoalEditSheet({required this.currentGoal, required this.onSave});
  @override State<_GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<_GoalEditSheet> {
  late String _selected;
  // label — русский ключ, используется для сохранения в Firestore
  final List<Map<String, String>> _goals = [
    {'label': 'Похудение веса', 'emoji': '🔥'},
    {'label': 'Набор массы', 'emoji': '💪'},
    {'label': 'Поддержание веса', 'emoji': '⚖️'},
    {'label': 'К пляжному сезону', 'emoji': '🏖️'},
    {'label': 'Спортивные рекорды', 'emoji': '🏆'},
  ];

  String _localizeGoal(AppLocalizations l10n, String goal) {
    return switch (goal) {
      'Похудение веса'    => l10n.goalWeightLoss,
      'Набор массы'       => l10n.goalMuscleMass,
      'Поддержание веса'  => l10n.goalMaintainWeight,
      'К пляжному сезону' => l10n.goalBeachSeason,
      'Спортивные рекорды'=> l10n.goalSportsRecords,
      _                   => goal,
    };
  }

  @override void initState() { super.initState(); _selected = widget.currentGoal; }
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return _SheetWrapper(
      title: l10n.fitnessGoalSheetTitle,
      child: Column(children: [
        ..._goals.map((g) {
          final sel = _selected == g['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selected = g['label']!); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? colors.primary.withValues(alpha: 0.12) : colors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? colors.primary : Colors.white.withValues(alpha: 0.06), width: sel ? 2 : 1),
                ),
                child: Row(children: [
                  Text(g['emoji']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(_localizeGoal(l10n, g['label']!), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: sel ? colors.primary : colors.textPrimary))),
                  if (sel) Icon(Icons.check_circle_rounded, color: colors.primary, size: 22),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _SaveButton(onTap: () { widget.onSave(_selected); Navigator.of(context).pop(); _showSuccess(context, l10n.save); }),
      ]),
    );
  }
}

// --- Avatar Picker Sheet ---
class _AvatarPickerSheet extends StatefulWidget {
  final int currentPresetIndex;
  final String currentCustomPath;
  final ValueChanged<int> onPresetSelected;
  final ValueChanged<String> onCustomSelected;

  const _AvatarPickerSheet({
    required this.currentPresetIndex,
    required this.currentCustomPath,
    required this.onPresetSelected,
    required this.onCustomSelected,
  });

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late int _selected;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPresetIndex;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (xfile != null && mounted) {
        widget.onCustomSelected(xfile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Не удалось выбрать фото: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Выбор аватарки', style: AppTextStyles.titleL),
        const SizedBox(height: 20),

        // Upload buttons
        Row(children: [
          Expanded(child: _SourceButton(
            icon: Icons.camera_alt_rounded,
            label: 'Камера',
            color: colors.primary,
            onTap: _picking ? null : () => _pickImage(ImageSource.camera),
          )),
          const SizedBox(width: 12),
          Expanded(child: _SourceButton(
            icon: Icons.photo_library_rounded,
            label: 'Галерея',
            color: colors.accentPurple,
            onTap: _picking ? null : () => _pickImage(ImageSource.gallery),
          )),
        ]),

        // Current custom photo preview
        if (widget.currentCustomPath.isNotEmpty && File(widget.currentCustomPath).existsSync()) ...[
          const SizedBox(height: 16),
          Row(children: [
            const Text('Ваше фото:', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(width: 12),
            ClipOval(
              child: Image.file(File(widget.currentCustomPath),
                  width: 46, height: 46, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
              ),
              child: Text('Активно', style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.w700)),
            ),
          ]),
        ],

        const SizedBox(height: 20),
        Divider(color: colors.surfaceLight),
        const SizedBox(height: 16),

        // Preset grid label
        Row(children: [
          Text('Стандартные аватарки', style: TextStyle(fontSize: 13, color: colors.textMuted, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_selected >= 0)
            GestureDetector(
              onTap: () {
                widget.onPresetSelected(_selected);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Применить', style: TextStyle(fontSize: 12, color: colors.textOnPrimary, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
        const SizedBox(height: 14),

        // 2-row grid of 10 presets
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            mainAxisExtent: 80,
          ),
          itemCount: _kPresets.length,
          itemBuilder: (_, i) {
            final p = _kPresets[i];
            final isSelected = _selected == i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selected = i);
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: p.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: p.gradientColors.first.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)]
                        : [],
                  ),
                  child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 5),
                Text(p.label,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? colors.primary : colors.textMuted,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
              ]),
            );
          },
        ),
      ]),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _SourceButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// --- Notifications Sheet ---
class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();
  @override State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _workoutReminder = true;
  bool _eveningSync = true;
  bool _mealReminder = false;
  bool _progressWeekly = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return _SheetWrapper(
      title: l10n.notificationsLabel,
      child: Column(children: [
        _NotifToggle(label: 'Напоминание о тренировке', subtitle: 'За 30 минут до начала', value: _workoutReminder, onChanged: (v) => setState(() => _workoutReminder = v)),
        Divider(color: colors.surfaceLight),
        _NotifToggle(label: 'Вечерняя синхронизация', subtitle: 'Каждый вечер в 22:00', value: _eveningSync, onChanged: (v) => setState(() => _eveningSync = v)),
        Divider(color: colors.surfaceLight),
        _NotifToggle(label: 'Напоминание о питании', subtitle: 'Три раза в день', value: _mealReminder, onChanged: (v) => setState(() => _mealReminder = v)),
        Divider(color: colors.surfaceLight),
        _NotifToggle(label: 'Еженедельный отчет', subtitle: 'По воскресеньям', value: _progressWeekly, onChanged: (v) => setState(() => _progressWeekly = v)),
        const SizedBox(height: 24),
        _SaveButton(onTap: () { Navigator.of(context).pop(); _showSuccess(context, 'Настройки сохранены'); }),
      ]),
    );
  }
}

// --- Security Sheet ---
class _SecuritySheet extends StatefulWidget {
  const _SecuritySheet();
  @override State<_SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends State<_SecuritySheet> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureOld = true, _obscureNew = true;

  @override
  void dispose() { _oldPassCtrl.dispose(); _newPassCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return _SheetWrapper(
      title: context.l10n.securityLabel,
      child: Form(
        key: _formKey,
        child: Column(children: [
          _SheetField(controller: _oldPassCtrl, label: 'Текущий пароль', icon: Icons.lock_outline_rounded, obscure: _obscureOld,
            suffix: IconButton(icon: Icon(_obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: colors.textMuted, size: 18), onPressed: () => setState(() => _obscureOld = !_obscureOld)),
            validator: (v) => v!.isEmpty ? 'Введите текущий пароль' : null),
          const SizedBox(height: 14),
          _SheetField(controller: _newPassCtrl, label: 'Новый пароль', icon: Icons.lock_rounded, obscure: _obscureNew,
            suffix: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: colors.textMuted, size: 18), onPressed: () => setState(() => _obscureNew = !_obscureNew)),
            validator: (v) { if (v!.isEmpty) return 'Введите новый пароль'; if (v.length < 6) return 'Минимум 6 символов'; return null; }),
          const SizedBox(height: 24),
          _SaveButton(label: 'Сменить пароль', onTap: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop();
              _showSuccess(context, 'Пароль изменен');
            }
          }),
        ]),
      ),
    );
  }
}

// --- Reusable Sheet Widgets ---
class _SheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetWrapper({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.surfaceLight, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.titleL),
          const SizedBox(height: 24),
          child,
        ]),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  const _SheetField({required this.controller, required this.label, required this.icon, this.obscure = false, this.keyboardType, this.validator, this.suffix});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelL),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(color: colors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: colors.surfaceLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.error)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.error, width: 2)),
          errorStyle: TextStyle(color: colors.error, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? label;
  const _SaveButton({required this.onTap, this.label});
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label ?? l10n.save, style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _NumSlider extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int decimals;
  final ValueChanged<double> onChanged;
  const _NumSlider({required this.label, required this.value, required this.min, required this.max, required this.unit, this.decimals = 1, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: AppTextStyles.labelL),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(decimals == 0 ? '${value.round()} $unit' : '${value.toStringAsFixed(decimals)} $unit',
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: colors.primary,
          inactiveTrackColor: colors.surfaceLight,
          thumbColor: colors.primary,
          overlayColor: colors.primary.withValues(alpha: 0.2),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          trackHeight: 5,
        ),
        child: Slider(
          value: value.clamp(min, max),
          min: min, max: max,
          divisions: ((max - min) * (decimals == 0 ? 1 : 2)).round(),
          onChanged: onChanged,
        ),
      ),
    ]);
  }
}

class _NotifToggle extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifToggle({required this.label, required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 15, color: colors.textPrimary, fontWeight: FontWeight.w500)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textMuted)),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: colors.primary),
      ]),
    );
  }
}

void _showSuccess(BuildContext context, String msg) {
  final colors = AppTheme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
    backgroundColor: colors.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 2),
  ));
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w800, color: colors.textPrimary), textAlign: TextAlign.center, maxLines: 1),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted)),
      ]),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, required this.color, this.onTap});
}

class _AiProgressDialog extends StatelessWidget {
  const _AiProgressDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = AppTheme.of(context);
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.generatingPlan,
            style: TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'DeepSeek пересчитывает программу\nс учётом новых параметров',
            style: TextStyle(fontSize: 13, color: colors.textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
