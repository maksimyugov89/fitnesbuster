import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, logInfo} from "./shared";
import {ONE_DAY_MS, FEED_RETENTION_DAYS, FEED_CLEANUP_LIMIT} from "./constants";

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
