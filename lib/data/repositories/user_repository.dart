import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/entities/body_measurement.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/core/utils/enum_parser.dart';
import 'package:fitnesbuster/core/cache/hive_cache.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/constants/firestore_collections.dart';

class UserRepository implements IUserRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserRepository({required fb.FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _firestore = firestore;

  @override
  Future<UserEntity> getUser(String userId) async {
    final doc = await _firestore.collection(FirestoreCollections.users).doc(userId).get();
    if (!doc.exists) {
      final fbUser = _auth.currentUser;
      return UserEntity(
        id: userId,
        name: fbUser?.displayName ?? AppLocalizations.tl('socialDefaultUser'),
        email: fbUser?.email ?? '',
        createdAt: fbUser?.metadata.creationTime ?? DateTime.now(),
      );
    }
    return _docToEntity(doc);
  }

  @override
  Future<UserEntity> updateProfile(UserEntity user) async {
    final data = <String, dynamic>{
      'name': user.name,
      'nameLower': user.name.toLowerCase(),
      'email': user.email,
    };
    if (user.avatarUrl != null) data['photoUrl'] = user.avatarUrl;
    if (user.profile != null) {
      data['profile'] = _profileToMap(user.profile!);
    }
    await _firestore.collection(FirestoreCollections.users).doc(user.id).set(data, SetOptions(merge: true));
    return user;
  }

  @override
  Future<UserEntity> saveOnboardingData({
    required String userId,
    required FitnessGoal goal,
    required IntensityLevel intensity,
    String? location,
    String? running,
    String? city,
    UserProfile? profile,
  }) async {
    final data = <String, dynamic>{
      'onboarding': {
        'goal': goal.name,
        'intensity': intensity.name,
        if (location != null) 'location': location,
        if (running != null) 'running': running,
        if (city != null && city.isNotEmpty) 'city': city,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (profile != null) {
      data['profile'] = _profileToMap(profile);
    }
    await _firestore.collection(FirestoreCollections.users).doc(userId).set(data, SetOptions(merge: true));
    return getUser(userId);
  }

  @override
  Future<UserEntity> updateWorkoutSettings({
    required String userId,
    required String location,
    required String running,
  }) async {
    try {
      await _firestore.collection(FirestoreCollections.users).doc(userId).set({
        'onboarding.location': location,
        'onboarding.running': running,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      appLogger.w('UserRepository: Firestore unavailable for workout settings', error: e, stackTrace: st);
    }
    return getUser(userId);
  }

  @override
  Future<void> saveAiPlans({
    required String userId,
    required String workoutPlanJson,
    required String mealPlanJson,
  }) async {
    await HiveCache.saveAiPlans(
      userId,
      workoutPlan: workoutPlanJson,
      mealPlan: mealPlanJson,
    );
    try {
      await _firestore.collection(FirestoreCollections.users).doc(userId).set({
        'aiPlans': {
          'workoutPlan': workoutPlanJson,
          'mealPlan': mealPlanJson,
          'generatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await HiveCache.clearSyncNeeded(userId);
    } catch (e, st) {
      appLogger.w('UserRepository: saveAiPlans to Firestore failed', error: e, stackTrace: st);
      await HiveCache.setNeedsSync(userId);
    }
  }

  @override
  Future<void> saveTestWeekCompleted({required String userId}) async {
    await _firestore.collection(FirestoreCollections.users).doc(userId).set({
      'testWeekCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await HiveCache.setTestWeekCompleted(userId);
  }

  @override
  Future<bool> isTestWeekCompleted(String userId) async {
    // Serve from cache immediately; update cache from Firestore in background
    final cached = HiveCache.getTestWeekCompleted(userId);
    if (cached != null) {
      _syncTestWeekFlag(userId).ignore();
      return cached;
    }
    return _syncTestWeekFlag(userId);
  }

  Future<bool> _syncTestWeekFlag(String userId) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(userId).get();
      final result = (doc.data()?['testWeekCompleted'] as bool?) ?? false;
      if (result) await HiveCache.setTestWeekCompleted(userId);
      return result;
    } catch (e, st) {
      appLogger.w('UserRepository: _syncTestWeekFlag failed', error: e, stackTrace: st);
      return HiveCache.getTestWeekCompleted(userId) ?? false;
    }
  }

  @override
  Future<void> updateGoal({required String userId, required FitnessGoal goal}) async {
    await _firestore.collection(FirestoreCollections.users).doc(userId).update({
      'profile.goal': goal.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveMeasurement({
    required String userId,
    required BodyMeasurement measurement,
  }) async {
    await _firestore.collection(FirestoreCollections.users).doc(userId).set({
      'bodyMeasurements': FieldValue.arrayUnion([measurement.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<BodyMeasurement>> getMeasurements(String userId) async {
    final doc = await _firestore.collection(FirestoreCollections.users).doc(userId).get();
    final list = doc.data()?['bodyMeasurements'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => BodyMeasurement.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> updateWorkoutPlan({required String userId, required String workoutPlanJson}) async {
    await HiveCache.updateWorkoutPlan(userId, workoutPlanJson);
    try {
      await _firestore.collection(FirestoreCollections.users).doc(userId).update({
        'aiPlans.workoutPlan': workoutPlanJson,
        'aiPlans.generatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await HiveCache.clearSyncNeeded(userId);
    } catch (e, st) {
      appLogger.w('UserRepository: updateWorkoutPlan to Firestore failed', error: e, stackTrace: st);
      await HiveCache.setNeedsSync(userId);
    }
  }

  @override
  Future<Map<String, String?>> getAiPlans(String userId) async {
    if (HiveCache.hasAiPlans(userId)) {
      if (HiveCache.isSyncNeeded(userId)) {
        _pushCachedPlansToFirestore(userId).ignore();
      } else {
        _fetchAndCacheAiPlans(userId).ignore();
      }
      return HiveCache.getAiPlans(userId);
    }
    return _fetchAndCacheAiPlans(userId);
  }

  Future<Map<String, String?>> _fetchAndCacheAiPlans(String userId) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(userId).get();
      final data = doc.data();
      final aiPlans = data?['aiPlans'] as Map<String, dynamic>?;
      final workoutPlan = _stripMarkdownFences(
          (aiPlans?['workoutPlan'] ?? data?['workoutPlan']) as String?);
      final mealPlan = _stripMarkdownFences(
          (aiPlans?['mealPlan'] ?? data?['mealPlan']) as String?);
      await HiveCache.saveAiPlans(userId, workoutPlan: workoutPlan, mealPlan: mealPlan);
      return {'workoutPlan': workoutPlan, 'mealPlan': mealPlan};
    } catch (e, st) {
      appLogger.w('UserRepository: _fetchAndCacheAiPlans failed', error: e, stackTrace: st);
      if (HiveCache.hasAiPlans(userId)) return HiveCache.getAiPlans(userId);
      rethrow;
    }
  }

  /// Pushes HiveCache plans up to Firestore when sync was previously deferred.
  Future<void> _pushCachedPlansToFirestore(String userId) async {
    try {
      final plans = HiveCache.getAiPlans(userId);
      final workoutPlan = plans['workoutPlan'];
      final mealPlan = plans['mealPlan'];
      if (workoutPlan != null || mealPlan != null) {
        final aiPlans = <String, dynamic>{
          if (workoutPlan != null) 'workoutPlan': workoutPlan,
          if (mealPlan != null) 'mealPlan': mealPlan,
          'generatedAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection(FirestoreCollections.users).doc(userId).set({
          'aiPlans': aiPlans,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await HiveCache.clearSyncNeeded(userId);
    } catch (e, st) {
      appLogger.w('UserRepository: _pushCachedPlansToFirestore failed', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic> _profileToMap(UserProfile p) => {
    'weight': p.weight,
    'height': p.height,
    'age': p.age,
    'gender': p.gender == Gender.male ? 'male' : 'female',
    'goal': p.goal.name,
    'intensity': p.intensity.name,
    'activityLevel': p.activityLevel.name,
    if (p.medicalRestrictions.isNotEmpty) 'medicalRestrictions': p.medicalRestrictions,
    if (p.exerciseRestrictions.isNotEmpty) 'exerciseRestrictions': p.exerciseRestrictions,
    if (p.targetWeight != null) 'targetWeight': p.targetWeight,
  };

  String? _stripMarkdownFences(String? json) {
    if (json == null) return null;
    final trimmed = json.trim();
    final full = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(trimmed);
    if (full != null) return full.group(1)!.trim();
    final open = RegExp(r'^```(?:json)?\s*').firstMatch(trimmed);
    if (open != null) return trimmed.substring(open.end).trim();
    return trimmed;
  }

  UserEntity _docToEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    UserProfile? profile;
    if (data?['profile'] != null) {
      final p = data!['profile'] as Map<String, dynamic>;
      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      profile = UserProfile(
        weight: (p['weight'] as num).toDouble(),
        height: (p['height'] as num).toDouble(),
        age: p['age'] as int,
        gender: parseGender(p['gender'] as String?),
        goal: parseFitnessGoal(p['goal'] as String?),
        intensity: parseIntensityLevel(p['intensity'] as String?),
        activityLevel: parseActivityLevel(p['activityLevel'] as String?),
        medicalRestrictions: (p['medicalRestrictions'] as List<dynamic>?)
            ?.map((e) => e.toString()).toList() ?? const [],
        exerciseRestrictions: (p['exerciseRestrictions'] as List<dynamic>?)
            ?.map((e) => e.toString()).toList() ?? const [],
        workoutLocation: onboarding?['location'] as String?,
        runningPreference: onboarding?['running'] as String?,
        city: onboarding?['city'] as String?,
        testWeekCompleted: (data['testWeekCompleted'] as bool?) ?? false,
      );
    }
    return UserEntity(
      id: doc.id,
      name: data?['name'] as String? ?? '',
      email: data?['email'] as String? ?? '',
      avatarUrl: data?['photoUrl'] as String?,
      profile: profile,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
