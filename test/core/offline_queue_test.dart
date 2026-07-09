import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fitnesbuster/core/cache/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOfflineQueueStore implements OfflineQueueStore {
  final Map<dynamic, String> _values = {};
  int _nextKey = 0;

  List<String> get values => _values.values.toList();

  @override
  bool get isEmpty => _values.isEmpty;

  @override
  Iterable<dynamic> get keys => _values.keys.toList();

  @override
  String? get(dynamic key) => _values[key];

  @override
  Future<int> add(String value) async {
    final key = _nextKey++;
    _values[key] = value;
    return key;
  }

  @override
  Future<void> put(dynamic key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _values.remove(key);
  }
}

void main() {
  late FakeOfflineQueueStore queueStore;
  late FakeOfflineQueueStore deadLetterStore;
  late OfflineQueue queue;

  Future<void> initQueue({int maxAttempts = 3}) async {
    queueStore = FakeOfflineQueueStore();
    deadLetterStore = FakeOfflineQueueStore();
    final stores = {
      'offline_queue': queueStore,
      'offline_queue_dead_letter': deadLetterStore,
    };
    queue = OfflineQueue(
      maxAttempts: maxAttempts,
      openStore: (boxName) async => stores[boxName]!,
      checkConnectivity: () async => [ConnectivityResult.wifi],
      connectivityChanges: () => const Stream<List<ConnectivityResult>>.empty(),
      autoFlushOnEnqueue: false,
    );
    await queue.init();
  }

  test('flush dispatches queued data to the handler for its type', () async {
    await initQueue();
    Map<String, dynamic>? handledData;
    queue.registerHandler('profile.update', (data) async {
      handledData = data;
    });

    await queue.enqueue('profile.update', {'displayName': 'Alex'});
    await queue.flush();

    expect(handledData, {'displayName': 'Alex'});
    expect(queueStore.isEmpty, isTrue);
    expect(deadLetterStore.isEmpty, isTrue);
  });

  test('flush deletes malformed queue entries', () async {
    await initQueue();
    await queueStore.add('{not-json');

    await queue.flush();

    expect(queueStore.isEmpty, isTrue);
    expect(deadLetterStore.isEmpty, isTrue);
  });

  test(
    'flush increments attempts and keeps retryable failed entries',
    () async {
      await initQueue(maxAttempts: 3);
      queue.registerHandler('profile.update', (_) async {
        throw StateError('temporary failure');
      });

      await queue.enqueue('profile.update', {'displayName': 'Alex'});
      await queue.flush();

      expect(queueStore.values, hasLength(1));
      final updated =
          jsonDecode(queueStore.values.single) as Map<String, dynamic>;
      expect(updated['attempts'], 1);
      expect(deadLetterStore.isEmpty, isTrue);
    },
  );

  test(
    'flush moves failed entries to dead letter after max attempts',
    () async {
      await initQueue(maxAttempts: 2);
      final events = <OfflineQueueEvent>[];
      final sub = queue.events.listen(events.add);
      queue.registerHandler('profile.update', (_) async {
        throw StateError('permanent failure');
      });

      await queue.enqueue('profile.update', {'displayName': 'Alex'});
      await queue.flush();
      await queue.flush();

      expect(queueStore.isEmpty, isTrue);
      expect(deadLetterStore.values, hasLength(1));
      final deadLetter =
          jsonDecode(deadLetterStore.values.single) as Map<String, dynamic>;
      expect(deadLetter['type'], 'profile.update');
      expect(deadLetter['data'], {'displayName': 'Alex'});
      expect(deadLetter['attempts'], 2);
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.single.isDeadLetter, isTrue);
      expect(events.single.type, 'profile.update');
      await sub.cancel();
    },
  );
}
