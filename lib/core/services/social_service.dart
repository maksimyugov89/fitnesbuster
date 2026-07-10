import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/constants/firestore_collections.dart';
import 'package:fitnesbuster/data/models/user_search_result.dart';

export 'package:fitnesbuster/core/services/social_models.dart';

typedef CurrentUidProvider = String? Function();
typedef SocialCallableInvoker =
    Future<Object?> Function(String name, Map<String, dynamic> data);

class SocialService implements ISocialService {
  SocialService({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
    CurrentUidProvider? currentUidProvider,
    SocialCallableInvoker? callableInvoker,
  }) : _db = firestore,
       _functions = functions,
       _currentUidProvider =
           currentUidProvider ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _callableInvoker = callableInvoker;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functions;
  final CurrentUidProvider _currentUidProvider;
  final SocialCallableInvoker? _callableInvoker;

  String? get _uid => _currentUidProvider();

  // ── FCM token registration ─────────────────────────────────────────────────

  @override
  Future<void> initFcm() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) {
        await _db.doc('${FirestoreCollections.users}/$uid').set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
      // Refresh token when it rotates
      messaging.onTokenRefresh.listen((newToken) async {
        await _db.doc('${FirestoreCollections.users}/$uid').set({
          'fcmToken': newToken,
        }, SetOptions(merge: true));
      });
    } catch (e, st) {
      appLogger.w('SocialService: FCM init failed', error: e, stackTrace: st);
    }
  }

  // ── Save username (called once from profile setup) ─────────────────────────

  @override
  Future<void> setUsername(String username) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.doc('${FirestoreCollections.users}/$uid').set({
        'username': username,
        'usernameLower': username.toLowerCase(),
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('social_username', username);
    } catch (e, st) {
      appLogger.w(
        'SocialService: setUsername failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── Publish activity event (fanout via Cloud Function) ────────────────────

  @override
  Future<void> publishActivity(String type, Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _call('publishActivity', {'type': type, 'data': data});
    } catch (e, st) {
      appLogger.w(
        'SocialService: publish activity failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── FRIENDS ────────────────────────────────────────────────────────────────

  @override
  Future<void> sendFriendRequest(String toUid) async {
    try {
      await _call('sendFriendRequest', {'toUid': toUid});
    } catch (e, st) {
      appLogger.w(
        'SocialService: sendFriendRequest failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _call('acceptFriendRequest', {'requestId': requestId});
    } catch (e, st) {
      appLogger.w(
        'SocialService: acceptFriendRequest failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _call('declineFriendRequest', {'requestId': requestId});
    } catch (e, st) {
      appLogger.w(
        'SocialService: declineFriendRequest failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> removeFriend(String friendUid) async {
    try {
      await _call('removeFriend', {'friendUid': friendUid});
    } catch (e, st) {
      appLogger.w(
        'SocialService: removeFriend failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final data = await _call('searchUsers', {'query': query});
      return (data as List? ?? [])
          .map(
            (e) =>
                UserSearchResult.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (e, st) {
      appLogger.w(
        'SocialService: searchUsers failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Stream<List<FriendUser>> friendsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection(FirestoreCollections.friendsList(uid))
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FriendUser.fromDoc).toList());
  }

  @override
  Stream<List<FriendRequest>> incomingRequestsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection(FirestoreCollections.friendRequests)
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FriendRequest.fromDoc).toList());
  }

  // ── FEED ───────────────────────────────────────────────────────────────────

  @override
  Stream<List<FeedEvent>> feedStream({int limit = 40}) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection(FirestoreCollections.feed(uid))
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(FeedEvent.fromDoc).toList());
  }

  // ── CHALLENGES ─────────────────────────────────────────────────────────────

  @override
  Future<String> createChallenge({
    required String title,
    required String description,
    required String goalType,
    required int targetValue,
    required int durationDays,
    required bool isPublic,
  }) async {
    try {
      final data = await _call('createChallenge', {
        'title': title,
        'description': description,
        'goalType': goalType,
        'targetValue': targetValue,
        'durationDays': durationDays,
        'isPublic': isPublic,
      });
      final response = data as Map<String, dynamic>?;
      return response?['challengeId'] as String? ?? '';
    } catch (e, st) {
      appLogger.w(
        'SocialService: createChallenge failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    try {
      await _call('joinChallenge', {'challengeId': challengeId});
    } catch (e, st) {
      appLogger.w(
        'SocialService: joinChallenge failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> leaveChallenge(String challengeId) async {
    try {
      await _call('leaveChallenge', {'challengeId': challengeId});
    } catch (e, st) {
      appLogger.w(
        'SocialService: leaveChallenge failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _call('deleteChallenge', {'challengeId': challengeId});
    } catch (e, st) {
      appLogger.w(
        'SocialService: deleteChallenge failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> recordWorkout({
    required int durationMinutes,
    required int caloriesBurned,
    required int cardioMinutes,
    required int streak,
  }) async {
    try {
      final data = await _call('recordWorkout', {
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'cardioMinutes': cardioMinutes,
        'streak': streak,
      });
      final response = data as Map<String, dynamic>?;
      return ((response?['completed'] as List?) ?? []).cast<String>();
    } catch (e, st) {
      appLogger.w(
        'SocialService: recordWorkout failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Challenge>> publicChallengesStream() {
    return _db
        .collection(FirestoreCollections.challenges)
        .where('isPublic', isEqualTo: true)
        .orderBy('endDate', descending: true)
        .limit(30)
        .snapshots()
        .map((s) {
          appLogger.i('publicChallengesStream snapshot count=${s.docs.length}');
          return s.docs.map(Challenge.fromDoc).toList();
        });
  }

  @override
  Stream<List<Challenge>> myChallengesStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection(FirestoreCollections.challenges)
        .where('participants', arrayContains: uid)
        .orderBy('endDate', descending: true)
        .snapshots()
        .map((s) {
          appLogger.i(
            'myChallengesStream snapshot count=${s.docs.length} uid=$uid',
          );
          return s.docs.map(Challenge.fromDoc).toList();
        });
  }

  @override
  Stream<List<ChallengeParticipant>> challengeLeaderboardStream(
    String challengeId,
  ) {
    return _db
        .collection(FirestoreCollections.challengeProgress(challengeId))
        .orderBy('currentValue', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChallengeParticipant.fromDoc).toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Object?> _call(String name, Map<String, dynamic> data) async {
    final invoker = _callableInvoker;
    if (invoker != null) return invoker(name, data);
    final functions =
        _functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');
    final fn = functions.httpsCallable(name);
    final result = await fn.call(data);
    return result.data;
  }
}
