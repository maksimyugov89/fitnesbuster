import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/data/repositories/auth_repository.dart';
import 'auth_repository_test.mocks.dart';

class _FakeUserCredential implements fb.UserCredential {
  final fb.User _user;
  const _FakeUserCredential(this._user);
  @override
  fb.User? get user => _user;
  @override
  fb.AdditionalUserInfo? get additionalUserInfo => null;
  @override
  fb.AuthCredential? get credential => null;
}

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
  late AuthRepository repo;

  late MockUser mockFbUser;

  const tUid = 'test-uid-123';
  const tName = 'Test User';
  const tEmail = 'test@example.com';
  final tCreationTime = DateTime(2024, 1, 1);

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockFbUser = MockUser();

    when(mockFbUser.uid).thenReturn(tUid);
    when(mockFbUser.displayName).thenReturn(tName);
    when(mockFbUser.email).thenReturn(tEmail);
    when(mockFbUser.photoURL).thenReturn(null);
    when(mockFbUser.metadata).thenReturn(_FakeUserMetadata(tCreationTime));

    repo = AuthRepository(auth: mockAuth, firestore: mockFirestore);
  });

  group('currentUser', () {
    test('returns null when no Firebase user', () {
      when(mockAuth.currentUser).thenReturn(null);
      expect(repo.currentUser, isNull);
    });

    test('returns UserEntity when Firebase user exists', () {
      when(mockAuth.currentUser).thenReturn(mockFbUser);
      final user = repo.currentUser;
      expect(user, isNotNull);
      expect(user!.id, tUid);
      expect(user.name, tName);
      expect(user.email, tEmail);
    });

    test('UserEntity has correct default values when displayName is null', () {
      final anonUser = MockUser();
      when(anonUser.uid).thenReturn('anon-1');
      when(anonUser.displayName).thenReturn(null);
      when(anonUser.email).thenReturn(null);
      when(anonUser.photoURL).thenReturn(null);
      when(anonUser.metadata).thenReturn(_FakeUserMetadata(DateTime(2023)));

      when(mockAuth.currentUser).thenReturn(anonUser);
      final user = repo.currentUser!;
      expect(user.name, 'Пользователь');
      expect(user.email, '');
    });
  });

  group('login', () {
    test('returns UserEntity on successful login', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: tEmail,
        password: 'password',
      )).thenAnswer((_) async => _FakeUserCredential(mockFbUser));

      final user = await repo.login(email: tEmail, password: 'password');
      expect(user.id, tUid);
      expect(user.name, tName);
    });

    test('throws on FirebaseAuthException', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: 'bad@test.com',
        password: 'wrong',
      )).thenThrow(fb.FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => repo.login(email: 'bad@test.com', password: 'wrong'),
        throwsA(isA<fb.FirebaseAuthException>()),
      );
    });
  });

  group('register', () {
    test('creates Firestore doc and returns UserEntity', () async {
      when(mockAuth.createUserWithEmailAndPassword(
        email: tEmail,
        password: 'password',
      )).thenAnswer((_) async => _FakeUserCredential(mockFbUser));

      when(mockFbUser.updateDisplayName(any)).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockUserCollection = MockCollectionReference();
      when(mockFirestore.collection('users')).thenReturn(mockUserCollection);
      when(mockUserCollection.doc(tUid)).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      final user = await repo.register(
        name: tName,
        email: tEmail,
        password: 'password',
      );

      expect(user.id, tUid);
      expect(user.name, tName);
      expect(user.email, tEmail);
      verify(mockDocRef.set(argThat(contains('name')))).called(1);
    });
  });

  group('logout', () {
    test('calls signOut on FirebaseAuth', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});
      await repo.logout();
      verify(mockAuth.signOut()).called(1);
    });
  });

  group('resetPassword', () {
    test('calls sendPasswordResetEmail', () async {
      when(mockAuth.sendPasswordResetEmail(email: tEmail))
          .thenAnswer((_) async {});
      await repo.resetPassword(tEmail);
      verify(mockAuth.sendPasswordResetEmail(email: tEmail)).called(1);
    });
  });
}
