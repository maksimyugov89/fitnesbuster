import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

enum RecoveryLevel { excellent, good, fair, low }

class RecoveryScore {
  final int score; // 0-100
  final RecoveryLevel level;
  final String label;
  final String advice;
  final bool shouldReduceIntensity;
  final int? sleepMinutes;
  final double? hrv;
  final int? restingHr;

  const RecoveryScore({
    required this.score,
    required this.level,
    required this.label,
    required this.advice,
    required this.shouldReduceIntensity,
    this.sleepMinutes,
    this.hrv,
    this.restingHr,
  });

  Color get color => switch (level) {
    RecoveryLevel.excellent => const Color(0xFF22D3A5),
    RecoveryLevel.good => const Color(0xFFC8FF00),
    RecoveryLevel.fair => const Color(0xFFF5A623),
    RecoveryLevel.low => const Color(0xFFFF4466),
  };

  String get emoji => switch (level) {
    RecoveryLevel.excellent => '💚',
    RecoveryLevel.good => '💛',
    RecoveryLevel.fair => '🟠',
    RecoveryLevel.low => '❤️',
  };
}

class RecoveryScoreService {
  // Sleep component (40%) — based on minutes slept
  static int _sleepScore(int? minutes) {
    if (minutes == null) return 65; // neutral when no data
    if (minutes >= 480) return 100; // ≥ 8h
    if (minutes >= 420) return 80; // ≥ 7h
    if (minutes >= 360) return 55; // ≥ 6h
    if (minutes >= 300) return 30; // ≥ 5h
    return 10;
  }

  // HRV component (35%) — RMSSD in ms, higher = better
  static int _hrvScore(double? hrv) {
    if (hrv == null) return 65;
    if (hrv >= 60) return 100;
    if (hrv >= 40) return 80;
    if (hrv >= 25) return 60;
    if (hrv >= 15) return 40;
    return 20;
  }

  // Resting HR component (25%) — lower = better recovery
  static int _hrScore(int? bpm) {
    if (bpm == null) return 65;
    if (bpm <= 55) return 100;
    if (bpm <= 65) return 80;
    if (bpm <= 75) return 60;
    if (bpm <= 85) return 40;
    return 20;
  }

  static RecoveryScore calculate({
    int? sleepMinutes,
    double? hrv,
    int? restingHr,
  }) {
    final score =
        (_sleepScore(sleepMinutes) * 0.40 +
                _hrvScore(hrv) * 0.35 +
                _hrScore(restingHr) * 0.25)
            .round();

    final level = score >= 80
        ? RecoveryLevel.excellent
        : score >= 65
        ? RecoveryLevel.good
        : score >= 45
        ? RecoveryLevel.fair
        : RecoveryLevel.low;

    final label = switch (level) {
      RecoveryLevel.excellent => AppLocalizations.tl('recoveryExcellent'),
      RecoveryLevel.good => AppLocalizations.tl('recoveryGood'),
      RecoveryLevel.fair => AppLocalizations.tl('recoveryAverage'),
      RecoveryLevel.low => AppLocalizations.tl('recoveryLow2'),
    };

    final advice = switch (level) {
      RecoveryLevel.excellent => AppLocalizations.tl('recoveryReadyMax'),
      RecoveryLevel.good => AppLocalizations.tl('recoveryReadyNormal'),
      RecoveryLevel.fair => AppLocalizations.tl('recoveryReduce'),
      RecoveryLevel.low => AppLocalizations.tl('recoveryRestDay'),
    };

    return RecoveryScore(
      score: score,
      level: level,
      label: label,
      advice: advice,
      shouldReduceIntensity:
          level == RecoveryLevel.fair || level == RecoveryLevel.low,
      sleepMinutes: sleepMinutes,
      hrv: hrv,
      restingHr: restingHr,
    );
  }

  static String formatSleep(int? minutes) {
    if (minutes == null) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0
        ? AppLocalizations.tlp('recoveryTime', {
            'h': h.toString(),
            'm': m.toString(),
          })
        : '$hч';
  }
}
