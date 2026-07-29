import * as admin from "firebase-admin";
import {FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db, logInfo, enforceAppCheck} from "./shared";
import {FRIEND_LIST_LIMIT} from "./constants";
import {
  DELETE_ACCOUNT_BATCH_LIMIT,
  challengeProgressPath,
  ownDeleteAccountCollectionPaths,
  reciprocalFriendPath,
} from "./accountCleanupPlan";

/**
 * Permanently deletes the authenticated user's account and all associated
 * data (GDPR / right-to-erasure). Removes:
 * - `users/{uid}` profile document (name, email, profile, aiPlans, measurements)
 * - `friends/{uid}/list/*` and the reciprocal entries in friends' own lists
 * - `friend_requests` where the user is sender or recipient
 * - `activity_events/{uid}/items/*`, `feed/{uid}/events/*`, `notifications/{uid}/items/*`
 * - challenge participation: removed from `challenges.participants` and
 *   the matching `challenge_progress/*​/participants/{uid}` document
 * - the Firebase Auth user record itself
 *
 * Copies of this user's activity already fanned out into friends' feeds are
 * not retroactively purged (cost-prohibitive to scan every friend's feed);
 * they expire automatically within 30 days via `cleanOldFeedEvents`.
 */
export const deleteAccount = onCall(
  {region: "europe-west1", enforceAppCheck},
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;

    let batch = db.batch();
    let opCount = 0;
    const flushIfNeeded = async () => {
      if (opCount >= DELETE_ACCOUNT_BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    };
    const queueDelete = async (ref: FirebaseFirestore.DocumentReference) => {
      batch.delete(ref);
      opCount++;
      await flushIfNeeded();
    };

    // Friends: delete own list + reciprocal entries in friends' lists
    const friendsSnap = await db.collection(`friends/${uid}/list`).limit(FRIEND_LIST_LIMIT).get();
    for (const doc of friendsSnap.docs) {
      await queueDelete(doc.ref);
      await queueDelete(db.doc(reciprocalFriendPath(uid, doc.id)));
    }

    // Friend requests where the user is sender or recipient
    const [asSender, asRecipient] = await Promise.all([
      db.collection("friend_requests").where("fromUid", "==", uid).get(),
      db.collection("friend_requests").where("toUid", "==", uid).get(),
    ]);
    for (const doc of [...asSender.docs, ...asRecipient.docs]) {
      await queueDelete(doc.ref);
    }

    // Own activity events, feed inbox, notifications
    for (const path of ownDeleteAccountCollectionPaths(uid)) {
      const snap = await db.collection(path).get();
      for (const doc of snap.docs) {
        await queueDelete(doc.ref);
      }
    }

    // Challenge participation: leave the challenge + drop progress doc
    const challengesSnap = await db.collection("challenges").where("participants", "array-contains", uid).get();
    for (const chalDoc of challengesSnap.docs) {
      batch.update(chalDoc.ref, {participants: FieldValue.arrayRemove(uid)});
      opCount++;
      await flushIfNeeded();
      await queueDelete(db.doc(challengeProgressPath(chalDoc.id, uid)));
    }

    // Profile document itself
    await queueDelete(db.doc(`users/${uid}`));

    await batch.commit();

    // Auth record deleted last: if anything above throws, the account
    // remains accessible so the user (or a retry) doesn't get locked out
    // with no way to trigger cleanup again.
    await admin.auth().deleteUser(uid);

    logInfo("Account deleted", {uid});
    return {success: true};
  }
);
