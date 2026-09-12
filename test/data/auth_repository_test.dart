import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/core/legal/legal_consent.dart';
import 'package:fitnesbuster/data/repositories/auth_repository.dart';
import 'package:fitnesbuster/domain/exceptions/auth_exception.dart';
import 'auth_repository_test.mocks.dart';

class _FakeUserCredential implements fb.UserCredential {
  final fb.User _user;
  final fb.AdditionalUserInfo? _additionalUserInfo;
  const _FakeUserCredential(
    this._user, {
    fb.AdditionalUserInfo? additionalUserInfo,
  }) : _additionalUserInfo = additionalUserInfo;
  @override
  fb.User? get user => _user;
  @override
  fb.AdditionalUserInfo? get additionalUserInfo => _additionalUserInfo;
  @override
  fb.AuthCredential? get credential => null;
}

/// `AdditionalUserInfo` has a @protected constructor, so the fake extends it
/// (a legitimate use of a protected member from a subclass).
class _FakeAdditionalUserInfo extends fb.AdditionalUserInfo {
  _FakeAdditionalUserInfo({required super.isNewUser});
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
  MockSpec<GoogleSignIn>(),
  MockSpec<GoogleSignInAccount>(),
  MockSpec<GoogleSignInAuthentication>(),
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
  const tConsent = LegalConsentAcceptance(
    source: LegalConsentSource.emailRegistration,
    localeCode: 'ru',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockFbUser = MockUser();

    when(mockFbUser.uid).thenReturn(tUid);
    when(mockFbUser.displayName).thenReturn(tName);
    when(mockFbUser.email).thenReturn(tEmail);
    when(mockFbUser.photoURL).thenReturn(null);
    when(mockFbUser.metadata).thenReturn(_FakeUserMetadata(tCreationTime));

    repo = AuthRepository(
      auth: mockAuth,
      firestore: mockFirestore,
      deleteAccountCall: () async {},
    );
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

  group('getCurrentUserWithProfile', () {
    test('hydrates the Firebase user from its Firestore profile', () async {
      when(mockAuth.currentUser).thenReturn(mockFbUser);
      final collection = MockCollectionReference();
      final docRef = MockDocumentReference();
      final consentCollection = MockCollectionReference();
      final consentDocRef = MockDocumentReference();
      final consentSnapshot = MockDocumentSnapshot();
      final snapshot = MockDocumentSnapshot();
      when(mockFirestore.collection('users')).thenReturn(collection);
      when(collection.doc(tUid)).thenReturn(docRef);
      when(docRef.collection('legal_consents')).thenReturn(consentCollection);
      when(
        consentCollection.doc(LegalConsentAcceptance.recordId),
      ).thenReturn(consentDocRef);
      when(consentSnapshot.exists).thenReturn(true);
      when(consentDocRef.get()).thenAnswer((_) async => consentSnapshot);
      when(snapshot.exists).thenReturn(true);
      when(snapshot.data()).thenReturn({
        'name': 'Firestore Name',
        'email': tEmail,
        'profile': {
          'weight': 81,
          'height': 178,
          'age': 32,
          'gender': 'male',
          'goal': 'maintain',
          'intensity': 'balanced',
          'activityLevel': 'moderatelyActive',
        },
        'currentStreak': 4,
      });
      when(docRef.get()).thenAnswer((_) async => snapshot);

      final user = await repo.getCurrentUserWithProfile();

      expect(user?.name, 'Firestore Name');
      expect(user?.profile?.weight, 81);
      expect(user?.currentStreak, 4);
    });

    test('falls back to Firebase user when Firestore read fails', () async {
      when(mockAuth.currentUser).thenReturn(mockFbUser);
      final collection = MockCollectionReference();
      final docRef = MockDocumentReference();
      when(mockFirestore.collection('users')).thenReturn(collection);
      when(collection.doc(tUid)).thenReturn(docRef);
      when(docRef.get()).thenThrow(Exception('offline'));

      final user = await repo.getCurrentUserWithProfile();

      expect(user?.name, tName);
      expect(user?.profile, isNull);
    });
  });

  group('login', () {
    test('returns UserEntity on successful login', () async {
      when(
        mockAuth.signInWithEmailAndPassword(
          email: tEmail,
          password: 'password',
        ),
      ).thenAnswer((_) async => _FakeUserCredential(mockFbUser));
      final collection = MockCollectionReference();
      final docRef = MockDocumentReference();
      final consentCollection = MockCollectionReference();
      final consentDocRef = MockDocumentReference();
      final consentSnapshot = MockDocumentSnapshot();
      final snapshot = MockDocumentSnapshot();
      when(mockFirestore.collection('users')).thenReturn(collection);
      when(collection.doc(tUid)).thenReturn(docRef);
      when(docRef.collection('legal_consents')).thenReturn(consentCollection);
      when(
        consentCollection.doc(LegalConsentAcceptance.recordId),
      ).thenReturn(consentDocRef);
      when(consentSnapshot.exists).thenReturn(true);
      when(consentDocRef.get()).thenAnswer((_) async => consentSnapshot);
      when(snapshot.exists).thenReturn(true);
      when(snapshot.data()).thenReturn({
        'name': tName,
        'nameLower': 'test user',
        'email': tEmail,
        'profile': {
          'weight': 81,
          'height': 178,
          'age': 32,
          'gender': 'male',
          'goal': 'maintain',
          'intensity': 'balanced',
          'activityLevel': 'moderatelyActive',
        },
      });
      when(docRef.get()).thenAnswer((_) async => snapshot);

      final user = await repo.login(email: tEmail, password: 'password');
      expect(user.id, tUid);
      expect(user.name, tName);
      expect(user.profile?.weight, 81);
    });

    test('throws on FirebaseAuthException', () async {
      when(
        mockAuth.signInWithEmailAndPassword(
          email: 'bad@test.com',
          password: 'wrong',
        ),
      ).thenThrow(fb.FirebaseAuthException(code: 'wrong-password'));

      expect(
        () => repo.login(email: 'bad@test.com', password: 'wrong'),
        throwsA(isA<WrongPasswordException>()),
      );
    });
  });

  group('register', () {
    test('creates Firestore doc and returns UserEntity', () async {
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: tEmail,
          password: 'password',
        ),
      ).thenAnswer((_) async => _FakeUserCredential(mockFbUser));

      when(mockFbUser.updateDisplayName(any)).thenAnswer((_) async {});

      final mockDocRef = MockDocumentReference();
      final mockConsentDocRef = MockDocumentReference();
      final mockUserCollection = MockCollectionReference();
      final mockConsentCollection = MockCollectionReference();
      final mockMissingConsentSnapshot = MockDocumentSnapshot();
      when(mockFirestore.collection('users')).thenReturn(mockUserCollection);
      when(mockUserCollection.doc(tUid)).thenReturn(mockDocRef);
      when(
        mockDocRef.collection('legal_consents'),
      ).thenReturn(mockConsentCollection);
      when(
        mockConsentCollection.doc(LegalConsentAcceptance.recordId),
      ).thenReturn(mockConsentDocRef);
      when(mockMissingConsentSnapshot.exists).thenReturn(false);
      when(
        mockConsentDocRef.get(),
      ).thenAnswer((_) async => mockMissingConsentSnapshot);
      when(mockConsentDocRef.set(any)).thenAnswer((_) async {});
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      final user = await repo.register(
        name: tName,
        email: tEmail,
        password: 'password',
        consent: tConsent,
      );

      expect(user.id, tUid);
      expect(user.name, tName);
      expect(user.email, tEmail);
      verify(
        mockConsentDocRef.set(
          argThat(
            allOf(
              containsPair('termsVersion', '2026-07-07'),
              containsPair('privacyPolicyVersion', '2026-07-17'),
              containsPair('source', 'email_registration'),
              containsPair('locale', 'ru'),
            ),
          ),
        ),
      ).called(1);
      verify(mockDocRef.set(argThat(contains('name')))).called(1);
    });
  });

  group('acceptCurrentLegalConsent', () {
    test('records google-login consent for existing current user', () async {
      when(mockAuth.currentUser).thenReturn(mockFbUser);

      final mockDocRef = MockDocumentReference();
      final mockConsentDocRef = MockDocumentReference();
      final mockUserCollection = MockCollectionReference();
      final mockConsentCollection = MockCollectionReference();
      final mockMissingConsentSnapshot = MockDocumentSnapshot();
      final mockProfileSnapshot = MockDocumentSnapshot();

      when(mockFirestore.collection('users')).thenReturn(mockUserCollection);
      when(mockUserCollection.doc(tUid)).thenReturn(mockDocRef);
      when(
        mockDocRef.collection('legal_consents'),
      ).thenReturn(mockConsentCollection);
      when(
        mockConsentCollection.doc(LegalConsentAcceptance.recordId),
      ).thenReturn(mockConsentDocRef);
      when(mockMissingConsentSnapshot.exists).thenReturn(false);
      when(
        mockConsentDocRef.get(),
      ).thenAnswer((_) async => mockMissingConsentSnapshot);
      when(mockConsentDocRef.set(any)).thenAnswer((_) async {});
      when(mockProfileSnapshot.exists).thenReturn(true);
      when(
        mockProfileSnapshot.data(),
      ).thenReturn({'name': tName, 'nameLower': 'test user', 'email': tEmail});
      when(mockDocRef.get()).thenAnswer((_) async => mockProfileSnapshot);

      final user = await repo.acceptCurrentLegalConsent(
        consent: const LegalConsentAcceptance(
          source: LegalConsentSource.googleLogin,
          localeCode: 'ru',
        ),
      );

      expect(user.id, tUid);
      verify(
        mockConsentDocRef.set(
          argThat(
            allOf(
              containsPair('termsVersion', '2026-07-07'),
              containsPair('privacyPolicyVersion', '2026-07-17'),
              containsPair('source', 'google_login'),
              containsPair('locale', 'ru'),
            ),
          ),
        ),
      ).called(1);
    });
  });

  group('logout', () {
    test('calls signOut on FirebaseAuth', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});
      await repo.logout();
      verify(mockAuth.signOut()).called(1);
    });
  });

  group('deleteAccount', () {
    test('signs out and reports an unconfirmed server deletion', () async {
      when(mockAuth.currentUser).thenReturn(null);
      when(mockAuth.signOut()).thenAnswer((_) async {});
      repo = AuthRepository(
        auth: mockAuth,
        firestore: mockFirestore,
        deleteAccountCall: () async => throw Exception('network timeout'),
      );

      await expectLater(
        repo.deleteAccount(),
        throwsA(isA<UnknownAuthException>()),
      );
      verify(mockAuth.signOut()).called(1);
    });
  });

  group('resetPassword', () {
    test('calls sendPasswordResetEmail', () async {
      when(
        mockAuth.sendPasswordResetEmail(email: tEmail),
      ).thenAnswer((_) async {});
      await repo.resetPassword(tEmail);
      verify(mockAuth.sendPasswordResetEmail(email: tEmail)).called(1);
    });
  });

  group('signInWithGoogle', () {
    late MockGoogleSignIn googleSignIn;

    // A consent-less Google account: the flow must ask for consent instead of
    // dropping the freshly created Firebase session.
    void stubGoogleSignIn({required bool isNewUser}) {
      googleSignIn = MockGoogleSignIn();
      final account = MockGoogleSignInAccount();
      final gAuth = MockGoogleSignInAuthentication();
      when(googleSignIn.signIn()).thenAnswer((_) async => account);
      when(account.authentication).thenAnswer((_) async => gAuth);
      when(gAuth.accessToken).thenReturn('access-token');
      when(gAuth.idToken).thenReturn('id-token');
      when(mockAuth.signInWithCredential(any)).thenAnswer(
        (_) async => _FakeUserCredential(
          mockFbUser,
          additionalUserInfo: _FakeAdditionalUserInfo(isNewUser: isNewUser),
        ),
      );
      repo = AuthRepository(
        auth: mockAuth,
        firestore: mockFirestore,
        deleteAccountCall: () async {},
        googleSignIn: googleSignIn,
      );

      final userCollection = MockCollectionReference();
      final docRef = MockDocumentReference();
      final consentCollection = MockCollectionReference();
      final consentDocRef = MockDocumentReference();
      final missingConsent = MockDocumentSnapshot();
      when(mockFirestore.collection('users')).thenReturn(userCollection);
      when(userCollection.doc(tUid)).thenReturn(docRef);
      when(docRef.collection('legal_consents')).thenReturn(consentCollection);
      when(
        consentCollection.doc(LegalConsentAcceptance.recordId),
      ).thenReturn(consentDocRef);
      when(missingConsent.exists).thenReturn(false);
      when(consentDocRef.get()).thenAnswer((_) async => missingConsent);
    }

    test('a new Google user without consent keeps the session', () async {
      stubGoogleSignIn(isNewUser: true);

      await expectLater(
        repo.signInWithGoogle(),
        throwsA(
          isA<TermsRequiredException>()
              .having((e) => e.code, 'code', 'terms-required')
              .having((e) => e.isNewRegistration, 'isNewRegistration', isTrue),
        ),
      );

      // The UI needs a live session to show the dialog and to call
      // acceptCurrentLegalConsent(); signing out left new users stuck.
      verifyNever(mockAuth.signOut());
      verifyNever(mockFbUser.delete());
      verify(googleSignIn.signIn()).called(1);
    });

    test(
      'existing Google user without consent keeps the session too',
      () async {
        stubGoogleSignIn(isNewUser: false);

        await expectLater(
          repo.signInWithGoogle(),
          throwsA(
            isA<TermsRequiredException>()
                .having((e) => e.code, 'code', 'terms-required')
                .having(
                  (e) => e.isNewRegistration,
                  'isNewRegistration',
                  isFalse,
                ),
          ),
        );

        verifyNever(mockAuth.signOut());
        verifyNever(mockFbUser.delete());
      },
    );
  });
}
