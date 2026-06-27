import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitnesbuster/core/cache/hive_cache.dart';
import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/data/models/exercise_db_model.dart';
import 'package:fitnesbuster/core/localization/language_service.dart';
import 'package:fitnesbuster/core/theme/theme_service.dart';
import 'package:fitnesbuster/core/services/share_intent_service.dart';
import 'package:fitnesbuster/firebase_options.dart';

typedef ProgressCallback = void Function(String stage);

class AppInitException implements Exception {
  final String stage;
  final String message;
  AppInitException(this.stage, this.message);

  @override
  String toString() => '[$stage] $message';
}

class AppInitializer {
  AppInitializer();

  Future<void> initialize({
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call('Firebase');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      throw AppInitException('Firebase', e.toString());
    }

    try {
      onProgress?.call('Storage');
      final appDocDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocDir.path);
      await HiveCache.init();
    } catch (e) {
      throw AppInitException('Storage', e.toString());
    }

    try {
      onProgress?.call('Services');
      await initDependencies();
      AppRouter.init();
    } catch (e) {
      throw AppInitException('Services', e.toString());
    }

    try {
      onProgress?.call('Exercises');
      await ExerciseDatabase.load();
    } catch (e) {
      throw AppInitException('Exercises', e.toString());
    }

    try {
      onProgress?.call('Locale');
      await LanguageService.load();
      await initializeDateFormatting(LanguageService.current.code, null);
      await ThemeService.load();
      ShareIntentService.init();
    } catch (e) {
      throw AppInitException('Locale', e.toString());
    }
  }
}
