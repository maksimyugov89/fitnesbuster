/// AI service configuration.
/// Keys are injected at build time via --dart-define:
///   flutter run --dart-define=DEEPSEEK_API_KEY=sk-xxx
///   flutter build apk --dart-define=DEEPSEEK_API_KEY=sk-xxx
class AiConfig {
  final String apiKey;
  final String model;
  final String baseUrl;

  static final AiConfig _instance = AiConfig._internal();
  factory AiConfig() => _instance;

  AiConfig._internal()
      : apiKey = '',
        model = const String.fromEnvironment(
          'DEEPSEEK_MODEL',
          defaultValue: 'deepseek-chat',
        ),
        baseUrl = const String.fromEnvironment(
          'DEEPSEEK_BASE_URL',
          defaultValue: 'https://api.deepseek.com',
        );

  /// For use in tests only — creates a config with an explicit key.
  AiConfig.forTesting({
    required this.apiKey,
    this.model = 'deepseek-chat',
    this.baseUrl = 'https://api.deepseek.com',
  });

  bool get isConfigured => apiKey.isNotEmpty;
}
