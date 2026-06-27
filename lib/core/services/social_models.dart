import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUid: d['fromUid'] as String? ?? '',
      fromName: d['fromName'] as String? ?? AppLocalizations.tl('socialDefaultUser'),
      toUid: d['toUid'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FriendUser {
  final String uid;
  final String name;
  final DateTime addedAt;

  const FriendUser({required this.uid, required this.name, required this.addedAt});

  factory FriendUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FriendUser(
      uid: doc.id,
      name: d['name'] as String? ?? AppLocalizations.tl('socialDefaultUser'),
      addedAt: (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FeedEvent {
  final String id;
  final String type;
  final String fromUid;
  final String fromName;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const FeedEvent({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromName,
    required this.data,
    required this.timestamp,
  });

  factory FeedEvent.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FeedEvent(
      id: doc.id,
      type: d['type'] as String? ?? '',
      fromUid: d['fromUid'] as String? ?? '',
      fromName: d['fromName'] as String? ?? AppLocalizations.tl('socialDefaultUser'),
      data: (d['data'] as Map<String, dynamic>?) ?? {},
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get emoji {
    switch (type) {
      case 'workout_done': return '🏋️';
      case 'pr_set':       return '🏅';
      case 'achievement':  return '🏆';
      case 'challenge_won': return '⚡';
      default:             return '📌';
    }
  }

  String get description {
    switch (type) {
      case 'workout_done': return AppLocalizations.tl('socialDidWorkout');
      case 'pr_set':
        final ex = data['exerciseName'] as String? ?? '';
        return ex.isNotEmpty ? AppLocalizations.tlp('socialDidPr', {'ex': ex}) : AppLocalizations.tl('socialDidPrShort');
      case 'achievement':
        final name = data['achievementName'] as String? ?? '';
        return name.isNotEmpty ? AppLocalizations.tlp('socialGotBadge', {'name': name}) : AppLocalizations.tl('socialGotBadgeShort');
      case 'challenge_won':
        final title = data['challengeTitle'] as String? ?? '';
        return title.isNotEmpty ? AppLocalizations.tlp('socialDidChallenge', {'title': title}) : AppLocalizations.tl('socialDidChallengeShort');
      default: return AppLocalizations.tl('socialDidSomething');
    }
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final String goalType;
  final int targetValue;
  final int durationDays;
  final bool isPublic;
  final bool isPredefined;
  final String createdBy;
  final String creatorName;
  final List<String> participants;
  final DateTime startDate;
  final DateTime endDate;
  final String emoji;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.goalType,
    required this.targetValue,
    required this.durationDays,
    required this.isPublic,
    required this.isPredefined,
    required this.createdBy,
    required this.creatorName,
    required this.participants,
    required this.startDate,
    required this.endDate,
    required this.emoji,
  });

  factory Challenge.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      goalType: d['goalType'] as String? ?? 'workout_count',
      targetValue: (d['targetValue'] as num?)?.toInt() ?? 1,
      durationDays: (d['durationDays'] as num?)?.toInt() ?? 365,
      isPublic: d['isPublic'] as bool? ?? true,
      isPredefined: d['isPredefined'] as bool? ?? false,
      createdBy: d['createdBy'] as String? ?? '',
      creatorName: d['creatorName'] as String? ?? 'FitnesBuster',
      participants: ((d['participants'] as List?) ?? []).cast<String>(),
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (d['endDate'] as Timestamp?)?.toDate() ?? DateTime(2030),
      emoji: d['emoji'] as String? ?? '🎯',
    );
  }

  bool get isActive => endDate.isAfter(DateTime.now());

  String get goalLabel {
    switch (goalType) {
      case 'workout_count':   return AppLocalizations.tl('socialWorkouts');
      case 'calories_burned': return AppLocalizations.tl('socialKcal');
      case 'cardio_minutes':  return AppLocalizations.tl('socialCardioMin');
      case 'workout_streak':  return AppLocalizations.tl('socialDayStreak');
      default:                return '';
    }
  }
}

class ChallengeParticipant {
  final String uid;
  final String name;
  final int currentValue;

  const ChallengeParticipant({
    required this.uid,
    required this.name,
    required this.currentValue,
  });

  factory ChallengeParticipant.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChallengeParticipant(
      uid: doc.id,
      name: d['name'] as String? ?? AppLocalizations.tl('socialDefaultUser'),
      currentValue: (d['currentValue'] as num?)?.toInt() ?? 0,
    );
  }
}
