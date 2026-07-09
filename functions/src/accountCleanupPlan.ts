export const DELETE_ACCOUNT_BATCH_LIMIT = 450;

export function ownDeleteAccountCollectionPaths(uid: string): string[] {
  return [
    `activity_events/${uid}/items`,
    `feed/${uid}/events`,
    `notifications/${uid}/items`,
  ];
}

export function reciprocalFriendPath(uid: string, friendUid: string): string {
  return `friends/${friendUid}/list/${uid}`;
}

export function challengeProgressPath(challengeId: string, uid: string): string {
  return `challenge_progress/${challengeId}/participants/${uid}`;
}
