import {HttpsError} from "firebase-functions/v2/https";

export interface SearchUserDoc {
  id: string;
  data: Record<string, unknown>;
}

export interface SearchUserResult {
  uid: string;
  name: string;
  username: string;
  isFriend: boolean;
}

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} must be a non-empty string`);
  }
  return value.trim();
}

export function validateSendFriendRequest(fromUid: string, toUid: unknown): string {
  const normalizedToUid = requireNonEmptyString(toUid, "toUid");
  if (fromUid === normalizedToUid) {
    throw new HttpsError("invalid-argument", "Cannot add yourself");
  }
  return normalizedToUid;
}

export function validateFriendRequestId(requestId: unknown): string {
  return requireNonEmptyString(requestId, "requestId");
}

export function validateFriendUid(friendUid: unknown): string {
  return requireNonEmptyString(friendUid, "friendUid");
}

export function normalizeSearchQuery(query: unknown): string {
  if (typeof query !== "string" || query.trim().length < 2) {
    throw new HttpsError("invalid-argument", "Query too short (min 2 chars)");
  }
  return query.toLowerCase().trim();
}

export function mergeSearchResults(
  callerUid: string,
  nameDocs: SearchUserDoc[],
  usernameDocs: SearchUserDoc[],
  friendUids: Set<string>
): SearchUserResult[] {
  const seen = new Set<string>();
  return [...nameDocs, ...usernameDocs]
    .filter((doc) => {
      if (doc.id === callerUid || seen.has(doc.id)) return false;
      seen.add(doc.id);
      return true;
    })
    .map((doc) => ({
      uid: doc.id,
      name: String(doc.data.name ?? ""),
      username: String(doc.data.username ?? ""),
      isFriend: friendUids.has(doc.id),
    }));
}
