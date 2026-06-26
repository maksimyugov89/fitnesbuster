import 'package:flutter/material.dart';

/// Central registry for all app image assets.
/// Paths are relative to pubspec.yaml asset declarations.
class AppImages {
  // ─── Icons ──────────────────────────────────────────────────────
  static const String iconDefault = 'assets/icons/icon.png';
  static const String bluetoothDevices = 'assets/icons/Bluetooth_Devices.png';
  static const String calorieCounter = 'assets/icons/Calorie_Counter.png';
  static const String cameraAndAvatar = 'assets/icons/Camera_&_Avatar.png';
  static const String exercises = 'assets/icons/Exercises.png';
  static const String notifications = 'assets/icons/Notifications.png';
  static const String nutrition = 'assets/icons/Nutrition.png';
  static const String progressAnalytics = 'assets/icons/Progress_Analytics.png';
  static const String running = 'assets/icons/Running.png';
  static const String strengthTraining = 'assets/icons/Strength_Training.png';
  static const String supplements = 'assets/icons/Supplements.png';
  static const String weightTracker = 'assets/icons/Weight_Tracker.png';
  static const String workoutTimer = 'assets/icons/Workout_Timer.png';
}

/// Helper widget to display app icons with consistent sizing.
class AppIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;
  final BoxFit fit;

  const AppIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return color != null
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
            child: Image.asset(asset, width: size, height: size, fit: fit),
          )
        : Image.asset(asset, width: size, height: size, fit: fit);
  }
}
