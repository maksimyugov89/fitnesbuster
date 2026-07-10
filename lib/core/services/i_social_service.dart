import 'package:fitnesbuster/core/services/social_models.dart';
import 'package:fitnesbuster/data/models/user_search_result.dart';

abstract interface class ISocialService {
  Future<void> initFcm();
  Future<void> setUsername(String username);
  Future<void> publishActivity(String type, Map<String, dynamic> data);

  Future<void> sendFriendRequest(String toUid);
  Future<void> acceptFriendRequest(String requestId);
  Future<void> declineFriendRequest(String requestId);
  Future<void> removeFriend(String friendUid);
  Future<List<UserSearchResult>> searchUsers(String query);
  Stream<List<FriendUser>> friendsStream();
  Stream<List<FriendRequest>> incomingRequestsStream();

  Stream<List<FeedEvent>> feedStream({int limit});

  Future<String> createChallenge({
    required String title,
    required String description,
    required String goalType,
    required int targetValue,
    required int durationDays,
    required bool isPublic,
  });
  Future<void> joinChallenge(String challengeId);
  Future<void> leaveChallenge(String challengeId);
  Future<void> deleteChallenge(String challengeId);
  Future<List<String>> recordWorkout({
    required int durationMinutes,
    required int caloriesBurned,
    required int cardioMinutes,
    required int streak,
  });
  Stream<List<Challenge>> publicChallengesStream();
  Stream<List<Challenge>> myChallengesStream();
  Stream<List<ChallengeParticipant>> challengeLeaderboardStream(
    String challengeId,
  );
}
