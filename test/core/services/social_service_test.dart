import 'dart:async';

// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'social_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(),
])
class _FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot(this._id, this._data);
  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;
}

class _FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _FakeQuerySnapshot(this._docs);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
}

void main() {
  test(
    'publishActivity sends validated callable payload when signed in',
    () async {
      final calls = <MapEntry<String, Map<String, dynamic>>>[];
      final service = SocialService(
        firestore: MockFirebaseFirestore(),
        currentUidProvider: () => 'u1',
        callableInvoker: (name, data) async {
          calls.add(MapEntry(name, data));
          return {'eventId': 'e1'};
        },
      );

      await service.publishActivity('workout_done', {'workoutId': 'w1'});

      expect(calls, hasLength(1));
      expect(calls.single.key, 'publishActivity');
      expect(calls.single.value, {
        'type': 'workout_done',
        'data': {'workoutId': 'w1'},
      });
    },
  );

  test('publishActivity is a no-op when signed out', () async {
    var called = false;
    final service = SocialService(
      firestore: MockFirebaseFirestore(),
      currentUidProvider: () => null,
      callableInvoker: (_, _) async {
        called = true;
        return null;
      },
    );

    await service.publishActivity('workout_done', {});

    expect(called, isFalse);
  });

  test('searchUsers maps callable response to UserSearchResult list', () async {
    final service = SocialService(
      firestore: MockFirebaseFirestore(),
      currentUidProvider: () => 'u1',
      callableInvoker: (name, data) async {
        expect(name, 'searchUsers');
        expect(data, {'query': 'al'});
        return [
          {'uid': 'u2', 'name': 'Alex', 'username': 'alex', 'isFriend': true},
        ];
      },
    );

    final results = await service.searchUsers('al');

    expect(results, hasLength(1));
    expect(results.single.uid, 'u2');
    expect(results.single.isFriend, isTrue);
  });

  test(
    'createChallenge sends callable payload and returns challenge id',
    () async {
      final service = SocialService(
        firestore: MockFirebaseFirestore(),
        currentUidProvider: () => 'u1',
        callableInvoker: (name, data) async {
          expect(name, 'createChallenge');
          expect(data, {
            'title': 'Week of strength',
            'description': 'Finish 3 workouts',
            'goalType': 'workout_count',
            'targetValue': 3,
            'durationDays': 7,
            'isPublic': true,
          });
          return {'challengeId': 'challenge-1'};
        },
      );

      final challengeId = await service.createChallenge(
        title: 'Week of strength',
        description: 'Finish 3 workouts',
        goalType: 'workout_count',
        targetValue: 3,
        durationDays: 7,
        isPublic: true,
      );

      expect(challengeId, 'challenge-1');
    },
  );

  test('recordWorkout returns completed challenge names', () async {
    final service = SocialService(
      firestore: MockFirebaseFirestore(),
      currentUidProvider: () => 'u1',
      callableInvoker: (name, data) async {
        expect(name, 'recordWorkout');
        expect(data['caloriesBurned'], 250);
        return {
          'completed': ['First steps'],
        };
      },
    );

    final completed = await service.recordWorkout(
      durationMinutes: 45,
      caloriesBurned: 250,
      cardioMinutes: 10,
      streak: 3,
    );

    expect(completed, ['First steps']);
  });

  // ── Stream tests ──────────────────────────────────────────────────────────

  group('friendsStream', () {
    test('returns empty stream when uid is null', () {
      final service = SocialService(
        firestore: MockFirebaseFirestore(),
        currentUidProvider: () => null,
      );
      expect(service.friendsStream(), emitsDone);
    });

    test('maps Firestore snapshot to FriendUser list', () async {
      final query = MockCollectionReference();
      final db = MockFirebaseFirestore();
      final addedAt = DateTime(2025, 7, 1);

      when(db.collection('friends/u1/list')).thenReturn(query);
      when(query.orderBy('addedAt', descending: true)).thenReturn(query);
      when(query.snapshots()).thenAnswer((_) {
        final snap = _FakeQuerySnapshot([
          _FakeQueryDocumentSnapshot('u2', {
            'name': 'Alice',
            'addedAt': Timestamp.fromDate(addedAt),
          }),
          _FakeQueryDocumentSnapshot('u3', {
            'name': 'Bob',
            'addedAt': Timestamp.fromDate(addedAt),
          }),
        ]);
        return Stream.value(snap);
      });

      final service = SocialService(
        firestore: db,
        currentUidProvider: () => 'u1',
      );

      await expectLater(
        service.friendsStream(),
        emits(
          predicate<List<FriendUser>>((list) {
            if (list.length != 2) return false;
            return list[0].uid == 'u2' &&
                list[0].name == 'Alice' &&
                list[1].uid == 'u3' &&
                list[1].name == 'Bob';
          }),
        ),
      );
    });
  });

  group('incomingRequestsStream', () {
    test('returns empty stream when uid is null', () {
      final service = SocialService(
        firestore: MockFirebaseFirestore(),
        currentUidProvider: () => null,
      );
      expect(service.incomingRequestsStream(), emitsDone);
    });

    test('maps Firestore snapshot to FriendRequest list', () async {
      final query = MockCollectionReference();
      final db = MockFirebaseFirestore();
      final createdAt = DateTime(2025, 7, 1);

      when(db.collection('friend_requests')).thenReturn(query);
      when(query.where('toUid', isEqualTo: 'u1')).thenReturn(query);
      when(query.where('status', isEqualTo: 'pending')).thenReturn(query);
      when(query.orderBy('createdAt', descending: true)).thenReturn(query);
      when(query.snapshots()).thenAnswer((_) {
        final snap = _FakeQuerySnapshot([
          _FakeQueryDocumentSnapshot('req1', {
            'fromUid': 'u2',
            'fromName': 'Alice',
            'toUid': 'u1',
            'status': 'pending',
            'createdAt': Timestamp.fromDate(createdAt),
          }),
        ]);
        return Stream.value(snap);
      });

      final service = SocialService(
        firestore: db,
        currentUidProvider: () => 'u1',
      );

      await expectLater(
        service.incomingRequestsStream(),
        emits(
          predicate<List<FriendRequest>>((list) {
            return list.length == 1 &&
                list[0].id == 'req1' &&
                list[0].fromUid == 'u2' &&
                list[0].fromName == 'Alice';
          }),
        ),
      );
    });
  });

  group('feedStream', () {
    test('returns empty stream when uid is null', () {
      final service = SocialService(
        firestore: MockFirebaseFirestore(),
        currentUidProvider: () => null,
      );
      expect(service.feedStream(), emitsDone);
    });

    test('maps Firestore snapshot to FeedEvent list', () async {
      final query = MockCollectionReference();
      final db = MockFirebaseFirestore();
      final ts = DateTime(2025, 7, 1);

      when(db.collection('feed/u1/events')).thenReturn(query);
      when(query.orderBy('timestamp', descending: true)).thenReturn(query);
      when(query.limit(40)).thenReturn(query);
      when(query.snapshots()).thenAnswer((_) {
        final snap = _FakeQuerySnapshot([
          _FakeQueryDocumentSnapshot('ev1', {
            'type': 'workout_done',
            'fromUid': 'u1',
            'fromName': 'Self',
            'data': {'durationMinutes': 45},
            'timestamp': Timestamp.fromDate(ts),
          }),
        ]);
        return Stream.value(snap);
      });

      final service = SocialService(
        firestore: db,
        currentUidProvider: () => 'u1',
      );

      await expectLater(
        service.feedStream(),
        emits(
          predicate<List<FeedEvent>>((list) {
            return list.length == 1 &&
                list[0].type == 'workout_done' &&
                list[0].fromUid == 'u1';
          }),
        ),
      );
    });
  });

  group('publicChallengesStream', () {
    test('maps Firestore snapshot to Challenge list', () async {
      final query = MockCollectionReference();
      final db = MockFirebaseFirestore();
      final startDate = DateTime(2025, 7, 1);

      when(db.collection('challenges')).thenReturn(query);
      when(query.where('isPublic', isEqualTo: true)).thenReturn(query);
      when(query.orderBy('endDate', descending: true)).thenReturn(query);
      when(query.limit(30)).thenReturn(query);
      when(query.snapshots()).thenAnswer((_) {
        final snap = _FakeQuerySnapshot([
          _FakeQueryDocumentSnapshot('ch1', {
            'title': 'Public Run',
            'description': 'Run 10km',
            'goalType': 'workout_count',
            'targetValue': 3,
            'durationDays': 7,
            'isPublic': true,
            'isPredefined': false,
            'createdBy': 'u2',
            'creatorName': 'Alice',
            'participants': ['u2'],
            'startDate': Timestamp.fromDate(startDate),
            'endDate': Timestamp.fromDate(DateTime(2026)),
            'emoji': '\u{1F3C3}',
          }),
        ]);
        return Stream.value(snap);
      });

      final service = SocialService(
        firestore: db,
        currentUidProvider: () => 'u1',
      );

      await expectLater(
        service.publicChallengesStream(),
        emits(
          predicate<List<Challenge>>((list) {
            return list.length == 1 &&
                list[0].id == 'ch1' &&
                list[0].title == 'Public Run';
          }),
        ),
      );
    });
  });

  group('myChallengesStream', () {
    test('returns empty stream when uid is null', () {
      final service = SocialService(
        firestore: MockFirebaseFirestore(),
        currentUidProvider: () => null,
      );
      expect(service.myChallengesStream(), emitsDone);
    });

    test('maps Firestore snapshot with participants filter', () async {
      final query = MockCollectionReference();
      final db = MockFirebaseFirestore();
      final startDate = DateTime(2025, 7, 1);

      when(db.collection('challenges')).thenReturn(query);
      when(query.where('participants', arrayContains: 'u1')).thenReturn(query);
      when(query.orderBy('endDate', descending: true)).thenReturn(query);
      when(query.snapshots()).thenAnswer((_) {
        final snap = _FakeQuerySnapshot([
          _FakeQueryDocumentSnapshot('ch2', {
            'title': 'My Sprint',
            'description': 'Personal',
            'goalType': 'calories_burned',
            'targetValue': 500,
            'durationDays': 14,
            'isPublic': false,
            'isPredefined': false,
            'createdBy': 'u0',
            'creatorName': 'Coach',
            'participants': ['u1', 'u3'],
            'startDate': Timestamp.fromDate(startDate),
            'endDate': Timestamp.fromDate(DateTime(2026)),
            'emoji': '\u{26A1}',
          }),
        ]);
        return Stream.value(snap);
      });

      final service = SocialService(
        firestore: db,
        currentUidProvider: () => 'u1',
      );

      await expectLater(
        service.myChallengesStream(),
        emits(
          predicate<List<Challenge>>((list) {
            return list.length == 1 &&
                list[0].id == 'ch2' &&
                list[0].participants.contains('u1');
          }),
        ),
      );
    });
  });

  group('challengeLeaderboardStream', () {
    test('maps Firestore snapshot to ChallengeParticipant list', () async {
      final query = MockCollectionReference();
      final db = MockFirebaseFirestore();

      when(
        db.collection('challenge_progress/c1/participants'),
      ).thenReturn(query);
      when(query.orderBy('currentValue', descending: true)).thenReturn(query);
      when(query.snapshots()).thenAnswer((_) {
        final snap = _FakeQuerySnapshot([
          _FakeQueryDocumentSnapshot('u1', {
            'name': 'Alice',
            'currentValue': 5,
          }),
          _FakeQueryDocumentSnapshot('u2', {'name': 'Bob', 'currentValue': 3}),
        ]);
        return Stream.value(snap);
      });

      final service = SocialService(
        firestore: db,
        currentUidProvider: () => 'u1',
      );

      await expectLater(
        service.challengeLeaderboardStream('c1'),
        emits(
          predicate<List<ChallengeParticipant>>((list) {
            return list.length == 2 &&
                list[0].uid == 'u1' &&
                list[0].currentValue == 5 &&
                list[1].uid == 'u2' &&
                list[1].currentValue == 3;
          }),
        ),
      );
    });
  });

  // ── Error propagation ─────────────────────────────────────────────────────

  test('sendFriendRequest rethrows callable errors', () async {
    final service = SocialService(
      firestore: MockFirebaseFirestore(),
      currentUidProvider: () => 'u1',
      callableInvoker: (_, _) async {
        throw FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'No access',
        );
      },
    );
    await expectLater(
      () => service.sendFriendRequest('u2'),
      throwsA(isA<FirebaseFunctionsException>()),
    );
  });

  test('createChallenge rethrows callable errors', () async {
    final service = SocialService(
      firestore: MockFirebaseFirestore(),
      currentUidProvider: () => 'u1',
      callableInvoker: (_, _) async {
        throw FirebaseFunctionsException(
          code: 'internal',
          message: 'Server error',
        );
      },
    );
    await expectLater(
      () => service.createChallenge(
        title: 'Test',
        description: '',
        goalType: 'workout_count',
        targetValue: 1,
        durationDays: 1,
        isPublic: true,
      ),
      throwsA(isA<FirebaseFunctionsException>()),
    );
  });

  test('removeFriend rethrows callable errors', () async {
    final service = SocialService(
      firestore: MockFirebaseFirestore(),
      currentUidProvider: () => 'u1',
      callableInvoker: (_, _) async {
        throw FirebaseFunctionsException(
          code: 'not-found',
          message: 'No such friend',
        );
      },
    );
    await expectLater(
      () => service.removeFriend('u2'),
      throwsA(isA<FirebaseFunctionsException>()),
    );
  });
}
