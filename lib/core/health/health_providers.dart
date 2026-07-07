import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

/// All supported health & fitness apps that can sync via Health Connect.
/// The app uses Health Connect (Android) as the central aggregation layer,
/// so any app that writes to Health Connect is supported automatically.
enum HealthProvider {
  garminConnect(
    'Garmin Connect',
    'garmin',
    iconAsset: AppImages.workoutsTab,
  ),
  fitbit('Fitbit', 'fitbit', dotColor: Color(0xFF00B0B9)),
  samsungHealth(
    'Samsung Health',
    'samsung',
    iconAsset: AppImages.ringDevice,
  ),
  appleHealth('Apple Health', 'apple', iconAsset: AppImages.hrv),
  huaweiHealth('Huawei Health', 'huawei', iconAsset: AppImages.phone),
  zeppLife('Zepp Life', 'zepp', dotColor: Color(0xFF2196F3)),
  miFitness('Mi Fitness', 'xiaomi', dotColor: Color(0xFFE0E0E0)),
  polarFlow('Polar Flow', 'polar', dotColor: Color(0xFFE53935)),
  suunto('Suunto', 'suunto', iconAsset: AppImages.workoutTimer),
  coros('Coros', 'coros', dotColor: Color(0xFF43A047)),
  whoop('Whoop', 'whoop', dotColor: Color(0xFFFDD835)),
  oura('Oura', 'oura', iconAsset: AppImages.ringDevice),
  withings('Withings Health Mate', 'withings', iconAsset: AppImages.foodScale),
  googleFit('Google Fit / Health Connect', 'google', iconAsset: AppImages.sync),
  healthConnect(
    'Health Connect (Android)',
    'hc',
    iconAsset: AppImages.progressTab,
  );

  final String displayName;
  final String id;
  final String? iconAsset;
  final Color? dotColor;
  bool get isAvailable =>
      true; // All providers are available via Health Connect

  const HealthProvider(this.displayName, this.id, {this.iconAsset, this.dotColor});

  /// Providers that natively write to Health Connect on Android.
  static List<HealthProvider> get androidHealthConnect => [
    samsungHealth,
    googleFit,
    healthConnect,
  ];

  /// Providers that require a bridge app (like Health Sync).
  static List<HealthProvider> get requiresBridge => [
    garminConnect,
    fitbit,
    huaweiHealth,
    polarFlow,
    suunto,
    coros,
    whoop,
    oura,
    withings,
  ];
}

/// Connection status for each health provider.
class ProviderConnection {
  final HealthProvider provider;
  final bool isConnected;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  const ProviderConnection({
    required this.provider,
    this.isConnected = false,
    this.lastSyncAt,
    this.errorMessage,
  });
}
