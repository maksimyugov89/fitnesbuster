import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

/// Provides a persistent AES-256 key (stored in Keychain/EncryptedSharedPreferences
/// via `flutter_secure_storage`) used to encrypt every Hive box at rest.
class HiveEncryption {
  HiveEncryption._();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';

  static HiveAesCipher? _cipher;

  static HiveAesCipher get cipher {
    final c = _cipher;
    if (c == null) {
      throw StateError(
        'HiveEncryption.init() must be called before accessing cipher',
      );
    }
    return c;
  }

  static Future<void> init() async {
    try {
      final encoded = await _storage.read(key: _keyName);
      if (encoded == null) {
        await _generateAndStoreKey();
      } else {
        try {
          final key = base64Url.decode(encoded);
          _cipher = HiveAesCipher(key);
        } catch (e) {
          // Corrupted key — regenerate
          appLogger.w(
            '[HiveEncryption] Stored key corrupted, regenerating',
            error: e,
          );
          await _generateAndStoreKey();
        }
      }
    } catch (e) {
      // FlutterSecureStorage itself failed (e.g. Android Keystore corruption
      // after app reinstallation with a different signing key). Fall back to
      // an in-memory-only key so the app can at least start.
      appLogger.w(
        '[HiveEncryption] Secure storage unavailable, using memory key',
        error: e,
      );
      _cipher = HiveAesCipher(Hive.generateSecureKey());
    }
  }

  static Future<void> _generateAndStoreKey() async {
    final key = Hive.generateSecureKey();
    try {
      await _storage.write(key: _keyName, value: base64UrlEncode(key));
    } catch (e) {
      appLogger.w(
        '[HiveEncryption] Could not persist key to secure storage',
        error: e,
      );
    }
    _cipher = HiveAesCipher(key);
  }

  /// Deletes the stored encryption key and generates a fresh one.
  /// Call this when the Hive box can't be decrypted (e.g. after app
  /// reinstallation with a different signing key).
  static Future<void> reset() async {
    _cipher = null;
    try {
      await _storage.delete(key: _keyName);
    } catch (_) {}
    await init();
  }
}
