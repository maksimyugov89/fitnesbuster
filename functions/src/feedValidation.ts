import {HttpsError} from "firebase-functions/v2/https";

export const PUBLISH_ACTIVITY_TYPES = new Set([
  "workout_done",
  "pr_set",
  "achievement",
  "challenge_won",
]);

const PUBLISH_ACTIVITY_MAX_DATA_BYTES = 10_000;

export interface ValidatedPublishActivity {
  type: string;
  data: Record<string, unknown>;
}

export function validatePublishActivityRequest(
  rawData: unknown
): ValidatedPublishActivity {
  if (typeof rawData !== "object" || rawData === null || Array.isArray(rawData)) {
    throw new HttpsError("invalid-argument", "request data must be an object");
  }
  const data = rawData as {type?: unknown; data?: unknown};
  return validatePublishActivityPayload(data.type, data.data);
}

export function validatePublishActivityPayload(
  type: unknown,
  rawData: unknown
): ValidatedPublishActivity {
  if (typeof type !== "string" || !PUBLISH_ACTIVITY_TYPES.has(type)) {
    throw new HttpsError("invalid-argument", "Unsupported activity type");
  }
  if (rawData === undefined || rawData === null) {
    return {type, data: {}};
  }
  if (typeof rawData !== "object" || Array.isArray(rawData)) {
    throw new HttpsError("invalid-argument", "data must be an object");
  }
  const data = rawData as Record<string, unknown>;
  const size = Buffer.byteLength(JSON.stringify(data), "utf8");
  if (size > PUBLISH_ACTIVITY_MAX_DATA_BYTES) {
    throw new HttpsError("invalid-argument", "data payload is too large");
  }
  return {type, data};
}
