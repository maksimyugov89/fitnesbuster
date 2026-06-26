import 'package:cloud_firestore/cloud_firestore.dart';

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
      fromName: d['fromName'] as String? ?? 'Пользователь',
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
      name: d['name'] as String? ?? 'Пользователь',
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
      fromName: d['fromName'] as String? ?? 'Пользователь',
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
      case 'workout_done': return 'завершил(а) тренировку';
      case 'pr_set':
        final ex = data['exerciseName'] as String? ?? '';
        return ex.isNotEmpty ? 'установил(а) личный рекорд в «$ex»' : 'установил(а) личный рекорд';
      case 'achievement':
        final name = data['achievementName'] as String? ?? '';
        return name.isNotEmpty ? 'получил(а) значок «$name»' : 'получил(а) новый значок';
      case 'challenge_won':
        final title = data['challengeTitle'] as String? ?? '';
        return title.isNotEmpty ? 'выполнил(а) челлендж «$title»' : 'выполнил(а) челлендж';
      default: return 'что-то сделал(а)';
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
      case 'workout_count':   return 'тренировок';
      case 'calories_burned': return 'ккал';
      case 'cardio_minutes':  return 'мин кардио';
      case 'workout_streak':  return 'дней подряд';
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
      name: d['name'] as String? ?? 'Пользователь',
      currentValue: (d['currentValue'] as num?)?.toInt() ?? 0,
    );
  }
}
