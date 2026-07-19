import * as admin from "firebase-admin";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {HttpsError} from "firebase-functions/v2/https";
import {FIRESTORE_DATABASE_ID} from "./firebaseConfig";
import {RETRY_BASE_DELAY_MS, RETRY_MAX_ATTEMPTS} from "./constants";
import {evaluateRateLimit, rateLimitFailureAction} from "./rateLimitLogic";

const db = getFirestore(FIRESTORE_DATABASE_ID);
const messaging = admin.messaging();

// ─── Logging ──────────────────────────────────────────────────────────────────

/** Structured info-level log entry for Cloud Functions monitoring. */
function logInfo(msg: string, data?: Record<string, unknown>): void {
  console.log(JSON.stringify({severity: "INFO", message: msg, ...data}));
}

/** Structured warning-level log entry for Cloud Functions monitoring. */
function logWarn(msg: string, data?: Record<string, unknown>): void {
  console.warn(JSON.stringify({severity: "WARNING", message: msg, ...data}));
}

/** Structured error-level log entry with captured error for Cloud Functions monitoring. */
function logError(msg: string, error: unknown, data?: Record<string, unknown>): void {
  console.error(JSON.stringify({severity: "ERROR", message: msg, error: String(error), ...data}));
}

// ─── Rate Limiter ─────────────────────────────────────────────────────────────

/**
 * Simple per-user, per-action rate limiter using Firestore as backing store.
 *
 * @param uid        The requesting user's UID.
 * @param action     Name of the rate-limited action (e.g. "deepseekProxy").
 * @param maxRequests Maximum allowed requests within the sliding window.
 * @param windowMs   Sliding window duration in milliseconds.
 * @param failClosed When `true`, a genuine infrastructure error (Firestore
 *                   transaction failure that is NOT contention) throws
 *                   `HttpsError("unavailable", …)` instead of silently
 *                   permitting the request.  Use for paid/costly endpoints
 *                   where a blind permit could burn budget.
 * @returns `true` if the request is allowed, `false` if the limit has been exceeded.
 * @throws `HttpsError("unavailable", …)` — only when `failClosed` is true and the
 *         rate-limiter infrastructure itself is unreachable.
 */
async function checkRateLimit(
  uid: string,
  action: string,
  maxRequests: number,
  windowMs: number,
  {failClosed = false}: {failClosed?: boolean} = {}
): Promise<boolean> {
  const ref = db.collection("rate_limits").doc(`${uid}_${action}`);
  try {
    return await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const now = Date.now();
      const decision = evaluateRateLimit(
        snap.exists ? snap.data()! : undefined,
        now,
        maxRequests,
        windowMs
      );
      if (!decision.allowed) {
        logWarn("Rate limit exceeded", {uid, action, maxRequests});
        return false;
      }
      tx.set(ref, decision.nextState!, {merge: snap.exists});
      return true;
    }, {maxAttempts: 15});
  } catch (e) {
    const failureAction = rateLimitFailureAction(e, failClosed);
    if (failureAction === "deny") {
      // ABORTED: Firestore's own concurrency control gave up retrying after
      // exhausting maxAttempts under heavy contention on this exact document
      // (many requests racing for the same rate-limit slot at once). Fail
      // *closed* here — unlike a genuine infra outage, this is precisely
      // the burst scenario the limiter exists to catch. The caller can
      // safely retry a moment later once the contention clears.
      logWarn("Rate limiter contention exhausted — denying", {uid, action});
      return false;
    }
    logError("Rate limiter check failed", e, {uid, action});
    if (failureAction === "throw") {
      throw new HttpsError(
        "unavailable",
        "Rate limiter is temporarily unavailable. Please try again later."
      );
    }
    return true; // fail-open: permit on genuine infrastructure error
  }
}

// ─── Push Notifications ───────────────────────────────────────────────────────

/**
 * Sends an FCM push notification to a single user.
 *
 * If the user's FCM token has become invalid, it is removed from the Firestore
 * document so subsequent calls do not retry a dead token.
 *
 * @param toUid Recipient user UID.
 * @param title Notification title.
 * @param body  Notification body text.
 * @param data  Optional key-value payload delivered to the app.
 */
async function sendPush(
  toUid: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  const snap = await db.doc(`users/${toUid}`).get();
  const token = snap.data()?.fcmToken as string | undefined;
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: {title, body},
      data,
      android: {priority: "high"},
      apns: {payload: {aps: {sound: "default"}}},
    });
  } catch (e) {
    await db.doc(`users/${toUid}`).update({fcmToken: FieldValue.delete()});
  }
}

// ─── In-App Notifications ────────────────────────────────────────────────────

/**
 * Creates an in-app notification document under the recipient's notification
 * sub-collection. Unlike push notifications, these are read by the Flutter
 * client directly from Firestore.
 *
 * @param toUid    Recipient user UID.
 * @param type     Notification type — used by the client for routing / display.
 * @param message  Human-readable notification text.
 * @param fromUid  Sender user UID.
 * @param fromName Sender display name.
 * @param extraData Optional map merged into the document payload.
 */
async function createNotification(
  toUid: string,
  type: string,
  message: string,
  fromUid: string,
  fromName: string,
  extraData: Record<string, unknown> = {}
): Promise<void> {
  await db.collection(`notifications/${toUid}/items`).add({
    type,
    message,
    fromUid,
    fromName,
    data: extraData,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

// ─── Retry ───────────────────────────────────────────────────────────────────

/**
 * Executes an async function with exponential backoff retry.
 *
 * @param fn           The async function to wrap.
 * @param maxAttempts  Maximum number of attempts before throwing (default 3).
 * @returns The resolved value of `fn`.
 * @throws The last error encountered if all attempts fail.
 */
async function withRetry<T>(fn: () => Promise<T>, maxAttempts = RETRY_MAX_ATTEMPTS): Promise<T> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      lastError = e;
      if (attempt < maxAttempts) {
        await new Promise((r) => setTimeout(r, RETRY_BASE_DELAY_MS * Math.pow(2, attempt)));
      }
    }
  }
  throw lastError;
}

export {
  db,
  messaging,
  logInfo,
  logWarn,
  logError,
  checkRateLimit,
  sendPush,
  createNotification,
  withRetry,
};
