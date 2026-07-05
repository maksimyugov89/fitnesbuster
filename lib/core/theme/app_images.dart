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

  // ─── Nav / feature icons ────────────────────────────────────────
  static const String home = 'assets/icons/home_rounded.png';
  static const String workoutsTab = 'assets/icons/fitness_center_rounded.png';
  static const String nutritionTab = 'assets/icons/restaurant_rounded.png';
  static const String progressTab = 'assets/icons/show_chart_rounded.png';
  static const String profileTab = 'assets/icons/person_rounded.png';

  // ─── Health metrics ─────────────────────────────────────────────
  static const String heartRate = 'assets/icons/favorite_rounded.png';
  static const String hrv = 'assets/icons/monitor_heart_outlined.png';
  static const String sleep = 'assets/icons/bedtime_rounded.png';
  static const String steps = 'assets/icons/directions_walk_rounded.png';
  static const String water = 'assets/icons/water_drop_rounded.png';
  static const String respiratoryRate = 'assets/icons/air_rounded.png';
  static const String route = 'assets/icons/map_rounded.png';
  static const String trend = 'assets/icons/trending_up_rounded.png';

  // ─── Feature sections ───────────────────────────────────────────
  static const String achievements = 'assets/icons/emoji_events_rounded.png';
  static const String aiAssistant = 'assets/icons/psychology_rounded.png';
  static const String shoppingList = 'assets/icons/shopping_basket_rounded.png';
  static const String bodyMeasurements = 'assets/icons/straighten_rounded.png';
  static const String barcodeScanner =
      'assets/icons/qr_code_scanner_rounded.png';
  static const String foodScale = 'assets/icons/scale_rounded.png';
  static const String healthIntegration = 'assets/icons/Health_Integration.png';
  static const String activityFeed = 'assets/icons/Activity_Feed.png';
  static const String friends = 'assets/icons/Friends.png';
  static const String challenges = 'assets/icons/Challenges.png';

  // ─── Profile menu ───────────────────────────────────────────────
  static const String personalData = 'assets/icons/person_outline_rounded.png';
  static const String goal = 'assets/icons/flag_outlined.png';
  static const String location = 'assets/icons/location_on_outlined.png';
  static const String language = 'assets/icons/language_rounded.png';
  static const String appTheme = 'assets/icons/palette_outlined.png';
  static const String security = 'assets/icons/security_rounded.png';
  static const String help = 'assets/icons/help_outline_rounded.png';
  static const String terms = 'assets/icons/article_outlined.png';
  static const String about = 'assets/icons/info_outline_rounded.png';
}

/// Helper widget to display app icons with consistent sizing.
///
/// These are silver/chrome illustrated assets shared across every theme.
/// Each source icon has a companion `<name>_glow.png` — a precomputed mask
/// built from a padded canvas (see scratchpad glow-extraction scripts):
/// a tight highlight/sparkle layer clipped to the icon's own silhouette, plus
/// a soft outer halo blurred from that silhouette into the surrounding
/// padding. When [glowColor] is set, that mask is drawn oversized (by
/// [glowOverscan]) and tinted via [BlendMode.srcIn], centered on top of the
/// untouched base icon. [OverflowBox] + `Stack(clipBehavior: Clip.none)` let
/// the halo visually spill past the icon's own bounding box (e.g. past a
/// tightly-fit colored frame) instead of being clamped back down to it.
class AppIcon extends StatelessWidget {
  final String asset;
  final double size;
  final BoxFit fit;
  final Color? glowColor;

  /// How much larger than [size] the glow layer renders, matching the
  /// padding ratio baked into the `_glow.png` masks (see PAD_RATIO in the
  /// generation script). Must stay in sync with that script to keep the
  /// halo's silhouette aligned with the base icon.
  static const double glowOverscan = 1.30;

  const AppIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.fit = BoxFit.contain,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = Image.asset(asset, width: size, height: size, fit: fit);
    final glow = glowColor;
    if (glow == null) return base;
    final glowAsset = asset.replaceFirst(RegExp(r'\.png$'), '_glow.png');
    final glowSize = size * glowOverscan;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          base,
          OverflowBox(
            maxWidth: glowSize,
            maxHeight: glowSize,
            child: Image.asset(
              glowAsset,
              width: glowSize,
              height: glowSize,
              fit: fit,
              color: glow,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
