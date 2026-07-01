import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

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
    final encoded = await _storage.read(key: _keyName);
    final List<int> key;
    if (encoded == null) {
      key = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64UrlEncode(key));
    } else {
      key = base64Url.decode(encoded);
    }
    _cipher = HiveAesCipher(key);
  }
}
