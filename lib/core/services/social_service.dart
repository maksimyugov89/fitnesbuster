import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

export 'package:fitnesbuster/core/services/social_models.dart';

class SocialService implements ISocialService {
  SocialService();

  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
        await _db.doc('users/$uid').set({'fcmToken': token}, SetOptions(merge: true));
      }
      // Refresh token when it rotates
      messaging.onTokenRefresh.listen((newToken) async {
        await _db.doc('users/$uid').set({'fcmToken': newToken}, SetOptions(merge: true));
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
    await _db.doc('users/$uid').set({
      'username': username,
      'usernameLower': username.toLowerCase(),
    }, SetOptions(merge: true));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('social_username', username);
  }

  // ── Publish activity event (fanout via Cloud Function) ────────────────────

  @override
  Future<void> publishActivity(String type, Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('activity_events/$uid/items').add({
        'type': type,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      appLogger.w('SocialService: publish activity failed', error: e, stackTrace: st);
    }
  }

  // ── FRIENDS ────────────────────────────────────────────────────────────────

  @override
  Future<void> sendFriendRequest(String toUid) async {
    await _call('sendFriendRequest', {'toUid': toUid});
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    await _call('acceptFriendRequest', {'requestId': requestId});
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    await _call('declineFriendRequest', {'requestId': requestId});
  }

  @override
  Future<void> removeFriend(String friendUid) async {
    await _call('removeFriend', {'friendUid': friendUid});
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final result = await _call('searchUsers', {'query': query});
    return (result.data as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Stream<List<FriendUser>> friendsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('friends/$uid/list')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FriendUser.fromDoc).toList());
  }

  @override
  Stream<List<FriendRequest>> incomingRequestsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('friend_requests')
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
        .collection('feed/$uid/events')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(FeedEvent.fromDoc).toList());
  }

  // ── CHALLENGES ─────────────────────────────────────────────────────────────

  @override
  Future<void> joinChallenge(String challengeId) async {
    await _call('joinChallenge', {'challengeId': challengeId});
  }

  @override
  Future<void> seedChallenges() async {
    await _call('seedChallenges', {});
  }

  @override
  Future<List<String>> recordWorkout({
    required int durationMinutes,
    required int caloriesBurned,
    required int cardioMinutes,
    required int streak,
  }) async {
    final result = await _call('recordWorkout', {
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'cardioMinutes': cardioMinutes,
      'streak': streak,
    });
    final data = result.data as Map<String, dynamic>?;
    return ((data?['completed'] as List?) ?? []).cast<String>();
  }

  @override
  Stream<List<Challenge>> publicChallengesStream() {
    return _db
        .collection('challenges')
        .where('isPublic', isEqualTo: true)
        .orderBy('endDate', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map(Challenge.fromDoc).toList());
  }

  @override
  Stream<List<Challenge>> myChallengesStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('challenges')
        .where('participants', arrayContains: uid)
        .orderBy('endDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Challenge.fromDoc).toList());
  }

  @override
  Stream<List<ChallengeParticipant>> challengeLeaderboardStream(String challengeId) {
    return _db
        .collection('challenge_progress/$challengeId/participants')
        .orderBy('currentValue', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChallengeParticipant.fromDoc).toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<HttpsCallableResult<dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final fn = _functions.httpsCallable(name);
    return fn.call(data);
  }
}
