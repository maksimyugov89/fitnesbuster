import 'package:fitnesbuster/domain/entities/daily_time.dart';

abstract interface class INotificationService {
  Future<void> initialize();
  Future<void> scheduleWorkoutReminder({
    DailyTime time = const DailyTime(hour: 8, minute: 0),
  });
  Future<void> cancelWorkoutReminder();
  Future<void> scheduleWaterReminders();
  Future<void> cancelWaterReminders();
  Future<void> showInstant({
    int id = 9999,
    required String title,
    required String body,
    bool isWater = false,
  });
  Future<void> scheduleSmartWorkoutReminder();
  Future<void> cancel(int id);
  Future<void> cancelAll();
}
