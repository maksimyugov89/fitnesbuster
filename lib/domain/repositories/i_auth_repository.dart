import 'package:fitnesbuster/domain/entities/entities.dart';

abstract interface class IAuthRepository {
  UserEntity? get currentUser;
  Stream<UserEntity?> get userChanges;

  /// Fetches the current user with their full Firestore profile (weight,
  /// height, etc). Unlike [currentUser] — which returns instantly from the
  /// cached Firebase Auth user without a profile — this awaits the Firestore
  /// doc, so callers who need profile data at launch don't have to wait for
  /// a subsequent [userChanges] emission to correct it.
  Future<UserEntity?> getCurrentUserWithProfile();

  /// Whether the currently signed-in Firebase user has a verified email,
  /// based on the locally cached user (no network call). Google-linked
  /// accounts are verified automatically by Firebase.
  bool get isEmailVerified;

  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  });
  Future<UserEntity> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<void> logout();
  Future<void> updateProfile({String? name, String? photoUrl});

  /// Sends (or resends) the verification email to the current user.
  Future<void> sendEmailVerification();

  /// Refreshes the current user from Firebase and returns the up-to-date
  /// email verification status.
  Future<bool> reloadAndCheckEmailVerified();

  /// Permanently deletes the current user's account and all associated data
  /// (Firestore documents + Firebase Auth record) via the `deleteAccount`
  /// Cloud Function, then clears local caches and signs out.
  Future<void> deleteAccount();

  /// Reloads the current Firebase user from the server. Throws
  /// [FirebaseAuthException] with code `user-not-found` or
  /// `user-token-expired` if the account was deleted / disabled.
  Future<void> reloadUser();

  /// Signs out the current Firebase user locally (no server call).
  /// Unlike [logout], this does *not* attempt Firestore / FCM cleanup.
  Future<void> signOut();
}
