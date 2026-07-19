import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:fitnesbuster/core/cache/hive_encryption.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

typedef QueueOperation = Future<void> Function(Map<String, dynamic> data);
typedef OfflineQueueStoreFactory =
    Future<OfflineQueueStore> Function(String boxName);
typedef ConnectivityChecker = Future<List<ConnectivityResult>> Function();
typedef ConnectivityChanges = Stream<List<ConnectivityResult>> Function();

abstract interface class OfflineQueueStore {
  bool get isEmpty;
  Iterable<dynamic> get keys;

  String? get(dynamic key);
  Future<int> add(String value);
  Future<void> put(dynamic key, String value);
  Future<void> delete(dynamic key);
}

class HiveOfflineQueueStore implements OfflineQueueStore {
  final Box<String> _box;

  HiveOfflineQueueStore(this._box);

  static Future<OfflineQueueStore> open(String boxName) async {
    late Box<String> box;
    try {
      box = await Hive.openBox<String>(
        boxName,
        encryptionCipher: HiveEncryption.cipher,
      );
    } on HiveError catch (e) {
      appLogger.w(
        'OfflineQueue: encrypted box $boxName is unreadable; resetting it',
        error: e,
      );
      await Hive.deleteBoxFromDisk(boxName);
      box = await Hive.openBox<String>(
        boxName,
        encryptionCipher: HiveEncryption.cipher,
      );
    } on FormatException catch (e) {
      appLogger.w(
        'OfflineQueue: encrypted box $boxName has invalid format; resetting it',
        error: e,
      );
      await Hive.deleteBoxFromDisk(boxName);
      box = await Hive.openBox<String>(
        boxName,
        encryptionCipher: HiveEncryption.cipher,
      );
    }
    return HiveOfflineQueueStore(box);
  }

  @override
  bool get isEmpty => _box.isEmpty;

  @override
  Iterable<dynamic> get keys => _box.keys;

  @override
  String? get(dynamic key) => _box.get(key);

  @override
  Future<int> add(String value) => _box.add(value);

  @override
  Future<void> put(dynamic key, String value) => _box.put(key, value);

  @override
  Future<void> delete(dynamic key) => _box.delete(key);
}

class _QueueEntry {
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int attempts;

  const _QueueEntry({
    required this.type,
    required this.data,
    required this.createdAt,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
  };

  _QueueEntry copyWith({int? attempts}) {
    return _QueueEntry(
      type: type,
      data: data,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  static _QueueEntry fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final rawData = json['data'];
    final rawCreatedAt = json['createdAt'] as String?;
    if (type == null || rawData is! Map || rawCreatedAt == null) {
      throw const FormatException('Invalid offline queue entry');
    }
    final createdAt = DateTime.tryParse(rawCreatedAt);
    if (createdAt == null) {
      throw const FormatException('Invalid offline queue entry timestamp');
    }
    return _QueueEntry(
      type: type,
      data: Map<String, dynamic>.from(rawData),
      createdAt: createdAt,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

class OfflineQueue {
  static const _boxName = 'offline_queue';
  static const _deadLetterBoxName = 'offline_queue_dead_letter';
  OfflineQueueStore? _box;
  OfflineQueueStore? _deadLetterBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final Map<String, QueueOperation> _handlers = {};
  final int _maxAttempts;
  final OfflineQueueStoreFactory _openStore;
  final ConnectivityChecker _checkConnectivity;
  final ConnectivityChanges _connectivityChanges;
  final bool _autoFlushOnEnqueue;
  final _events = StreamController<OfflineQueueEvent>.broadcast();

  OfflineQueue({
    int maxAttempts = 3,
    OfflineQueueStoreFactory? openStore,
    ConnectivityChecker? checkConnectivity,
    ConnectivityChanges? connectivityChanges,
    bool autoFlushOnEnqueue = true,
  }) : _maxAttempts = maxAttempts,
       _openStore = openStore ?? HiveOfflineQueueStore.open,
       _checkConnectivity =
           checkConnectivity ?? (() => Connectivity().checkConnectivity()),
       _connectivityChanges =
           connectivityChanges ?? (() => Connectivity().onConnectivityChanged),
       _autoFlushOnEnqueue = autoFlushOnEnqueue;

  Future<void> init() async {
    _box = await _openStore(_boxName);
    _deadLetterBox = await _openStore(_deadLetterBoxName);
    _connectivitySub = _connectivityChanges().listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        unawaited(flush());
      }
    });
  }

  void registerHandler(String type, QueueOperation handler) {
    _handlers[type] = handler;
  }

  Stream<OfflineQueueEvent> get events => _events.stream;

  bool get hasDeadLetters => !(_deadLetterBox?.isEmpty ?? true);

  Future<void> enqueue(String type, Map<String, dynamic> data) async {
    if (_box == null) return;
    final entry = _QueueEntry(
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    await _box!.add(jsonEncode(entry.toJson()));
    if (_autoFlushOnEnqueue) {
      unawaited(tryFlush());
    }
  }

  Future<void> tryFlush() async {
    final results = await _checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      await flush();
    }
  }

  Future<void> flush() async {
    if (_box == null || _box!.isEmpty) return;
    final keys = _box!.keys.toList();
    for (final key in keys) {
      try {
        final raw = _box!.get(key);
        if (raw == null) continue;
        final entry = _parseEntry(raw);
        if (entry == null) {
          await _box!.delete(key);
          continue;
        }
        final handler = _handlers[entry.type];
        if (handler == null) {
          appLogger.w('OfflineQueue: no handler registered for ${entry.type}');
          continue;
        }
        await handler(entry.data);
        await _box!.delete(key);
      } catch (_) {
        final raw = _box!.get(key);
        final entry = raw == null ? null : _parseEntry(raw);
        if (entry == null) {
          await _box!.delete(key);
          continue;
        }
        final updated = entry.copyWith(attempts: entry.attempts + 1);
        if (updated.attempts >= _maxAttempts) {
          await _deadLetterBox?.add(jsonEncode(updated.toJson()));
          await _box!.delete(key);
          final event = OfflineQueueEvent.deadLetter(
            type: updated.type,
            attempts: updated.attempts,
          );
          appLogger.w(
            'OfflineQueue: moved ${updated.type} to dead-letter after ${updated.attempts} attempts',
          );
          _events.add(event);
          continue;
        }
        await _box!.put(key, jsonEncode(updated.toJson()));
        break;
      }
    }
  }

  bool get isEmpty => _box?.isEmpty ?? true;

  _QueueEntry? _parseEntry(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _QueueEntry.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _events.close();
    _connectivitySub = null;
  }
}

class OfflineQueueEvent {
  final String type;
  final int attempts;
  final bool isDeadLetter;

  const OfflineQueueEvent._({
    required this.type,
    required this.attempts,
    required this.isDeadLetter,
  });

  const OfflineQueueEvent.deadLetter({
    required String type,
    required int attempts,
  }) : this._(type: type, attempts: attempts, isDeadLetter: true);
}
