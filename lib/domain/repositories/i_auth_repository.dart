import 'package:fitnesbuster/domain/entities/entities.dart';

abstract interface class IAuthRepository {
  UserEntity? get currentUser;
  Stream<UserEntity?> get userChanges;
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
}
