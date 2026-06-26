/// Returns a SharedPreferences date key in the format "YYYY_M_D" (no zero-padding).
///
/// All screens must use this helper to read/write date-keyed data so the
/// format stays consistent. Example: 2026_6_15
String dateKey(DateTime d) => '${d.year}_${d.month}_${d.day}';

/// Returns today's date key.
String todayKey() => dateKey(DateTime.now());
