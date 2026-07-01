import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/exceptions/auth_exception.dart';
import 'package:fitnesbuster/core/utils/enum_parser.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/constants/firestore_collections.dart';

class AuthRepository implements IAuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required fb.FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  @override
  UserEntity? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _fbUserToEntity(fbUser);
  }

  @override
  Stream<UserEntity?> get userChanges => _auth.authStateChanges().asyncMap((
    fbUser,
  ) async {
    if (fbUser == null) return null;
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(fbUser.uid)
          .get();
      if (doc.exists) return _docToEntity(fbUser, doc);
    } catch (e, st) {
      appLogger.w('AuthRepository: load user doc', error: e, stackTrace: st);
    }
    return _fbUserToEntity(fbUser);
  });

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = result.user!;
      await _ensureFirestoreDoc(fbUser);
      return _fbUserToEntity(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  Future<void> _ensureFirestoreDoc(fb.User fbUser) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(fbUser.uid)
          .get();
      final data = doc.data();
      if (!doc.exists || data == null || data['nameLower'] == null) {
        final name =
            (fbUser.displayName?.isNotEmpty == true
                    ? fbUser.displayName!
                    : (fbUser.email ?? '').split('@').first)
                .trim();
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(fbUser.uid)
            .set({
              'name': name,
              'nameLower': name.toLowerCase(),
              'email': fbUser.email ?? '',
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e, st) {
      appLogger.w(
        'AuthRepository: ensureFirestoreDoc failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = result.user!;
      await fbUser.updateDisplayName(name.trim());
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(fbUser.uid)
          .set({
            'name': name.trim(),
            'nameLower': name.trim().toLowerCase(),
            'email': email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
      return _fbUserToEntity(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null)
      throw Exception(AppLocalizations.tl('googleLoginCancelled'));
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final fbUser = result.user!;
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(fbUser.uid)
        .get();
    if (!doc.exists) {
      final gName =
          fbUser.displayName ??
          googleUser.displayName ??
          AppLocalizations.tl('socialDefaultUser');
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(fbUser.uid)
          .set({
            'name': gName,
            'nameLower': gName.toLowerCase(),
            'email': fbUser.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
    }
    return _fbUserToEntity(fbUser);
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> logout() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await FirebaseMessaging.instance.deleteToken();
        await _firestore.collection(FirestoreCollections.users).doc(uid).update(
          {'fcmToken': FieldValue.delete()},
        );
      }
    } catch (e, st) {
      appLogger.w(
        'AuthRepository: delete FCM token on logout',
        error: e,
        stackTrace: st,
      );
    }
    await _auth.signOut();
  }

  @override
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return;
    if (name != null) await fbUser.updateDisplayName(name);
    if (photoUrl != null) await fbUser.updatePhotoURL(photoUrl);
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(fbUser.uid)
        .update({
          if (name != null) 'name': name,
          if (name != null) 'nameLower': name.toLowerCase(),
          if (photoUrl != null) 'photoUrl': photoUrl,
        });
  }

  UserEntity _fbUserToEntity(fb.User fbUser) {
    return UserEntity(
      id: fbUser.uid,
      name: fbUser.displayName ?? AppLocalizations.tl('socialDefaultUser'),
      email: fbUser.email ?? '',
      avatarUrl: fbUser.photoURL,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  UserEntity _docToEntity(fb.User fbUser, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    UserProfile? profile;
    if (data != null && data['profile'] != null) {
      final p = data['profile'] as Map<String, dynamic>;
      profile = UserProfile(
        weight: (p['weight'] as num).toDouble(),
        height: (p['height'] as num).toDouble(),
        age: p['age'] as int,
        gender: parseGender(p['gender'] as String?),
        goal: parseFitnessGoal(p['goal'] as String?),
        intensity: parseIntensityLevel(p['intensity'] as String?),
        activityLevel: parseActivityLevel(p['activityLevel'] as String?),
      );
    }
    return UserEntity(
      id: fbUser.uid,
      name:
          (data?['name'] as String?) ??
          fbUser.displayName ??
          AppLocalizations.tl('socialDefaultUser'),
      email: (data?['email'] as String?) ?? fbUser.email ?? '',
      avatarUrl: data?['photoUrl'] as String? ?? fbUser.photoURL,
      profile: profile,
      createdAt:
          (data?['createdAt'] as Timestamp?)?.toDate() ??
          fbUser.metadata.creationTime ??
          DateTime.now(),
    );
  }

  AuthException _mapFirebaseException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundException();
      case 'wrong-password':
        return const WrongPasswordException();
      case 'invalid-email':
        return const InvalidEmailException();
      case 'user-disabled':
        return const UserDisabledException();
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'weak-password':
        return const WeakPasswordException();
      case 'operation-not-allowed':
        return const OperationNotAllowedException();
      case 'too-many-requests':
        return const TooManyRequestsException();
      default:
        return UnknownAuthException(e.code);
    }
  }
}
