import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/domain/services/i_notification_service.dart';
import 'package:fitnesbuster/domain/entities/daily_time.dart';

class NotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _workoutChannelId = 'fitnesbuster_workout';
  static final _workoutChannelName = AppLocalizations.tl('notifWorkoutChannel');
  static final _workoutChannelDesc = AppLocalizations.tl('notifWorkoutDesc');

  static const _waterChannelId = 'fitnesbuster_water';
  static final _waterChannelName = AppLocalizations.tl('notifWaterChannel');
  static final _waterChannelDesc = AppLocalizations.tl('notifWaterDesc');

  static const _workoutReminderId = 1000;
  static const _waterReminderBaseId = 2000;
  static const _waterReminderHours = [9, 11, 13, 15, 17, 19];

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(AndroidNotificationChannel(
      _workoutChannelId, _workoutChannelName,
      description: _workoutChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
    await android?.createNotificationChannel(AndroidNotificationChannel(
      _waterChannelId, _waterChannelName,
      description: _waterChannelDesc,
      importance: Importance.defaultImportance,
      playSound: false,
    ));
  }

  // ── Workout reminder ─────────────────────────────────────────────────────────

  @override
  Future<void> scheduleWorkoutReminder({
    DailyTime time = const DailyTime(hour: 8, minute: 0),
  }) async {
    await _plugin.cancel(id: _workoutReminderId);
    await _plugin.zonedSchedule(
      id: _workoutReminderId,
      title: AppLocalizations.tl('notifWorkoutTime'),
      body: AppLocalizations.tl('notifWorkoutBody'),
      scheduledDate: _nextInstanceOf(time.hour, time.minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _workoutChannelId, _workoutChannelName,
          channelDescription: _workoutChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelWorkoutReminder() async {
    await _plugin.cancel(id: _workoutReminderId);
  }

  // ── Water reminders ──────────────────────────────────────────────────────────

  @override
  Future<void> scheduleWaterReminders() async {
    await cancelWaterReminders();
    for (int i = 0; i < _waterReminderHours.length; i++) {
      await _plugin.zonedSchedule(
        id: _waterReminderBaseId + i + 1,
        title: AppLocalizations.tl('notifWaterTitle'),
        body: _waterMessages[i % _waterMessages.length],
        scheduledDate: _nextInstanceOf(_waterReminderHours[i], 0),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _waterChannelId, _waterChannelName,
            channelDescription: _waterChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static final _waterMessages = [
    AppLocalizations.tl('notifWaterBody1'),
    AppLocalizations.tl('notifWaterBody2'),
    AppLocalizations.tl('notifWaterBody3'),
    AppLocalizations.tl('notifWaterBody4'),
    AppLocalizations.tl('notifWaterBody5'),
    AppLocalizations.tl('notifWaterBody6'),
  ];

  @override
  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < _waterReminderHours.length; i++) {
      await _plugin.cancel(id: _waterReminderBaseId + i + 1);
    }
  }

  // ── Instant notification ─────────────────────────────────────────────────────

  @override
  Future<void> showInstant({
    int id = 9999,
    required String title,
    required String body,
    bool isWater = false,
  }) async {
    final channelId = isWater ? _waterChannelId : _workoutChannelId;
    final channelName = isWater ? _waterChannelName : _workoutChannelName;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ── Smart scheduling ─────────────────────────────────────────────────────────

  /// Reads workout completion times from the last 21 days, computes the
  /// average, and schedules the reminder 30 min before that window.
  /// Falls back to 08:00 if fewer than 3 data points exist.
  @override
  Future<void> scheduleSmartWorkoutReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final times = <int>[];

    for (int i = 1; i <= 21; i++) {
      final d = now.subtract(Duration(days: i));
      final k = '${d.year}_${d.month}_${d.day}';
      final t = prefs.getInt('workout_time_$k');
      if (t != null) times.add(t);
    }

    if (times.length < 3) {
      // Not enough history — use default 08:00
      await scheduleWorkoutReminder();
      return;
    }

    final avgMinutes =
        (times.reduce((a, b) => a + b) / times.length).round();
    // 30 minutes before average workout time, clamped to 05:00–22:00
    final reminderMinutes = (avgMinutes - 30).clamp(300, 22 * 60);
    await scheduleWorkoutReminder(
      time: DailyTime(
        hour: reminderMinutes ~/ 60,
        minute: reminderMinutes % 60,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async => _plugin.cancel(id: id);
  @override
  Future<void> cancelAll() async => _plugin.cancelAll();

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
