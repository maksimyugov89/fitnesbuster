import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/core/services/social_models.dart';

void main() {
  // ── FeedEvent ───────────────────────────────────────────────────

  group('FeedEvent', () {
    test('emoji returns correct emoji for workout_done', () {
      final event = FeedEvent(
        id: '1',
        type: 'workout_done',
        fromUid: 'u1',
        fromName: 'A',
        data: {},
        timestamp: DateTime.utc(2026),
      );
      expect(event.emoji, '🏋️');
    });

    test('emoji returns correct emoji for pr_set', () {
      final event = FeedEvent(
        id: '1',
        type: 'pr_set',
        fromUid: 'u1',
        fromName: 'A',
        data: {},
        timestamp: DateTime.utc(2026),
      );
      expect(event.emoji, '🏅');
    });

    test('emoji returns correct emoji for achievement', () {
      final event = FeedEvent(
        id: '1',
        type: 'achievement',
        fromUid: 'u1',
        fromName: 'A',
        data: {},
        timestamp: DateTime.utc(2026),
      );
      expect(event.emoji, '🏆');
    });

    test('emoji returns correct emoji for challenge_won', () {
      final event = FeedEvent(
        id: '1',
        type: 'challenge_won',
        fromUid: 'u1',
        fromName: 'A',
        data: {},
        timestamp: DateTime.utc(2026),
      );
      expect(event.emoji, '⚡');
    });

    test('emoji returns default for unknown type', () {
      final event = FeedEvent(
        id: '1',
        type: 'unknown',
        fromUid: 'u1',
        fromName: 'A',
        data: {},
        timestamp: DateTime.utc(2026),
      );
      expect(event.emoji, '📌');
    });
  });

  // ── Challenge ────────────────────────────────────────────────────

  group('Challenge', () {
    test('isActive returns true when endDate is in the future', () {
      final challenge = Challenge(
        id: '1',
        title: 'Test',
        description: 'Desc',
        goalType: 'workout_count',
        targetValue: 10,
        durationDays: 30,
        isPublic: true,
        isPredefined: false,
        createdBy: 'u1',
        creatorName: 'A',
        participants: [],
        startDate: DateTime.utc(2026),
        endDate: DateTime(2030),
        emoji: '🎯',
      );
      expect(challenge.isActive, isTrue);
    });

    test('isActive returns false when endDate is in the past', () {
      final challenge = Challenge(
        id: '1',
        title: 'Test',
        description: 'Desc',
        goalType: 'workout_count',
        targetValue: 10,
        durationDays: 30,
        isPublic: true,
        isPredefined: false,
        createdBy: 'u1',
        creatorName: 'A',
        participants: [],
        startDate: DateTime(2020),
        endDate: DateTime(2021),
        emoji: '🎯',
      );
      expect(challenge.isActive, isFalse);
    });

    test('goalLabel returns correct label for workout_count', () {
      final challenge = Challenge(
        id: '1',
        title: 'Test',
        description: 'Desc',
        goalType: 'workout_count',
        targetValue: 10,
        durationDays: 30,
        isPublic: true,
        isPredefined: false,
        createdBy: 'u1',
        creatorName: 'A',
        participants: [],
        startDate: DateTime.utc(2026),
        endDate: DateTime(2030),
        emoji: '🎯',
      );
      expect(challenge.goalLabel, isNotEmpty);
    });
  });

  // ── ChallengeParticipant ─────────────────────────────────────────

  group('ChallengeParticipant', () {
    test('constructor creates valid participant', () {
      const p = ChallengeParticipant(uid: 'u1', name: 'User', currentValue: 5);
      expect(p.uid, 'u1');
      expect(p.name, 'User');
      expect(p.currentValue, 5);
    });
  });
}
