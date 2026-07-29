import {FieldValue} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db, logInfo, createNotification, sendPush, checkRateLimit, enforceAppCheck} from "./shared";
import {
  SEARCH_USERS_LIMIT,
  FRIEND_LIST_LIMIT,
  SEND_FRIEND_REQUEST_RATE_LIMIT,
  SEARCH_USERS_RATE_LIMIT,
  FRIEND_ACTION_RATE_LIMIT,
  RATE_LIMIT_WINDOW_MS,
} from "./constants";
import type {FriendRequestData, AcceptDeclineData, RemoveFriendData, SearchUsersData} from "./types";
import {
  mergeSearchResults,
  normalizeSearchQuery,
  validateFriendRequestId,
  validateFriendUid,
  validateSendFriendRequest,
} from "./friendsValidation";

/**
 * Sends a friend request from the authenticated user to another user.
 *
 * Validates that:
 * - `toUid` is a non-empty string
 * - The users are not already friends
 * - There is no pending request between the same pair
 *
 * On success, creates an in-app notification and pushes an FCM message
 * to the recipient.
 */
export const sendFriendRequest = onCall(
  {region: "europe-west1", enforceAppCheck},
  async (request: {auth?: {uid: string}; data: FriendRequestData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const fromUid = request.auth.uid;
    const {toUid} = request.data;

    const allowed = await checkRateLimit(fromUid, "sendFriendRequest", SEND_FRIEND_REQUEST_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    const normalizedToUid = validateSendFriendRequest(fromUid, toUid);

    const friendDoc = await db.doc(`friends/${fromUid}/list/${normalizedToUid}`).get();
    if (friendDoc.exists) throw new HttpsError("already-exists", "Already friends");

    const existing = await db
      .collection("friend_requests")
      .where("fromUid", "==", fromUid)
      .where("toUid", "==", normalizedToUid)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    if (!existing.empty) throw new HttpsError("already-exists", "Request already sent");

    const fromSnap = await db.doc(`users/${fromUid}`).get();
    const fromName = (fromSnap.data()?.name as string) ?? "Пользователь";

    const ref = await db.collection("friend_requests").add({
      fromUid,
      toUid: normalizedToUid,
      fromName,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    await createNotification(normalizedToUid, "friend_request", `${fromName} хочет добавить вас в друзья`, fromUid, fromName, {requestId: ref.id});
    await sendPush(normalizedToUid, "Запрос в друзья", `${fromName} хочет добавить вас в друзья`, {type: "friend_request", requestId: ref.id});

    return {requestId: ref.id};
  }
);

/**
 * Accepts a pending friend request.
 *
 * Runs inside a Firestore transaction to ensure atomicity: atomically
 * marks the request as accepted and creates bidirectional friend entries
 * for both users. Notifies the original sender via in-app and push.
 */
export const acceptFriendRequest = onCall(
  {region: "europe-west1", enforceAppCheck},
  async (request: {auth?: {uid: string}; data: AcceptDeclineData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {requestId} = request.data;

    const allowed = await checkRateLimit(uid, "acceptFriendRequest", FRIEND_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    const normalizedRequestId = validateFriendRequestId(requestId);

    const reqRef = db.doc(`friend_requests/${normalizedRequestId}`);
    let fromUidFinal = "";
    let fromNameFinal = "";
    let toNameFinal = "";

    await db.runTransaction(async (tx) => {
      const reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw new HttpsError("not-found", "Request not found");

      const req = reqSnap.data()!;
      if (req.toUid !== uid) throw new HttpsError("permission-denied", "Not your request");
      if (req.status !== "pending") throw new HttpsError("failed-precondition", "Request already handled");

      const fromUid: string = req.fromUid;
      fromUidFinal = fromUid;

      const [fromSnap, toSnap] = await Promise.all([
        tx.get(db.doc(`users/${fromUid}`)),
        tx.get(db.doc(`users/${uid}`)),
      ]);
      fromNameFinal = (fromSnap.data()?.name as string) ?? "Пользователь";
      toNameFinal = (toSnap.data()?.name as string) ?? "Пользователь";
      const now = FieldValue.serverTimestamp();

      tx.update(reqRef, {status: "accepted"});
      tx.set(db.doc(`friends/${fromUid}/list/${uid}`), {addedAt: now, name: toNameFinal});
      tx.set(db.doc(`friends/${uid}/list/${fromUid}`), {addedAt: now, name: fromNameFinal});
    });

    logInfo("Friend request accepted", {uid, requestId: normalizedRequestId});

    await createNotification(fromUidFinal, "friend_accepted", `${toNameFinal} принял(а) ваш запрос в друзья`, uid, toNameFinal);
    await sendPush(fromUidFinal, "Запрос принят", `${toNameFinal} теперь ваш друг!`, {type: "friend_accepted"});

    return {success: true};
  }
);

/**
 * Declines a pending friend request without notifying the sender.
 */
export const declineFriendRequest = onCall(
  {region: "europe-west1", enforceAppCheck},
  async (request: {auth?: {uid: string}; data: AcceptDeclineData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {requestId} = request.data;

    const allowed = await checkRateLimit(uid, "declineFriendRequest", FRIEND_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    const normalizedRequestId = validateFriendRequestId(requestId);

    const reqRef = db.doc(`friend_requests/${normalizedRequestId}`);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) throw new HttpsError("not-found", "Request not found");
    if (reqSnap.data()!.toUid !== uid) throw new HttpsError("permission-denied", "Not your request");

    await reqRef.update({status: "declined"});
    return {success: true};
  }
);

/**
 * Removes a friend relationship bidirectionally using a batch delete.
 */
export const removeFriend = onCall(
  {region: "europe-west1", enforceAppCheck},
  async (request: {auth?: {uid: string}; data: RemoveFriendData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {friendUid} = request.data;

    const allowed = await checkRateLimit(uid, "removeFriend", FRIEND_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    const normalizedFriendUid = validateFriendUid(friendUid);

    const batch = db.batch();
    batch.delete(db.doc(`friends/${uid}/list/${normalizedFriendUid}`));
    batch.delete(db.doc(`friends/${normalizedFriendUid}/list/${uid}`));
    await batch.commit();

    return {success: true};
  }
);

/**
 * Searches users by name or username prefix.
 *
 * Queries both `nameLower` and `usernameLower` fields using Firestore
 * range queries. Results are de-duplicated, excluded from self, and
 * annotated with friendship status.
 *
 * Returns up to {@link SEARCH_USERS_LIMIT} results per query direction.
 */
export const searchUsers = onCall(
  {region: "europe-west1", enforceAppCheck},
  async (request: {auth?: {uid: string}; data: SearchUsersData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const {query} = request.data;
    const q = normalizeSearchQuery(query);

    const allowed = await checkRateLimit(request.auth.uid, "searchUsers", SEARCH_USERS_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    const [nameSnap, usernameSnap, callerFriendsSnap] = await Promise.all([
      db.collection("users")
        .where("nameLower", ">=", q)
        .where("nameLower", "<=", q + "")
        .limit(SEARCH_USERS_LIMIT)
        .get(),
      db.collection("users")
        .where("usernameLower", ">=", q)
        .where("usernameLower", "<=", q + "")
        .limit(SEARCH_USERS_LIMIT)
        .get(),
      db.collection(`friends/${request.auth.uid}/list`).limit(FRIEND_LIST_LIMIT).get(),
    ]);

    const friendUids = new Set(callerFriendsSnap.docs.map((d) => d.id));
    return mergeSearchResults(
      request.auth.uid,
      nameSnap.docs.map((d) => ({id: d.id, data: d.data()})),
      usernameSnap.docs.map((d) => ({id: d.id, data: d.data()})),
      friendUids
    );
  }
);
