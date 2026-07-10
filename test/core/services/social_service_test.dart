import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitnesbuster/core/services/social_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

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
}
