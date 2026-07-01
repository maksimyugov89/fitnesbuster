class DailyTime {
  final int hour;
  final int minute;

  const DailyTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23, 'hour must be 0-23'),
      assert(minute >= 0 && minute <= 59, 'minute must be 0-59');
}
