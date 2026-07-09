import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Handles content shared into the app from other Android apps via
/// ACTION_SEND intents. Works in tandem with MainActivity.kt.
class ShareIntentService {
  static const _channel = MethodChannel('com.fitnesbuster.app/share');

  static final ValueNotifier<String?> pendingShare = ValueNotifier(null);

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          pendingShare.value = text;
        }
      }
    });
  }

  /// Call once on app start / screen focus to pick up any text that was shared
  /// before the Flutter engine was fully ready (cold-start share).
  static Future<void> checkInitialShare() async {
    try {
      final text = await _channel.invokeMethod<String>('getSharedText');
      if (text != null && text.isNotEmpty) {
        pendingShare.value = text;
      }
    } catch (_) {
      // Native side not available (iOS / web / older Android) — ignore
    }
  }

  /// Consume and clear the pending shared text.
  static String? consume() {
    final value = pendingShare.value;
    pendingShare.value = null;
    return value;
  }
}
