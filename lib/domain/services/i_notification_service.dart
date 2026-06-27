import 'package:flutter/material.dart';

abstract interface class INotificationService {
  Future<void> initialize();
  Future<void> scheduleWorkoutReminder({TimeOfDay time = const TimeOfDay(hour: 8, minute: 0)});
  Future<void> cancelWorkoutReminder();
  Future<void> scheduleWaterReminders();
  Future<void> cancelWaterReminders();
  Future<void> showInstant({int id = 9999, required String title, required String body, bool isWater = false});
  Future<void> scheduleSmartWorkoutReminder();
  Future<void> cancel(int id);
  Future<void> cancelAll();
}
