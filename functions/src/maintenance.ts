import * as admin from "firebase-admin";
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
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - FEED_RETENTION_DAYS * ONE_DAY_MS)
    );
    logInfo("cleanOldFeedEvents started", {cutoff: cutoff.toDate().toISOString()});

    let totalDeleted = 0;
    const usersSnap = await db.collection("users").select().get();
    for (const userDoc of usersSnap.docs) {
      const oldEvents = await db
        .collection(`feed/${userDoc.id}/events`)
        .where("timestamp", "<", cutoff)
        .limit(FEED_CLEANUP_LIMIT)
        .get();
      if (oldEvents.empty) continue;
      const batch = db.batch();
      for (const doc of oldEvents.docs) batch.delete(doc.ref);
      await batch.commit();
      totalDeleted += oldEvents.size;
    }
    logInfo("cleanOldFeedEvents finished", {totalDeleted, usersProcessed: usersSnap.size});
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
    const cutoff = admin.firestore.Timestamp.fromDate(
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
