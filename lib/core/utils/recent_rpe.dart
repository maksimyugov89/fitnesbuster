import 'package:fitnesbuster/core/di/injection.dart';
import 'package:fitnesbuster/core/utils/date_key.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';

/// Усредняет RPE, которые пользователь проставлял после тренировок за
/// последние [days] дней — best-effort сигнал накопленной усталости
/// (принцип Цацулина: устойчиво высокий RPE → пора снизить нагрузку).
/// Возвращает null, если оценок нет — вызывающая сторона решает, какое
/// нейтральное значение подставить в этом случае.
Future<int?> recentAverageRpe({int days = 7}) async {
  try {
    final settings = sl<ISettingsRepository>();
    final now = DateTime.now();
    final values = <int>[];
    for (int i = 0; i < days; i++) {
      final rpe = await settings.getWorkoutRpe(
        dateKey(now.subtract(Duration(days: i))),
      );
      if (rpe != null) values.add(rpe);
    }
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).round();
  } catch (_) {
    return null;
  }
}

/// Сегодняшний уровень мышечной боли (DOMS, 0-3), если пользователь ответил
/// на ежедневный чек-ин — в отличие от RPE, DOMS не усредняется: это
/// физиологический эффект прошлой нагрузки, ощутимый именно сегодня.
Future<int?> todayDomsLevel() async {
  try {
    return await sl<ISettingsRepository>().getDomsLevel(
      dateKey(DateTime.now()),
    );
  } catch (_) {
    return null;
  }
}
