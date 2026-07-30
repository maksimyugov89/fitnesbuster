/** FCM error codes that mean the token is permanently dead and must be removed. */
const DEAD_TOKEN_CODES = new Set<string>([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

/** Returns true only when the FCM error proves the token is permanently invalid. */
export function shouldDeleteFcmToken(errorCode: string | undefined): boolean {
  return errorCode !== undefined && DEAD_TOKEN_CODES.has(errorCode);
}
