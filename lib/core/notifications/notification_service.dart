import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _workoutChannelId = 'fitnesbuster_workout';
  static const _workoutChannelName = 'Тренировки';
  static const _workoutChannelDesc = 'Напоминания о тренировках';

  static const _waterChannelId = 'fitnesbuster_water';
  static const _waterChannelName = 'Вода';
  static const _waterChannelDesc = 'Напоминания выпить воду';

  static const _workoutReminderId = 1000;
  static const _waterReminderBaseId = 2000;
  static const _waterReminderHours = [9, 11, 13, 15, 17, 19];

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
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _workoutChannelId, _workoutChannelName,
      description: _workoutChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _waterChannelId, _waterChannelName,
      description: _waterChannelDesc,
      importance: Importance.defaultImportance,
      playSound: false,
    ));
  }

  // ── Workout reminder ─────────────────────────────────────────────────────────

  Future<void> scheduleWorkoutReminder({
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0),
  }) async {
    await _plugin.cancel(id: _workoutReminderId);
    await _plugin.zonedSchedule(
      id: _workoutReminderId,
      title: '💪 Время тренироваться!',
      body: 'Не пропусти тренировку сегодня — ты уже близко к цели.',
      scheduledDate: _nextInstanceOf(time.hour, time.minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _workoutChannelId, _workoutChannelName,
          channelDescription: _workoutChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelWorkoutReminder() async {
    await _plugin.cancel(id: _workoutReminderId);
  }

  // ── Water reminders ──────────────────────────────────────────────────────────

  Future<void> scheduleWaterReminders() async {
    await cancelWaterReminders();
    for (int i = 0; i < _waterReminderHours.length; i++) {
      await _plugin.zonedSchedule(
        id: _waterReminderBaseId + i + 1,
        title: '💧 Выпей воды!',
        body: _waterMessages[i % _waterMessages.length],
        scheduledDate: _nextInstanceOf(_waterReminderHours[i], 0),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _waterChannelId, _waterChannelName,
            channelDescription: _waterChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static const _waterMessages = [
    'Стакан воды сейчас — и тело скажет спасибо 🌊',
    'Пора пить воду! Держи уровень гидратации в норме.',
    'Не забывай про воду — она нужна для восстановления мышц.',
    'Выпей стакан воды прямо сейчас ☀️',
    'Гидратация = энергия. Выпей воды!',
    'Завершай день правильно — ещё один стакан воды 🌙',
  ];

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < _waterReminderHours.length; i++) {
      await _plugin.cancel(id: _waterReminderBaseId + i + 1);
    }
  }

  // ── Instant notification ─────────────────────────────────────────────────────

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
      time: TimeOfDay(
        hour: reminderMinutes ~/ 60,
        minute: reminderMinutes % 60,
      ),
    );
  }

  Future<void> cancel(int id) async => _plugin.cancel(id: id);
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
