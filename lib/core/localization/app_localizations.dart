import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/language_service.dart';
import 'package:fitnesbuster/core/localization/translations/all_translations.dart';

// ─── Extension shortcut ───────────────────────────────────────────────────────

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// ─── Main class ───────────────────────────────────────────────────────────────

class AppLocalizations {
  final String _locale;
  const AppLocalizations._(this._locale);

  static AppLocalizations of(BuildContext context) {
    try {
      final result = Localizations.of<AppLocalizations>(context, AppLocalizations);
      if (result != null) return result;
    } catch (_) {}
    return AppLocalizations._(LanguageService.current.code);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Supported locale list for MaterialApp.supportedLocales
  static const supportedLocales = [
    Locale('ru'), Locale('en'), Locale('es'), Locale('de'), Locale('fr'),
    Locale('it'), Locale('pt'), Locale('tr'), Locale('ar'), Locale('zh'),
    Locale('ja'), Locale('ko'), Locale('hi'), Locale('uk'), Locale('be'),
  ];

  /// Context-free translation lookup for use in BLoC, services, and non-widget code.
  /// Falls back to English if key is missing in current language.
  static String tl(String key) =>
      allTranslations[LanguageService.current.code]?[key] ??
      allTranslations['en']?[key] ??
      key;

  static String tlp(String key, Map<String, String> params) {
    var s = tl(key);
    for (final e in params.entries) { s = s.replaceAll('{${e.key}}', e.value); }
    return s;
  }

  String _t(String key) =>
      allTranslations[_locale]?[key] ??
      allTranslations['en']?[key] ??
      key;

  String _tp(String key, Map<String, String> p) {
    var s = _t(key);
    for (final e in p.entries) { s = s.replaceAll('{${e.key}}', e.value); }
    return s;
  }

  // ── Common ────────────────────────────────────────────────────────────────
  String get save            => _t('save');
  String get cancel          => _t('cancel');
  String get close           => _t('close');
  String get back            => _t('back');
  String get done            => _t('done');
  String get continueLabel   => _t('continueLabel');
  String get skip            => _t('skip');
  String get retry           => _t('retry');
  String get loading         => _t('loading');
  String get error           => _t('error');
  String get noData          => _t('noData');
  String get yes             => _t('yes');
  String get no              => _t('no');
  String get confirm         => _t('confirm');
  String get delete          => _t('delete');
  String get edit            => _t('edit');
  String get add             => _t('add');
  String get search          => _t('search');
  String get send            => _t('send');
  String get ok              => _t('ok');
  String get select          => _t('select');
  String get all             => _t('all');
  String get openArrow       => _t('openArrow');

  // ── Weekdays short ────────────────────────────────────────────────────────
  String get monShort => _t('monShort');
  String get tueShort => _t('tueShort');
  String get wedShort => _t('wedShort');
  String get thuShort => _t('thuShort');
  String get friShort => _t('friShort');
  String get satShort => _t('satShort');
  String get sunShort => _t('sunShort');

  // ── Weekdays full ─────────────────────────────────────────────────────────
  String get monday    => _t('monday');
  String get tuesday   => _t('tuesday');
  String get wednesday => _t('wednesday');
  String get thursday  => _t('thursday');
  String get friday    => _t('friday');
  String get saturday  => _t('saturday');
  String get sunday    => _t('sunday');

  String get today     => _t('today');
  String get yesterday => _t('yesterday');
  String get tomorrow  => _t('tomorrow');

  // ── Navigation tabs ───────────────────────────────────────────────────────
  String get navHome      => _t('navHome');
  String get navWorkout   => _t('navWorkout');
  String get navNutrition => _t('navNutrition');
  String get navProgress  => _t('navProgress');
  String get navProfile   => _t('navProfile');

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get emailLabel           => _t('emailLabel');
  String get passwordLabel        => _t('passwordLabel');
  String get confirmPasswordLabel => _t('confirmPasswordLabel');
  String get nameLabel            => _t('nameLabel');
  String get loginTitle           => _t('loginTitle');
  String get loginSubtitle        => _t('loginSubtitle');
  String get registerTitle        => _t('registerTitle');
  String get registerSubtitle     => _t('registerSubtitle');
  String get emailHint            => _t('emailHint');
  String get passwordHint         => _t('passwordHint');
  String get forgotPassword       => _t('forgotPassword');
  String get orContinueWith       => _t('orContinueWith');
  String get signInWithGoogle     => _t('signInWithGoogle');
  String get alreadyHaveAccount   => _t('alreadyHaveAccount');
  String get dontHaveAccount      => _t('dontHaveAccount');
  String get loginButton          => _t('loginButton');
  String get registerButton       => _t('registerButton');

  // ── Onboarding ────────────────────────────────────────────────────────────
  String get onbGoalTitle      => _t('onbGoalTitle');
  String get onbGoalSubtitle   => _t('onbGoalSubtitle');
  String get goalLoseWeight    => _t('goalLoseWeight');
  String get goalGainMuscle    => _t('goalGainMuscle');
  String get goalBodyComp      => _t('goalBodyComp');
  String get goalEndurance     => _t('goalEndurance');
  String get goalMaintain      => _t('goalMaintain');
  String get onbGenderTitle    => _t('onbGenderTitle');
  String get genderMale        => _t('genderMale');
  String get genderFemale      => _t('genderFemale');
  String get onbAgeTitle       => _t('onbAgeTitle');
  String get onbAgeHint        => _t('onbAgeHint');
  String get onbWeightTitle    => _t('onbWeightTitle');
  String get onbWeightHint     => _t('onbWeightHint');
  String get onbHeightTitle    => _t('onbHeightTitle');
  String get onbHeightHint     => _t('onbHeightHint');
  String get onbActivityTitle  => _t('onbActivityTitle');
  String get activitySedentary => _t('activitySedentary');
  String get activityLight     => _t('activityLight');
  String get activityModerate  => _t('activityModerate');
  String get activityActive    => _t('activityActive');
  String get activityVeryActive=> _t('activityVeryActive');
  String get generatingPlan    => _t('generatingPlan');
  String get planReady         => _t('planReady');

  // ── Dashboard ─────────────────────────────────────────────────────────────
  String get greetingMorning   => _t('greetingMorning');
  String get greetingAfternoon => _t('greetingAfternoon');
  String get greetingEvening   => _t('greetingEvening');
  String get dailyGoals        => _t('dailyGoals');
  String get taskWorkout       => _t('taskWorkout');
  String get taskWater         => _t('taskWater');
  String get taskMeals         => _t('taskMeals');
  String get recoveryTitle     => _t('recoveryTitle');
  String get recoveryLow       => _t('recoveryLow');
  String get recoveryMed       => _t('recoveryMed');
  String get recoveryHigh      => _t('recoveryHigh');
  String get heartRateLabel    => _t('heartRateLabel');
  String get stepsLabel        => _t('stepsLabel');
  String get activeCalLabel    => _t('activeCalLabel');
  String get sleepLabel        => _t('sleepLabel');
  String get aiPlanSection     => _t('aiPlanSection');
  String get openPlanBtn       => _t('openPlanBtn');
  String get startTodayBtn     => _t('startTodayBtn');
  String get xpLabel           => _t('xpLabel');
  String get levelLabel        => _t('levelLabel');
  String get socialSection     => _t('socialSection');
  String get askAiLabel        => _t('askAiLabel');
  String get askAiSubtitle     => _t('askAiSubtitle');
  String get workoutCalBurned  => _t('workoutCalBurned');

  // ── Workout ───────────────────────────────────────────────────────────────
  String get workoutPlanTitle  => _t('workoutPlanTitle');
  String get myPlanLabel       => _t('myPlanLabel');
  String get exerciseBaseLabel => _t('exerciseBaseLabel');
  String get aiCorrLabel       => _t('aiCorrLabel');
  String get restDayLabel      => _t('restDayLabel');
  String get setsLabel         => _t('setsLabel');
  String get repsLabel         => _t('repsLabel');
  String get weightLabel       => _t('weightLabel');
  String get restLabel         => _t('restLabel');
  String get durationLabel     => _t('durationLabel');
  String get cardioLabel       => _t('cardioLabel');
  String get rpeLabel          => _t('rpeLabel');
  String get startWorkoutBtn   => _t('startWorkoutBtn');
  String get finishWorkoutBtn  => _t('finishWorkoutBtn');
  String get skipRestBtn       => _t('skipRestBtn');
  String get workoutDoneTitle  => _t('workoutDoneTitle');
  String get correctPlanBtn    => _t('correctPlanBtn');
  String get coachTipLabel     => _t('coachTipLabel');
  String get warmupLabel       => _t('warmupLabel');
  String get cooldownLabel     => _t('cooldownLabel');
  String get workoutCalTitle   => _t('workoutCalTitle');
  String get workoutLogTitle   => _t('workoutLogTitle');
  String get exercisesLabel    => _t('exercisesLabel');
  String get setsCompletedLabel=> _t('setsCompletedLabel');
  String get readyLabel        => _t('readyLabel');
  String get restSeconds       => _t('restSeconds');
  String get skipRestLabel     => _t('skipRestLabel');
  String get restTitle         => _t('restTitle');
  String get prevLabel         => _t('prevLabel');
  String get nextLabel         => _t('nextLabel');
  String get exitWorkoutTitle  => _t('exitWorkoutTitle');
  String get exitWorkoutMsg    => _t('exitWorkoutMsg');
  String get keepGoingBtn      => _t('keepGoingBtn');
  String get exitBtn           => _t('exitBtn');
  String get phasesLabel       => _t('phasesLabel');
  String get approaches        => _t('approaches');
  String get repetitions       => _t('repetitions');
  String get importWorkoutTitle=> _t('importWorkoutTitle');
  String get correctionTitle   => _t('correctionTitle');
  String get writePref         => _t('writePref');
  String get fromInternet      => _t('fromInternet');
  String get pasteClipboard    => _t('pasteClipboard');
  String get fromFile          => _t('fromFile');
  String get scanQr            => _t('scanQr');
  String get shareFromApp      => _t('shareFromApp');
  String get applyChangesBtn   => _t('applyChangesBtn');
  String get changesTitle      => _t('changesTitle');
  String get aiLogicTitle      => _t('aiLogicTitle');
  String get updatedPlanTitle  => _t('updatedPlanTitle');
  String get noActivePlan      => _t('noActivePlan');

  // ── Exercise Browser ─────────────────────────────────────────────────────
  String get exercisesTitle   => _t('exercisesTitle');
  String get searchExHint     => _t('searchExHint');
  String get filterMuscle     => _t('filterMuscle');
  String get filterEquipment  => _t('filterEquipment');
  String get muscleChest      => _t('muscleChest');
  String get muscleBack       => _t('muscleBack');
  String get muscleShoulders  => _t('muscleShoulders');
  String get muscleArms       => _t('muscleArms');
  String get muscleLegs       => _t('muscleLegs');
  String get muscleAbs        => _t('muscleAbs');
  String get muscleGlutes     => _t('muscleGlutes');
  String get muscleCalves     => _t('muscleCalves');
  String get equipBarbell     => _t('equipBarbell');
  String get equipDumbbell    => _t('equipDumbbell');
  String get equipMachine     => _t('equipMachine');
  String get equipBodyweight  => _t('equipBodyweight');
  String get equipCable       => _t('equipCable');
  String get equipKettlebell  => _t('equipKettlebell');
  String get videoDemo        => _t('videoDemo');
  String get aiTipsLabel      => _t('aiTipsLabel');
  String get muscleActivation => _t('muscleActivation');

  // ── Nutrition ────────────────────────────────────────────────────────────
  String get nutritionTitle    => _t('nutritionTitle');
  String get mealPlanLabel     => _t('mealPlanLabel');
  String get foodDiaryLabel    => _t('foodDiaryLabel');
  String get shoppingListLabel => _t('shoppingListLabel');
  String get breakfast         => _t('breakfast');
  String get lunch             => _t('lunch');
  String get dinner            => _t('dinner');
  String get snack             => _t('snack');
  String get supper            => _t('supper');
  String get caloriesLabel     => _t('caloriesLabel');
  String get proteinLabel      => _t('proteinLabel');
  String get carbsLabel        => _t('carbsLabel');
  String get fatLabel          => _t('fatLabel');
  String get fiberLabel        => _t('fiberLabel');
  String get waterLabel        => _t('waterLabel');
  String get addWaterBtn       => _t('addWaterBtn');
  String get waterTargetLabel  => _t('waterTargetLabel');
  String get dailyTargetLabel  => _t('dailyTargetLabel');
  String get eatenLabel        => _t('eatenLabel');
  String get remainingLabel    => _t('remainingLabel');
  String get burnedLabel       => _t('burnedLabel');
  String get addFoodBtn        => _t('addFoodBtn');
  String get scanBarcodeBtn    => _t('scanBarcodeBtn');
  String get supplementsLabel  => _t('supplementsLabel');
  String get timingLabel       => _t('timingLabel');
  String get mealsLabel        => _t('mealsLabel');

  // ── Progress ─────────────────────────────────────────────────────────────
  String get progressTitle       => _t('progressTitle');
  String get measurementsLabel   => _t('measurementsLabel');
  String get photosLabel         => _t('photosLabel');
  String get recordsLabel        => _t('recordsLabel');
  String get bodyWeightLabel     => _t('bodyWeightLabel');
  String get bodyFatLabel        => _t('bodyFatLabel');
  String get waistLabel          => _t('waistLabel');
  String get hipsLabel           => _t('hipsLabel');
  String get chestMeasureLabel   => _t('chestMeasureLabel');
  String get armsLabel           => _t('armsLabel');
  String get thighsLabel         => _t('thighsLabel');
  String get weeklyDebriefTitle  => _t('weeklyDebriefTitle');
  String get aiAnalysisTitle     => _t('aiAnalysisTitle');
  String get prTitle             => _t('prTitle');
  String get newRecordLabel      => _t('newRecordLabel');
  String get weekLabel           => _t('weekLabel');
  String get monthLabel          => _t('monthLabel');
  String get threeMonthsLabel    => _t('threeMonthsLabel');
  String get addMeasurementBtn   => _t('addMeasurementBtn');
  String get beforeAfterLabel    => _t('beforeAfterLabel');

  // ── Profile ───────────────────────────────────────────────────────────────
  String get profileTitle         => _t('profileTitle');
  String get settingsLabel        => _t('settingsLabel');
  String get editProfileLabel     => _t('editProfileLabel');
  String get personalInfoLabel    => _t('personalInfoLabel');
  String get ageLabel             => _t('ageLabel');
  String get fitnessGoalLabel     => _t('fitnessGoalLabel');
  String get activityLevelLabel   => _t('activityLevelLabel');
  String get languageLabel        => _t('languageLabel');
  String get themeLabel           => _t('themeLabel');
  String get notificationsLabel   => _t('notificationsLabel');
  String get healthConnectLabel   => _t('healthConnectLabel');
  String get syncNowBtn           => _t('syncNowBtn');
  String get lastSyncLabel        => _t('lastSyncLabel');
  String get achievementsTitle    => _t('achievementsTitle');
  String get unlockedLabel        => _t('unlockedLabel');
  String get lockedLabel          => _t('lockedLabel');
  String get logoutBtn            => _t('logoutBtn');
  String get deleteAccountBtn     => _t('deleteAccountBtn');
  String get deleteAccountConfirm => _t('deleteAccountConfirm');
  String get versionLabel         => _t('versionLabel');
  String get yourDataLabel        => _t('yourDataLabel');
  String get appearanceLabel      => _t('appearanceLabel');
  String get selectLanguageTitle    => _t('selectLanguageTitle');
  String get selectLanguageSubtitle => _t('selectLanguageSubtitle');
  String languageChanged(String name) => _tp('languageChanged', {'name': name});
  String get selectThemeTitle       => _t('selectThemeTitle');
  String get themeNeon            => _t('themeNeon');
  String get themeOcean           => _t('themeOcean');
  String get themeSunset          => _t('themeSunset');
  String get themeForest          => _t('themeForest');
  String get themePurple          => _t('themePurple');
  String get themeCyber           => _t('themeCyber');

  // ── AI Chat ───────────────────────────────────────────────────────────────
  String get aiChatTitle    => _t('aiChatTitle');
  String get askTrainerHint => _t('askTrainerHint');
  String get thinkingLabel  => _t('thinkingLabel');
  String get aiChatSubtitle => _t('aiChatSubtitle');
  String get clearChatBtn   => _t('clearChatBtn');

  // ── Social ────────────────────────────────────────────────────────────────
  String get feedTitle           => _t('feedTitle');
  String get friendsTitle        => _t('friendsTitle');
  String get challengesTitle     => _t('challengesTitle');
  String get leaderboardLabel    => _t('leaderboardLabel');
  String get addFriendBtn        => _t('addFriendBtn');
  String get acceptBtn           => _t('acceptBtn');
  String get declineBtn          => _t('declineBtn');
  String get createChallengeBtn  => _t('createChallengeBtn');
  String get joinChallengeBtn    => _t('joinChallengeBtn');
  String get friendRequestsLabel => _t('friendRequestsLabel');
  String get myFriendsLabel      => _t('myFriendsLabel');
  String get searchFriendsHint   => _t('searchFriendsHint');
  String get myChallengesLabel   => _t('myChallengesLabel');
  String get publicChallengesLabel => _t('publicChallengesLabel');

  // ── Test Week ────────────────────────────────────────────────────────────
  String get testWeekTitle     => _t('testWeekTitle');
  String get testWeekSubtitle  => _t('testWeekSubtitle');
  String get startTestBtn      => _t('startTestBtn');
  String get testCompleteTitle => _t('testCompleteTitle');

  // ── Gamification ─────────────────────────────────────────────────────────
  String get xpEarnedLabel    => _t('xpEarnedLabel');
  String get nextLevelLabel   => _t('nextLevelLabel');
  String get achievementUnlocked => _t('achievementUnlocked');

  // ── Errors & states ───────────────────────────────────────────────────────
  String get networkError    => _t('networkError');
  String get saveError       => _t('saveError');
  String get loadError       => _t('loadError');
  String get planNotFound    => _t('planNotFound');
  String get noWorkoutToday  => _t('noWorkoutToday');
  String get noMealPlanError => _t('noMealPlanError');
  String get authRequired    => _t('authRequired');

  // ── Workout execution ─────────────────────────────────────────────────────────
  String get secondsToStart  => _t('secondsToStart');
  String get getReadyAlert   => _t('getReadyAlert');
  String get kgUnit          => _t('kgUnit');
  String get repsShort       => _t('repsShort');
  String get finishNow       => _t('finishNow');
  String get secondsRest     => _t('secondsRest');
  String get getReadyNextSet => _t('getReadyNextSet');
  String get updatingChallenges => _t('updatingChallenges');
  String get challengeCompleted => _t('challengeCompleted');

  // ── Workout plan ──────────────────────────────────────────────────────────────
  String get weekTab             => _t('weekTab');
  String get fullPlanTab         => _t('fullPlanTab');
  String get workoutsTitle       => _t('workoutsTitle');
  String get aiPlanSubtitle      => _t('aiPlanSubtitle');
  String get calendarBtn         => _t('calendarBtn');
  String get baseShort           => _t('baseShort');
  String get aiCorrShort         => _t('aiCorrShort');
  String get startBtn            => _t('startBtn');
  String get weeklyRecsTitle     => _t('weeklyRecsTitle');
  String get nextWeekTitle       => _t('nextWeekTitle');
  String get loginRequired       => _t('loginRequired');
  String get planNotGeneratedMsg => _t('planNotGeneratedMsg');
  String get planDamagedMsg      => _t('planDamagedMsg');
  String get planLoadFailMsg     => _t('planLoadFailMsg');
  String get restDayTitle        => _t('restDayTitle');
  String get restDayNote         => _t('restDayNote');
  String get workoutDoneStatus   => _t('workoutDoneStatus');
  String get workoutDoneSubtitleNext => _t('workoutDoneSubtitleNext');
  String get warmupTitle         => _t('warmupTitle');
  String get cooldownTitle       => _t('cooldownTitle');
  String get musclesWorkoutTitle => _t('musclesWorkoutTitle');
  String get view3D              => _t('view3D');
  String get exerciseDefault     => _t('exerciseDefault');

  // ── Progress ──────────────────────────────────────────────────────────────────
  String get photoFront      => _t('photoFront');
  String get photoSide       => _t('photoSide');
  String get photoBack       => _t('photoBack');
  String get photoFrontInstr => _t('photoFrontInstr');
  String get photoSideInstr  => _t('photoSideInstr');
  String get photoBackInstr  => _t('photoBackInstr');
  String get photoTips       => _t('photoTips');
  String get selectPhotoBtn  => _t('selectPhotoBtn');
  String get takeCameraBtn   => _t('takeCameraBtn');
  String get chooseGalleryBtn => _t('chooseGalleryBtn');
  String get todayShort      => _t('todayShort');
  String get currentWeightTitle => _t('currentWeightTitle');
  String get cmUnit          => _t('cmUnit');
  String get kcalShort       => _t('kcalShort');
  String get yearLabel       => _t('yearLabel');
  String get weightChartTitle => _t('weightChartTitle');
  String get noWeightData    => _t('noWeightData');
  String get bodyMeasTitle   => _t('bodyMeasTitle');
  String get photoProgressTitle2 => _t('photoProgressTitle2');
  String get anglesLabel     => _t('anglesLabel');
  String get photoNote       => _t('photoNote');
  String get tapHint         => _t('tapHint');
  String get aiProgressTitle => _t('aiProgressTitle');
  String get updateBtn       => _t('updateBtn');
  String get analyzeBtn      => _t('analyzeBtn');
  String get fillProfileForAi => _t('fillProfileForAi');
  String get weightBodyTab   => _t('weightBodyTab');
  String get workoutsStatTab => _t('workoutsStatTab');
  String get healthTabLabel  => _t('healthTabLabel');
  String get noBreakStreak   => _t('noBreakStreak');
  String get periodTodayLabel => _t('periodTodayLabel');
  String get periodWeekLabel  => _t('periodWeekLabel');
  String get periodMonthLabel => _t('periodMonthLabel');
  String get periodYearLabel  => _t('periodYearLabel');
  String get janShort => _t('janShort'); String get febShort => _t('febShort');
  String get marShort => _t('marShort'); String get aprShort => _t('aprShort');
  String get mayShort => _t('mayShort'); String get junShort => _t('junShort');
  String get julShort => _t('julShort'); String get augShort => _t('augShort');
  String get sepShort => _t('sepShort'); String get octShort => _t('octShort');
  String get novShort => _t('novShort'); String get decShort => _t('decShort');
  String get recoveryAiRest    => _t('recoveryAiRest');
  String get recoveryAiReduce  => _t('recoveryAiReduce');
  String get recoveryLowMsg2   => _t('recoveryLowMsg');
  String get recoveryHRVLowMsg2 => _t('recoveryHRVLowMsg');

  // ── Dashboard ──────────────────────────────────────────────────────────────────
  String get dashboardDefaultName  => _t('dashboardDefaultName');
  String get dashboardBpm          => _t('dashboardBpm');
  String get dashboardNormal       => _t('dashboardNormal');
  String get dashboardTapToEnter   => _t('dashboardTapToEnter');
  String get dashboardKg           => _t('dashboardKg');
  String get dashboardUpdated      => _t('dashboardUpdated');
  String get dashboardNoData       => _t('dashboardNoData');
  String get dashboardStreak       => _t('dashboardStreak');
  String get dashboardDays         => _t('dashboardDays');
  String get dashboardKeepGoing    => _t('dashboardKeepGoing');
  String get dashboardStartProgram => _t('dashboardStartProgram');
  String get dashboardIndividualLabel  => _t('dashboardIndividualLabel');
  String get dashboardYourSchedule => _t('dashboardYourSchedule');
  String get dashboardNoRush       => _t('dashboardNoRush');
  String get dashboardTarget       => _t('dashboardTarget');
  String get dashboardMetabolismPlusActivity => _t('dashboardMetabolismPlusActivity');
  String get dashboardDeficit      => _t('dashboardDeficit');
  String get dashboardSurplus      => _t('dashboardSurplus');

  // ── Onboarding ────────────────────────────────────────────────────────────────
  String get step1About       => _t('step1About');
  String get step2Params      => _t('step2Params');
  String get step3Activity    => _t('step3Activity');
  String get step4Restrictions => _t('step4Restrictions');
  String get step5Location    => _t('step5Location');
  String get nameFieldLabel   => _t('nameFieldLabel');
  String get nameHint         => _t('nameHint');
  String get bmiTitle         => _t('bmiTitle');
  String get bmiUnderweight   => _t('bmiUnderweight');
  String get bmiNormal        => _t('bmiNormal');
  String get bmiOverweight    => _t('bmiOverweight');
  String get bmiObese         => _t('bmiObese');
  String get locationHint     => _t('locationHint');
  String get detectAutoBtn    => _t('detectAutoBtn');
  String get enterManuallyLabel => _t('enterManuallyLabel');
  String get locationNote     => _t('locationNote');
  String get locationSkipNote => _t('locationSkipNote');
  String get restrictionsNote1 => _t('restrictionsNote1');
  String get restrictionsNote2 => _t('restrictionsNote2');
  String get restrictionsNote3 => _t('restrictionsNote3');
  String get detectingLabel   => _t('detectingLabel');
  String get geoDisabledMsg   => _t('geoDisabledMsg');
  String get geoPermissionDeniedMsg => _t('geoPermissionDeniedMsg');
  String get geoCityNotFoundMsg => _t('geoCityNotFoundMsg');
  String get geoErrorMsg      => _t('geoErrorMsg');
  String get generatingAnalyzing  => _t('generatingAnalyzing');
  String get generatingWorkout    => _t('generatingWorkout');
  String get generatingMeal       => _t('generatingMeal');
  String get generatingFinalizing => _t('generatingFinalizing');
  String get aiPlanCreating   => _t('aiPlanCreating');
  String get about30sec       => _t('about30sec');
  String get funFact1 => _t('funFact1'); String get funFact2 => _t('funFact2');
  String get funFact3 => _t('funFact3'); String get funFact4 => _t('funFact4');
  String get funFact5 => _t('funFact5'); String get funFact6 => _t('funFact6');
  String get startProgramBtn  => _t('startProgramBtn');
  String get dietNutsAllergy  => _t('dietNutsAllergy');
  String get dietLactose      => _t('dietLactose');
  String get dietGlutenFree   => _t('dietGlutenFree');
  String get dietVegetarian   => _t('dietVegetarian');
  String get dietNoRedMeat    => _t('dietNoRedMeat');
  String get dietDiabetic     => _t('dietDiabetic');
  String get dietLowSalt      => _t('dietLowSalt');
  String get dietVegan        => _t('dietVegan');
  String get dietKeto         => _t('dietKeto');

  // ── Shopping list ─────────────────────────────────────────────────────────────
  String get catProteins      => _t('catProteins');
  String get catDairy         => _t('catDairy');
  String get catGrains        => _t('catGrains');
  String get catVegetables    => _t('catVegetables');
  String get catFruits        => _t('catFruits');
  String get catFatsNuts      => _t('catFatsNuts');
  String get catOther         => _t('catOther');
  String get shoppingListTitle => _t('shoppingListTitle');

  // ── Profile screen ────────────────────────────────────────────────────────────
  String get activeProgramLabel    => _t('activeProgramLabel');
  String get fillProfileProgress   => _t('fillProfileProgress');
  String get bodyParamsLabel       => _t('bodyParamsLabel');
  String get otherSectionLabel     => _t('otherSectionLabel');
  String get securityLabel         => _t('securityLabel');
  String get helpSupportLabel      => _t('helpSupportLabel');
  String get licensesLabel         => _t('licensesLabel');
  String get aboutAppLabel         => _t('aboutAppLabel');
  String get workoutLocationLabel  => _t('workoutLocationLabel');
  String get earnBadgesHint        => _t('earnBadgesHint');
  String get allBadgesBtn          => _t('allBadgesBtn');
  String get workoutSettingsTitle  => _t('workoutSettingsTitle');
  String get workoutSettingsSubtitle => _t('workoutSettingsSubtitle');
  String get locationSectionLabel  => _t('locationSectionLabel');
  String get gymLocation           => _t('gymLocation');
  String get gymLocationSub        => _t('gymLocationSub');
  String get stadiumLocation       => _t('stadiumLocation');
  String get stadiumLocationSub    => _t('stadiumLocationSub');
  String get homeLocation          => _t('homeLocation');
  String get homeLocationSub       => _t('homeLocationSub');
  String get runningExercisesLabel => _t('runningExercisesLabel');
  String get withRunningLabel      => _t('withRunningLabel');
  String get withoutRunningLabel   => _t('withoutRunningLabel');
  String get noChangesLabel        => _t('noChangesLabel');
  String get goalWeightLoss        => _t('goalWeightLoss');
  String get goalMuscleMass        => _t('goalMuscleMass');
  String get goalMaintainWeight    => _t('goalMaintainWeight');
  String get goalBeachSeason       => _t('goalBeachSeason');
  String get goalSportsRecords     => _t('goalSportsRecords');
  String get yearsUnit             => _t('yearsUnit');
  String get bodyParamsSheetTitle  => _t('bodyParamsSheetTitle');
  String get fitnessGoalSheetTitle => _t('fitnessGoalSheetTitle');
  String get activeProgram12week   => _t('activeProgram12week');

  // ── Workout log ───────────────────────────────────────────────────────────────
  String get workoutDoneStatus3   => _t('workoutDoneStatus3');
  String get workoutNotDoneStatus => _t('workoutNotDoneStatus');
  String get rateWorkoutTitle     => _t('rateWorkoutTitle');
  String get expandAll            => _t('expandAll');
  String get collapseAll          => _t('collapseAll');
  String get detailLogNote        => _t('detailLogNote');
  String get last7DaysTitle       => _t('last7DaysTitle');
  String get setHeader            => _t('setHeader');
  String get repsHeader           => _t('repsHeader');
  String get weightKgHeader       => _t('weightKgHeader');
  String get greatJobMsg          => _t('greatJobMsg');
  String get noWorryMsg           => _t('noWorryMsg');

  // ── Nutrition screen ─────────────────────────────────────────────────────────
  String get todayTabLabel        => _t('todayTabLabel');
  String get weeklyTabLabel       => _t('weeklyTabLabel');
  String get addFoodTabLabel      => _t('addFoodTabLabel');
  String get mealCompleted        => _t('mealCompleted');
  String get mealCancelCompleted  => _t('mealCancelCompleted');
  String get nutritionTipsLabel   => _t('nutritionTipsLabel');
  String get supplementsSportLabel => _t('supplementsSportLabel');
  String get noPlanError          => _t('noPlanError');
  String get noWeeklyPlanError    => _t('noWeeklyPlanError');
  String get weeklyMealPlanTitle  => _t('weeklyMealPlanTitle');
  String get mlUnit               => _t('mlUnit');
  String get gUnit                => _t('gUnit');
  String get proteinShort         => _t('proteinShort');
  String get carbsShort           => _t('carbsShort');
  String get fatShort             => _t('fatShort');
  String get fiberShort           => _t('fiberShort');
  String get addFoodManualTitle   => _t('addFoodManualTitle');
  String get foodNameHint         => _t('foodNameHint');
  String get gramsHint            => _t('gramsHint');
  String get caloriesHint         => _t('caloriesHint');
  String get mealTypeLabel        => _t('mealTypeLabel');
  String get replaceIngredientsLabel => _t('replaceIngredientsLabel');
  String get extraFoodLabel       => _t('extraFoodLabel');

  String mealsEatenCount(int done, int total) =>
      _tp('mealsEatenCount', {'done': done.toString(), 'total': total.toString()});
  String dailyRationSubtitle(int cal) =>
      _tp('dailyRationSubtitle', {'cal': cal.toString()});
  String mealExceeded(int cal) =>
      _tp('mealExceeded', {'cal': cal.toString()});
  String mealEaten(int cal) =>
      _tp('mealEaten', {'cal': cal.toString()});
  String waterDrunkOf(String drunk, String total) =>
      _tp('waterDrunkOf', {'drunk': drunk, 'total': total});
  String waterRemaining(int ml) =>
      _tp('waterRemaining', {'ml': ml.toString()});
  String weeklyCalPerDay(int cal) =>
      _tp('weeklyCalPerDay', {'cal': cal.toString()});

  // ── Progress health tab ────────────────────────────────────────────────────
  String get syncTodayBtn        => _t('syncTodayBtn');
  String get weeklyDebriefSubtitle => _t('weeklyDebriefSubtitle');
  String get avgHeartRateLabel   => _t('avgHeartRateLabel');
  String get restingHrLabel      => _t('restingHrLabel');
  String get hrvLabel            => _t('hrvLabel');
  String get respiratoryRateLabel => _t('respiratoryRateLabel');
  String get stepsTodayLabel     => _t('stepsTodayLabel');
  String get sleepLabel2         => _t('sleepLabel2');
  String get waterHealthLabel    => _t('waterHealthLabel');
  String get bpmUnit             => _t('bpmUnit');
  String get msUnit              => _t('msUnit');
  String get bpmRespUnit         => _t('bpmRespUnit');
  String get stepsUnit           => _t('stepsUnit');
  String get hoursNightUnit      => _t('hoursNightUnit');
  String get mlHealthUnit        => _t('mlHealthUnit');
  String get normalBadge         => _t('normalBadge');
  String get aiAdviceLabel       => _t('aiAdviceLabel');
  String get thisWeekLabel       => _t('thisWeekLabel');

  String daysCompletedOf(int done, int total) =>
      _tp('daysCompletedOf', {'done': done.toString(), 'total': total.toString()});

  // ── Workout session ─────────────────────────────────────────────────────
  String get loadingWorkout     => _t('loadingWorkout');
  String get forward            => _t('forward');
  String get rest               => _t('rest');
  String get tip                => _t('tip');
  String get endWorkoutTitle    => _t('endWorkoutTitle');
  String get endWorkoutBody     => _t('endWorkoutBody');
  String get exitLabel         => _t('exit');

  // ── Workout calendar ─────────────────────────────────────────────────────
  String get reset              => _t('reset');
  String get moved              => _t('moved');
  String get workoutSchedule    => _t('workoutSchedule');
  String get noWorkoutPlan      => _t('noWorkoutPlan');
  String get generatePlanHint   => _t('generatePlanHint');
  String get nearestWorkouts    => _t('nearestWorkouts');

  // ── Exercise detail ──────────────────────────────────────────────────────
  String get characteristics    => _t('characteristics');
  String get technique          => _t('technique');
  String get howToPerform       => _t('howToPerform');
  String get analyzingTechnique => _t('analyzingTechnique');
  String get noConnection       => _t('noConnection');
  String get exerciseNotFound   => _t('exerciseNotFound');

  // ── Import / correction ──────────────────────────────────────────────────
  String get correctPlan        => _t('correctPlan');
  String get pasteFromClipboard => _t('pasteFromClipboard');
  String get clipboardEmpty     => _t('clipboardEmpty');
  String get openingFilePicker  => _t('openingFilePicker');
  String get selectFileAgain    => _t('selectFileAgain');

  // ── Test week ────────────────────────────────────────────────────────────
  String get testWeek           => _t('testWeek');
  String get analyzingPerf      => _t('analyzingPerformance');
  String get preparingTestWeek  => _t('preparingTestWeek');
  String get exercisesInstr     => _t('exercisesInstruction');
  String get recordMetric       => _t('recordMetric');
  String get startProgram       => _t('startProgram');
  String get programStarted     => _t('programStarted');
  String get toHome             => _t('toHome');

  // ── Parameterized ─────────────────────────────────────────────────────────
  String setsOf(String done, String total) =>
      _tp('setsOf', {'done': done, 'total': total});

  String exercisesCount(int n) =>
      _tp('exercisesCount', {'n': n.toString()});

  String levelN(int n) =>
      _tp('levelN', {'n': n.toString()});

  String xpPoints(int n) =>
      _tp('xpPoints', {'n': n.toString()});

  String cardioMinutes(int n) =>
      _tp('cardioMinutes', {'n': n.toString()});

  String greetUser(String name) =>
      _tp('greetUser', {'name': name});

  String exerciseXofY(String x, String y) =>
      _tp('exerciseXofY', {'x': x, 'y': y});

  String setsTimesReps(String sets, String reps) =>
      _tp('setsTimesReps', {'sets': sets, 'reps': reps});

  String restBetweenSets(String sec) =>
      _tp('restBetweenSets', {'sec': sec});

  String estimatedTimeSec(String sec) =>
      _tp('estimatedTimeSec', {'sec': sec});

  String exercisesAndSets(String n, String sets) =>
      _tp('exercisesAndSets', {'n': n, 'sets': sets});

  String completedSetsOf(String done, String total) =>
      _tp('completedSetsOf', {'done': done, 'total': total});

  String dayLabel(int n) =>
      _tp('dayLabel', {'n': n.toString()});

  String startWorkoutDetails(int n, int sets) =>
      _tp('startWorkoutDetails', {'n': n.toString(), 'sets': sets.toString()});

  String startWorkoutWithCardio(int n, int sets, int c) =>
      _tp('startWorkoutWithCardio', {'n': n.toString(), 'sets': sets.toString(), 'c': c.toString()});

  String minSuffix(int n) =>
      _tp('minSuffix', {'n': n.toString()});

  String kcalSuffix(int n) =>
      _tp('kcalSuffix', {'n': n.toString()});

  String weekNumShort(int n) =>
      _tp('weekNumShort', {'n': n.toString()});

  String stepsInfo(int n) =>
      _tp('stepsInfo', {'n': n.toString()});

  String prevMeasLabel(String date) =>
      _tp('prevMeasLabel', {'date': date});

  String aiAnalysisHintText(int n, String photos) =>
      _tp('aiAnalysisHintText', {'n': n.toString(), 'photos': photos});

  String workoutsChartTitle(String period) =>
      _tp('workoutsChartTitle', {'period': period});

  String workoutsDoneCountLabel(int n) =>
      _tp('workoutsDoneCountLabel', {'n': n.toString()});

  String photoPickTitle(String angle) =>
      _tp('photoPickTitle', {'angle': angle});

  String dashboardWeightUpdated(String weight, String target) =>
      _tp('dashboardWeightUpdated', {'weight': weight, 'target': target});

  String dashboardBmr(String bmr) =>
      _tp('dashboardBmr', {'bmr': bmr});

  String dashboardActivityPlus(String activity) =>
      _tp('dashboardActivityPlus', {'activity': activity});

  String dashboardCalExceeded(String extra) =>
      _tp('dashboardCalExceeded', {'extra': extra});

  String dashboardCalDeficit(String deficit) =>
      _tp('dashboardCalDeficit', {'deficit': deficit});

  String workoutsWeekCount(int done) =>
      _tp('workoutsWeekCount', {'done': done.toString()});

  String costEstimateLabel(int min, int max) =>
      _tp('costEstimateLabel', {'min': min.toString(), 'max': max.toString()});

  String maxWeightLabel(String n) =>
      _tp('maxWeightLabel', {'n': n});

  String enterValueManualHint(String unit) =>
      _tp('enterValueManualHint', {'unit': unit});
  // ── Profile screen strings ──
  String get profileUpdated          => _t('profileUpdated');
  String get enterNameValidation     => _t('enterNameValidation');
  String get changeAvatar            => _t('changeAvatar');
  String get programAndMealsUpdated  => _t('programAndMealsUpdated');
  String get workoutProgramUpdated   => _t('workoutProgramUpdated');
  String get planUpdateFailed        => _t('planUpdateFailed');
  String get photoPickError          => _t('photoPickError');
  // ── Import workout sheet ──
  String get correctionRetryMsg      => _t('correctionRetryMsg');
  String get pageLoadError           => _t('pageLoadError');
  String get fileReadError           => _t('fileReadError');
  String get fileOpenError           => _t('fileOpenError');
  String get notAuthorized           => _t('notAuthorized');
  String get planSaveFailed          => _t('planSaveFailed');
  String get unknownErrorMsg         => _t('unknownErrorMsg');
  String get errorTitle              => _t('errorTitle');
  String get tryAgainBtn             => _t('tryAgainBtn');
  // ── Intensity selection ──
  String get intensityHardcore       => _t('intensityHardcore');
  String get intensityHardcoreDesc   => _t('intensityHardcoreDesc');
  String get intensityIntense        => _t('intensityIntense');
  String get intensityIntenseDesc    => _t('intensityIntenseDesc');
  String get intensityBalanced       => _t('intensityBalanced');
  String get intensityBalancedDesc   => _t('intensityBalancedDesc');
  String get intensityGradual        => _t('intensityGradual');
  String get intensityGradualDesc    => _t('intensityGradualDesc');
  String get intensityLight          => _t('intensityLight');
  String get intensityLightDesc      => _t('intensityLightDesc');
  String get intensityTagHeavy       => _t('intensityTagHeavy');
  String get intensityTagFullbody    => _t('intensityTagFullbody');
  String get intensityTagHIIT        => _t('intensityTagHIIT');
  String get intensityTagFunctional  => _t('intensityTagFunctional');
  String get intensityTagLowImpact   => _t('intensityTagLowImpact');
  // ── Auth form validation ──
  String get enterEmailValidation    => _t('enterEmailValidation');
  String get invalidEmailFormat      => _t('invalidEmailFormat');
  String get enterPasswordValidation => _t('enterPasswordValidation');
  String get passwordMinLength       => _t('passwordMinLength');
  String get passwordNeedLetter      => _t('passwordNeedLetter');
  String get passwordNeedNumber      => _t('passwordNeedNumber');
  String get passwordsDontMatch      => _t('passwordsDontMatch');
  // ── TTS / Voice coaching ──
  String get ttsGetReady             => _t('ttsGetReady');
  String get ttsGo                   => _t('ttsGo');
  String ttsRestNextExercise(String name) => _tp('ttsRestNextExercise', {'name': name});
  String ttsRestNextSet(String n)        => _tp('ttsRestNextSet', {'n': n});
  String get ttsWorkoutDone          => _t('ttsWorkoutDone');
  // ── Workout session ──
  String get noSavedWorkoutPlan      => _t('noSavedWorkoutPlan');
  String get planIsEmpty             => _t('planIsEmpty');
  // ── Social screens ──
  String get challengesAdded         => _t('challengesAdded');
  String genericErrorMsg(String error) => _tp('genericErrorMsg', {'error': error});
  // ── Meal & shopping ──
  String loadErrorMsg(String error)  => _tp('loadErrorMsg', {'error': error});
  String aiErrorMsg(String error)    => _tp('aiErrorMsg', {'error': error});
  // ── Gamification levels (7-9) ──
  String get levelElite              => _t('levelElite');
  String get levelMaster             => _t('levelMaster');
  String get levelTitan              => _t('levelTitan');
}

// ─── Delegate ─────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  static const _supported = {
    'ru', 'en', 'es', 'de', 'fr', 'it', 'pt',
    'tr', 'ar', 'zh', 'ja', 'ko', 'hi', 'uk', 'be',
  };

  @override
  bool isSupported(Locale locale) =>
      _supported.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations._(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
