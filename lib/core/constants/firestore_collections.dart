class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String friendRequests = 'friend_requests';
  static const String challenges = 'challenges';

  static String activityEvents(String uid) => 'activity_events/$uid/items';
  static String friendsList(String uid) => 'friends/$uid/list';
  static String feed(String uid) => 'feed/$uid/events';
  static String challengeProgress(String challengeId) =>
      'challenge_progress/$challengeId/participants';
}
