/// All supported health & fitness apps that can sync via Health Connect.
/// The app uses Health Connect (Android) as the central aggregation layer,
/// so any app that writes to Health Connect is supported automatically.
enum HealthProvider {
  garminConnect('Garmin Connect', 'garmin', '🏋️'),
  fitbit('Fitbit', 'fitbit', '💙'),
  samsungHealth('Samsung Health', 'samsung', '⌚'),
  appleHealth('Apple Health', 'apple', '🍎'),
  huaweiHealth('Huawei Health', 'huawei', '📱'),
  zeppLife('Zepp Life', 'zepp', '🔵'),
  miFitness('Mi Fitness', 'xiaomi', '⚪'),
  polarFlow('Polar Flow', 'polar', '🔴'),
  suunto('Suunto', 'suunto', '⏱️'),
  coros('Coros', 'coros', '🟢'),
  whoop('Whoop', 'whoop', '🟡'),
  oura('Oura', 'oura', '💍'),
  withings('Withings Health Mate', 'withings', '⚖️'),
  googleFit('Google Fit / Health Connect', 'google', '🔄'),
  healthConnect('Health Connect (Android)', 'hc', '📊');

  final String displayName;
  final String id;
  final String emoji;
  bool get isAvailable => true; // All providers are available via Health Connect

  const HealthProvider(this.displayName, this.id, this.emoji);

  /// Providers that natively write to Health Connect on Android.
  static List<HealthProvider> get androidHealthConnect => [
    samsungHealth, googleFit, healthConnect,
  ];

  /// Providers that require a bridge app (like Health Sync).
  static List<HealthProvider> get requiresBridge => [
    garminConnect, fitbit, huaweiHealth, polarFlow,
    suunto, coros, whoop, oura, withings,
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
