import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

typedef QueueOperation = Future<void> Function();

class _QueueEntry {
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const _QueueEntry({
    required this.type,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };
}

class OfflineQueue {
  static const _boxName = 'offline_queue';
  Box<String>? _box;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final List<QueueOperation> _handlers = [];

  OfflineQueue();

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        flush();
      }
    });
  }

  void registerHandler(String type, QueueOperation handler) {
    _handlers.add(handler);
  }

  Future<void> enqueue(String type, Map<String, dynamic> data) async {
    if (_box == null) return;
    final entry = _QueueEntry(
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
    await _box!.add(jsonEncode(entry.toJson()));
    tryFlush();
  }

  void tryFlush() {
    Connectivity().checkConnectivity().then((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        flush();
      }
    });
  }

  Future<void> flush() async {
    if (_box == null || _box!.isEmpty) return;
    final keys = _box!.keys.toList();
    for (final key in keys) {
      try {
        final raw = _box!.get(key);
        if (raw == null) continue;
        for (final handler in _handlers) {
          await handler();
        }
        await _box!.delete(key);
      } catch (_) {
        break;
      }
    }
  }

  bool get isEmpty => _box?.isEmpty ?? true;

  Future<void> dispose() async {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }
}
