import 'package:fitnesbuster/domain/entities/test_week_progress.dart';

abstract interface class ITestWeekProgressRepository {
  Future<TestWeekProgress?> load(String userId);
  Future<void> save(String userId, TestWeekProgress progress);

  /// Clears the device cache after plan acceptance. The server copy is kept
  /// as the user's completed cross-device assessment archive.
  Future<void> clear(String userId);
}
