import {FieldValue} from "firebase-admin/firestore";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db, logInfo, logError, withRetry, checkRateLimit, enforceAppCheck} from "./shared";
import {FRIEND_LIST_LIMIT, FEED_CHUNK_SIZE} from "./constants";
import {FIRESTORE_DATABASE_ID} from "./firebaseConfig";
import {validatePublishActivityRequest} from "./feedValidation";
import type {PublishActivityData} from "./types";

const PUBLISH_ACTIVITY_RATE_LIMIT = 30;
const PUBLISH_ACTIVITY_WINDOW_MS = 60_000;

/**
 * Validated server-side entry point for client-originated activity events.
 *
 * Firestore rules intentionally deny direct client writes to
 * `activity_events/{uid}/items`; this callable writes through Admin SDK so the
 * fanout trigger can safely distribute only validated events.
 */
export const publishActivity = onCall(
  {region: "europe-west1", enforceAppCheck},
  async (request: {auth?: {uid: string}; data: PublishActivityData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const allowed = await checkRateLimit(uid, "publishActivity", PUBLISH_ACTIVITY_RATE_LIMIT, PUBLISH_ACTIVITY_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    const {type, data} = validatePublishActivityRequest(request.data);
    const ref = await db.collection(`activity_events/${uid}/items`).add({
      type,
      data,
      timestamp: FieldValue.serverTimestamp(),
    });

    logInfo("Activity published", {uid, type, eventId: ref.id});
    return {eventId: ref.id};
  }
);

/**
 * Triggered whenever a new activity event is written to a user's feed.
 *
 * Fans out the event to the personal feeds of all friends of the creating user.
 * Uses best-effort chunking: each chunk of up to {@link FEED_CHUNK_SIZE}
 * documents is written in its own transaction with retry. Chunk failures are
 * logged and skipped to avoid blocking the fanout pipeline.
 */
export const fanoutActivityEvent = onDocumentCreated(
  {
    document: "activity_events/{uid}/items/{eventId}",
    database: FIRESTORE_DATABASE_ID,
    region: "europe-west1",
  },
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data();
    if (!data) return;

    const userSnap = await db.doc(`users/${uid}`).get();
    const fromName = (userSnap.data()?.name as string) ?? "Пользователь";

    const friendsSnap = await db.collection(`friends/${uid}/list`).limit(FRIEND_LIST_LIMIT).get();
    if (friendsSnap.empty) return;

    const feedEntry = {
      type: data.type,
      fromUid: uid,
      fromName,
      data: data.data ?? {},
      timestamp: FieldValue.serverTimestamp(),
    };

    // Split friend list into chunks to stay within Firestore batch write limits
    const chunks: FirebaseFirestore.DocumentReference[][] = [[]];
    for (const friendDoc of friendsSnap.docs) {
      const last = chunks[chunks.length - 1];
      if (last.length >= FEED_CHUNK_SIZE) chunks.push([]);
      chunks[chunks.length - 1].push(
        db.collection(`feed/${friendDoc.id}/events`).doc()
      );
    }

    let chunkIndex = 0;
    for (const chunk of chunks) {
      try {
        await withRetry(async () => {
          const batch = db.batch();
          for (const ref of chunk) batch.set(ref, feedEntry);
          await batch.commit();
        });
      } catch (e) {
        logError("feed fanout chunk failed", e, {uid, chunkIndex, chunkSize: chunk.length});
        // best-effort: continue with remaining chunks
      }
      chunkIndex++;
    }
    logInfo("feed fanout complete", {uid, friendsCount: friendsSnap.size, chunks: chunks.length});
  }
);
