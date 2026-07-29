import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/data/repositories/user_repository.dart';
import 'package:fitnesbuster/domain/entities/body_measurement.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

import 'user_repository_test.mocks.dart';

class _FakeUserMetadata implements fb.UserMetadata {
  final DateTime _creationTime;
  const _FakeUserMetadata(this._creationTime);
  @override
  DateTime? get creationTime => _creationTime;
  @override
  DateTime? get lastSignInTime => _creationTime;
}

@GenerateNiceMocks([
  MockSpec<fb.FirebaseAuth>(),
  MockSpec<fb.User>(),
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockFbUser;
  late UserRepository repo;

  const tUid = 'test-uid-123';
  const tName = 'Test User';
  const tEmail = 'test@example.com';
  final tCreationTime = DateTime(2024, 1, 1);

  Map<String, dynamic> buildUserDoc({
    String name = tName,
    String email = tEmail,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? onboarding,
  }) {
    return {
      'name': name,
      'email': email,
      if (profile != null) 'profile': profile,
      if (onboarding != null) 'onboarding': onboarding,
    };
  }

  Map<String, dynamic> buildProfileMap({
    double weight = 80,
    double height = 175,
    int age = 30,
    String gender = 'male',
    String goal = 'loseWeight',
    String intensity = 'balanced',
    String activityLevel = 'moderatelyActive',
  }) {
    return {
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'goal': goal,
      'intensity': intensity,
      'activityLevel': activityLevel,
    };
  }

  MockDocumentSnapshot stubDocSnapshot(Map<String, dynamic> data) {
    final snap = MockDocumentSnapshot();
    when(snap.id).thenReturn(tUid);
    when(snap.exists).thenReturn(true);
    when(snap.data()).thenReturn(data);
    return snap;
  }

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockFbUser = MockUser();

    when(mockFbUser.uid).thenReturn(tUid);
    when(mockFbUser.displayName).thenReturn(tName);
    when(mockFbUser.email).thenReturn(tEmail);
    when(mockFbUser.photoURL).thenReturn(null);
    when(mockFbUser.metadata).thenReturn(_FakeUserMetadata(tCreationTime));

    repo = UserRepository(auth: mockAuth, firestore: mockFirestore);
  });

  MockDocumentReference stubUserDocRef() {
    final docRef = MockDocumentReference();
    final usersCollection = MockCollectionReference();
    when(mockFirestore.collection('users')).thenReturn(usersCollection);
    when(usersCollection.doc(tUid)).thenReturn(docRef);
    return docRef;
  }

  // ─── getUser ───────────────────────────────────────────────────────────────

  group('getUser', () {
    test(
      'returns entity from Firestore when doc exists with profile',
      () async {
        final docRef = stubUserDocRef();
        final docSnapshot = stubDocSnapshot(
          buildUserDoc(profile: buildProfileMap()),
        );
        when(docRef.get()).thenAnswer((_) async => docSnapshot);

        final user = await repo.getUser(tUid);

        expect(user.id, tUid);
        expect(user.name, tName);
        expect(user.email, tEmail);
        expect(user.profile, isNotNull);
        expect(user.profile!.weight, 80);
        expect(user.profile!.goal, FitnessGoal.loseWeight);
      },
    );

    test(
      'falls back to Firebase auth user when Firestore doc does not exist',
      () async {
        final docRef = stubUserDocRef();
        final docSnapshot = MockDocumentSnapshot();
        when(docSnapshot.exists).thenReturn(false);
        when(docRef.get()).thenAnswer((_) async => docSnapshot);

        when(mockAuth.currentUser).thenReturn(mockFbUser);

        final user = await repo.getUser(tUid);
        expect(user.id, tUid);
        expect(user.name, tName);
        expect(user.email, tEmail);
        expect(user.profile, isNull);
      },
    );

    test(
      'falls back to defaults when Firestore doc does not exist and auth is null',
      () async {
        final docRef = stubUserDocRef();
        final docSnapshot = MockDocumentSnapshot();
        when(docSnapshot.exists).thenReturn(false);
        when(docRef.get()).thenAnswer((_) async => docSnapshot);

        when(mockAuth.currentUser).thenReturn(null);

        final user = await repo.getUser(tUid);
        expect(user.id, tUid);
        expect(user.name, 'Пользователь');
        expect(user.email, '');
      },
    );
  });

  // ─── updateProfile ─────────────────────────────────────────────────────────

  group('updateProfile', () {
    test('calls set with merge on user doc', () async {
      final docRef = stubUserDocRef();
      when(
        docRef.set(any, SetOptions(merge: true)),
      ).thenAnswer((_) => Future.value());

      final user = UserEntity(
        id: tUid,
        name: 'Updated Name',
        email: 'updated@test.com',
        avatarUrl: 'https://example.com/avatar.png',
        profile: const UserProfile(
          weight: 82,
          height: 176,
          age: 31,
          gender: Gender.male,
          goal: FitnessGoal.maintain,
          intensity: IntensityLevel.intensive,
          activityLevel: ActivityLevel.veryActive,
        ),
        createdAt: DateTime(2024),
      );

      final result = await repo.updateProfile(user);
      expect(result.name, 'Updated Name');

      final captured = Map<String, dynamic>.from(
        verify(docRef.set(captureAny, any)).captured.single as Map,
      );
      expect(captured['name'], 'Updated Name');
      expect(captured['nameLower'], 'updated name');
      expect(captured['photoUrl'], 'https://example.com/avatar.png');
      expect(captured['profile']['trainingExperience'], 'novice');
    });
  });

  // ─── saveOnboardingData ────────────────────────────────────────────────────

  group('saveOnboardingData', () {
    test('saves goal, intensity, location, running with profile', () async {
      final docRef = stubUserDocRef();
      when(
        docRef.set(any, SetOptions(merge: true)),
      ).thenAnswer((_) => Future.value());

      final docSnapshot = stubDocSnapshot(
        buildUserDoc(
          profile: buildProfileMap(),
          onboarding: {
            'goal': 'loseWeight',
            'intensity': 'balanced',
            'location': 'gym',
            'running': 'withRunning',
          },
        ),
      );
      when(docRef.get()).thenAnswer((_) async => docSnapshot);

      final result = await repo.saveOnboardingData(
        userId: tUid,
        goal: FitnessGoal.loseWeight,
        intensity: IntensityLevel.balanced,
        location: 'gym',
        running: 'withRunning',
        profile: const UserProfile(
          weight: 75,
          height: 170,
          age: 25,
          gender: Gender.female,
          goal: FitnessGoal.loseWeight,
          intensity: IntensityLevel.balanced,
          activityLevel: ActivityLevel.lightlyActive,
        ),
      );

      expect(result.id, tUid);
      verify(docRef.set(any, any)).called(1);
    });
  });

  // ─── updateWorkoutSettings ─────────────────────────────────────────────────

  group('updateWorkoutSettings', () {
    test('updates location and running fields', () async {
      final docRef = stubUserDocRef();
      when(
        docRef.set(any, SetOptions(merge: true)),
      ).thenAnswer((_) => Future.value());

      final docSnapshot = stubDocSnapshot(buildUserDoc());
      when(docRef.get()).thenAnswer((_) async => docSnapshot);

      final result = await repo.updateWorkoutSettings(
        userId: tUid,
        location: 'outdoor',
        running: 'noRunning',
      );

      expect(result.id, tUid);
      final captured = Map<String, dynamic>.from(
        verify(docRef.set(captureAny, any)).captured.single as Map,
      );
      expect(captured['onboarding'], {
        'location': 'outdoor',
        'running': 'noRunning',
      });
      expect(captured, isNot(contains('onboarding.location')));
    });
  });

  // ─── updateGoal ────────────────────────────────────────────────────────────

  group('updateGoal', () {
    test('updates profile.goal field', () async {
      final docRef = stubUserDocRef();
      when(docRef.update(any)).thenAnswer((_) => Future.value());

      await repo.updateGoal(userId: tUid, goal: FitnessGoal.gainWeight);

      verify(docRef.update(any)).called(1);
    });

    test('updates training experience without replacing the profile', () async {
      final docRef = stubUserDocRef();
      when(docRef.update(any)).thenAnswer((_) => Future.value());

      await repo.updateTrainingExperience(
        userId: tUid,
        trainingExperience: TrainingExperience.experienced,
      );

      final captured = Map<String, dynamic>.from(
        verify(docRef.update(captureAny)).captured.single as Map,
      );
      expect(captured['profile.trainingExperience'], 'experienced');
      expect(captured, contains('updatedAt'));
    });
  });

  // ─── measurements ──────────────────────────────────────────────────────────

  group('measurements', () {
    test('saveMeasurement writes with set and merge', () async {
      final docRef = stubUserDocRef();
      when(
        docRef.set(any, SetOptions(merge: true)),
      ).thenAnswer((_) => Future.value());

      final m = BodyMeasurement(
        date: DateTime(2024, 6, 15),
        chestCm: 100,
        waistCm: 85,
        hipsCm: 95,
      );

      await repo.saveMeasurement(userId: tUid, measurement: m);
      verify(docRef.set(any, any)).called(1);
    });

    test('getMeasurements returns sorted list', () async {
      final docRef = stubUserDocRef();
      final now = DateTime(2024, 6, 20);
      final yesterday = DateTime(2024, 6, 19);

      final docSnapshot = MockDocumentSnapshot();
      when(docSnapshot.data()).thenReturn({
        'bodyMeasurements': [
          {'date': now.millisecondsSinceEpoch, 'chestCm': 100},
          {'date': yesterday.millisecondsSinceEpoch, 'chestCm': 99},
        ],
      });
      when(docRef.get()).thenAnswer((_) async => docSnapshot);

      final list = await repo.getMeasurements(tUid);
      expect(list.length, 2);
      expect(list[0].date, now);
      expect(list[1].date, yesterday);
    });

    test('getMeasurements returns empty list when no measurements', () async {
      final docRef = stubUserDocRef();
      final docSnapshot = MockDocumentSnapshot();
      when(docSnapshot.data()).thenReturn({});
      when(docRef.get()).thenAnswer((_) async => docSnapshot);

      final list = await repo.getMeasurements(tUid);
      expect(list, isEmpty);
    });
  });
}
