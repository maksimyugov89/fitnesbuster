import {Timestamp} from "firebase-admin/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, logInfo} from "./shared";
import {
  ONE_DAY_MS,
  FEED_RETENTION_DAYS,
  FEED_CLEANUP_LIMIT,
  CHALLENGE_DELETE_GRACE_DAYS,
  CHALLENGE_CLEANUP_LIMIT,
} from "./constants";

/**
 * Scheduled cleanup job that runs daily at 03:00 UTC.
 *
 * Removes feed events older than {@link FEED_RETENTION_DAYS} days across all
 * users. Each user is processed independently with a batch delete of up to
 * {@link FEED_CLEANUP_LIMIT} documents per run.
 */
export const cleanOldFeedEvents = onSchedule(
  {schedule: "0 3 * * *", region: "europe-west1"},
  async () => {
    const cutoff = Timestamp.fromDate(
      new Date(Date.now() - FEED_RETENTION_DAYS * ONE_DAY_MS)
    );
    logInfo("cleanOldFeedEvents started", {cutoff: cutoff.toDate().toISOString()});

    // Collection-group sweep: one query across all feed/{uid}/events instead
    // of an O(N users) read loop. Requires the COLLECTION_GROUP single-field
    // index on "events"(timestamp), which cannot be expressed in
    // firestore.indexes.json (that file only accepts composite indexes — the
    // API answers "this index is not necessary, configure using single field
    // index controls"). It lives in the Firestore single-field index controls
    // for the field, was created 2026-09-10 via the Admin API, and is what the
    // FAILED_PRECONDITION error link in the console points at. Without it the
    // nightly job fails every time.
    let totalDeleted = 0;
    for (let i = 0; i < 10; i++) {
      const oldEvents = await db
        .collectionGroup("events")
        .where("timestamp", "<", cutoff)
        .limit(FEED_CLEANUP_LIMIT)
        .get();
      if (oldEvents.empty) break;
      const batch = db.batch();
      for (const doc of oldEvents.docs) batch.delete(doc.ref);
      await batch.commit();
      totalDeleted += oldEvents.size;
      if (oldEvents.size < FEED_CLEANUP_LIMIT) break;
    }
    logInfo("cleanOldFeedEvents finished", {totalDeleted});
  }
);

/**
 * Scheduled cleanup job that runs daily at 04:00 UTC.
 *
 * Deletes challenges (and their participant progress) that ended more than
 * {@link CHALLENGE_DELETE_GRACE_DAYS} days ago and were never removed by
 * their creator via {@link deleteChallenge}. Predefined system challenges
 * are skipped — their endDate is set far in the future so they never match
 * the cutoff, but the isPredefined check is kept as a defensive guard.
 */
export const cleanExpiredChallenges = onSchedule(
  {schedule: "0 4 * * *", region: "europe-west1"},
  async () => {
    const cutoff = Timestamp.fromDate(
      new Date(Date.now() - CHALLENGE_DELETE_GRACE_DAYS * ONE_DAY_MS)
    );
    logInfo("cleanExpiredChallenges started", {cutoff: cutoff.toDate().toISOString()});

    const expiredSnap = await db
      .collection("challenges")
      .where("endDate", "<", cutoff)
      .limit(CHALLENGE_CLEANUP_LIMIT)
      .get();

    let deleted = 0;
    for (const chalDoc of expiredSnap.docs) {
      const chal = chalDoc.data();
      if (chal.isPredefined === true) continue;

      const progressSnap = await db.collection(`challenge_progress/${chalDoc.id}/participants`).get();
      const batch = db.batch();
      for (const doc of progressSnap.docs) batch.delete(doc.ref);
      batch.delete(chalDoc.ref);
      await batch.commit();
      deleted++;
    }

    logInfo("cleanExpiredChallenges finished", {deleted, scanned: expiredSnap.size});
  }
);
