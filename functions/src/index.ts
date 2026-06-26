import * as admin from "firebase-admin";
import * as https from "https";
import {defineSecret} from "firebase-functions/params";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const deepseekApiKey = defineSecret("DEEPSEEK_API_KEY");
const exerciseDbApiKey = defineSecret("EXERCISE_DB_API_KEY");

// ─── Types ────────────────────────────────────────────────────────────────────

interface FriendRequestData {
  toUid: string;
}
interface AcceptDeclineData {
  requestId: string;
}
interface RemoveFriendData {
  friendUid: string;
}
interface SearchUsersData {
  query: string;
}
interface CreateChallengeData {
  title: string;
  description: string;
  goalType: "workouts" | "steps" | "streak" | "calories";
  targetValue: number;
  durationDays: number;
  isPublic: boolean;
}
interface JoinChallengeData {
  challengeId: string;
}
interface UpdateChallengeProgressData {
  challengeId: string;
  value: number;
}
interface RecordWorkoutData {
  durationMinutes: number;
  caloriesBurned: number;
  cardioMinutes: number;
  streak: number;
}

// ─── Helper: send FCM to a single user ───────────────────────────────────────

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
    // Token stale — remove it
    await db.doc(`users/${toUid}`).update({fcmToken: admin.firestore.FieldValue.delete()});
  }
}

// ─── Helper: create in-app notification ──────────────────────────────────────

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
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// FRIENDS
// ═══════════════════════════════════════════════════════════════════════════════

// ── sendFriendRequest ─────────────────────────────────────────────────────────
export const sendFriendRequest = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: FriendRequestData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const fromUid = request.auth.uid;
    const {toUid} = request.data;

    if (fromUid === toUid) throw new HttpsError("invalid-argument", "Cannot add yourself");

    // Check not already friends
    const friendDoc = await db.doc(`friends/${fromUid}/list/${toUid}`).get();
    if (friendDoc.exists) throw new HttpsError("already-exists", "Already friends");

    // Check no pending request
    const existing = await db
      .collection("friend_requests")
      .where("fromUid", "==", fromUid)
      .where("toUid", "==", toUid)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    if (!existing.empty) throw new HttpsError("already-exists", "Request already sent");

    const fromSnap = await db.doc(`users/${fromUid}`).get();
    const fromName = (fromSnap.data()?.name as string) ?? "Пользователь";

    const ref = await db.collection("friend_requests").add({
      fromUid,
      toUid,
      fromName,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await createNotification(toUid, "friend_request", `${fromName} хочет добавить вас в друзья`, fromUid, fromName, {requestId: ref.id});
    await sendPush(toUid, "Запрос в друзья", `${fromName} хочет добавить вас в друзья`, {type: "friend_request", requestId: ref.id});

    return {requestId: ref.id};
  }
);

// ── acceptFriendRequest ───────────────────────────────────────────────────────
export const acceptFriendRequest = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: AcceptDeclineData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {requestId} = request.data;

    const reqRef = db.doc(`friend_requests/${requestId}`);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) throw new HttpsError("not-found", "Request not found");

    const req = reqSnap.data()!;
    if (req.toUid !== uid) throw new HttpsError("permission-denied", "Not your request");
    if (req.status !== "pending") throw new HttpsError("failed-precondition", "Request already handled");

    const fromUid: string = req.fromUid;

    // Load both user names
    const [fromSnap, toSnap] = await Promise.all([
      db.doc(`users/${fromUid}`).get(),
      db.doc(`users/${uid}`).get(),
    ]);
    const fromName = (fromSnap.data()?.name as string) ?? "Пользователь";
    const toName = (toSnap.data()?.name as string) ?? "Пользователь";
    const now = admin.firestore.FieldValue.serverTimestamp();

    const batch = db.batch();
    // Update request status
    batch.update(reqRef, {status: "accepted"});
    // Add to both friends lists (bidirectional)
    batch.set(db.doc(`friends/${fromUid}/list/${uid}`), {addedAt: now, name: toName});
    batch.set(db.doc(`friends/${uid}/list/${fromUid}`), {addedAt: now, name: fromName});
    await batch.commit();

    await createNotification(fromUid, "friend_accepted", `${toName} принял(а) ваш запрос в друзья`, uid, toName);
    await sendPush(fromUid, "Запрос принят", `${toName} теперь ваш друг!`, {type: "friend_accepted"});

    return {success: true};
  }
);

// ── declineFriendRequest ──────────────────────────────────────────────────────
export const declineFriendRequest = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: AcceptDeclineData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {requestId} = request.data;

    const reqRef = db.doc(`friend_requests/${requestId}`);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) throw new HttpsError("not-found", "Request not found");
    if (reqSnap.data()!.toUid !== uid) throw new HttpsError("permission-denied", "Not your request");

    await reqRef.update({status: "declined"});
    return {success: true};
  }
);

// ── removeFriend ──────────────────────────────────────────────────────────────
export const removeFriend = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: RemoveFriendData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {friendUid} = request.data;

    const batch = db.batch();
    batch.delete(db.doc(`friends/${uid}/list/${friendUid}`));
    batch.delete(db.doc(`friends/${friendUid}/list/${uid}`));
    await batch.commit();

    return {success: true};
  }
);

// ── searchUsers ───────────────────────────────────────────────────────────────
export const searchUsers = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: SearchUsersData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const {query} = request.data;
    if (!query || query.length < 2) throw new HttpsError("invalid-argument", "Query too short");

    const q = query.toLowerCase().trim();

    // Search by name prefix and username prefix in parallel
    const [nameSnap, usernameSnap, callerFriendsSnap] = await Promise.all([
      db.collection("users")
        .where("nameLower", ">=", q)
        .where("nameLower", "<=", q + "")
        .limit(20)
        .get(),
      db.collection("users")
        .where("usernameLower", ">=", q)
        .where("usernameLower", "<=", q + "")
        .limit(20)
        .get(),
      db.collection(`friends/${request.auth.uid}/list`).get(),
    ]);

    const friendUids = new Set(callerFriendsSnap.docs.map((d) => d.id));

    // Merge and deduplicate results
    const seen = new Set<string>();
    const merged = [...nameSnap.docs, ...usernameSnap.docs].filter((d) => {
      if (d.id === request.auth!.uid || seen.has(d.id)) return false;
      seen.add(d.id);
      return true;
    });

    return merged.map((d) => ({
      uid: d.id,
      name: d.data().name ?? "",
      username: d.data().username ?? "",
      isFriend: friendUids.has(d.id),
    }));
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// FEED FANOUT
// ═══════════════════════════════════════════════════════════════════════════════

// Triggered when the app writes to /activity_events/{uid}/items/{eventId}
// Fans out to all friends' /feed/{friendUid}/events/
export const fanoutActivityEvent = onDocumentCreated(
  {document: "activity_events/{uid}/items/{eventId}", region: "europe-west1"},
  async (event) => {
    const uid = event.params.uid;
    const data = event.data?.data();
    if (!data) return;

    const userSnap = await db.doc(`users/${uid}`).get();
    const fromName = (userSnap.data()?.name as string) ?? "Пользователь";

    // Get all friends
    const friendsSnap = await db.collection(`friends/${uid}/list`).get();
    if (friendsSnap.empty) return;

    const feedEntry = {
      type: data.type,
      fromUid: uid,
      fromName,
      data: data.data ?? {},
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Fan out to each friend's feed (batched writes, max 500 per batch)
    const chunks: FirebaseFirestore.DocumentReference[][] = [[]];
    for (const friendDoc of friendsSnap.docs) {
      const last = chunks[chunks.length - 1];
      if (last.length >= 499) chunks.push([]);
      chunks[chunks.length - 1].push(
        db.collection(`feed/${friendDoc.id}/events`).doc()
      );
    }
    for (const chunk of chunks) {
      const batch = db.batch();
      for (const ref of chunk) batch.set(ref, feedEntry);
      await batch.commit();
    }
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// CHALLENGES
// ═══════════════════════════════════════════════════════════════════════════════

// ── createChallenge ───────────────────────────────────────────────────────────
export const createChallenge = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: CreateChallengeData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {title, description, goalType, targetValue, durationDays, isPublic} = request.data;

    if (!title?.trim()) throw new HttpsError("invalid-argument", "Title required");
    if (targetValue <= 0) throw new HttpsError("invalid-argument", "Target must be > 0");
    if (durationDays < 1 || durationDays > 90) throw new HttpsError("invalid-argument", "Duration 1–90 days");

    const now = admin.firestore.Timestamp.now();
    const endDate = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + durationDays * 86_400_000)
    );

    const userSnap = await db.doc(`users/${uid}`).get();
    const creatorName = (userSnap.data()?.name as string) ?? "Пользователь";

    const ref = await db.collection("challenges").add({
      title: title.trim(),
      description: description?.trim() ?? "",
      goalType,
      targetValue,
      durationDays,
      isPublic,
      createdBy: uid,
      creatorName,
      participants: [uid],
      startDate: now,
      endDate,
      createdAt: now,
    });

    // Creator starts with 0 progress
    await db.doc(`challenge_progress/${ref.id}/participants/${uid}`).set({
      uid,
      name: creatorName,
      currentValue: 0,
      lastUpdated: now,
    });

    return {challengeId: ref.id};
  }
);

// ── joinChallenge ─────────────────────────────────────────────────────────────
export const joinChallenge = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: JoinChallengeData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {challengeId} = request.data;

    const chalRef = db.doc(`challenges/${challengeId}`);
    const chalSnap = await chalRef.get();
    if (!chalSnap.exists) throw new HttpsError("not-found", "Challenge not found");

    const chal = chalSnap.data()!;
    const now = admin.firestore.Timestamp.now();
    if (chal.endDate.toMillis() < now.toMillis()) {
      throw new HttpsError("failed-precondition", "Challenge already ended");
    }
    if ((chal.participants as string[]).includes(uid)) {
      throw new HttpsError("already-exists", "Already joined");
    }

    const userSnap = await db.doc(`users/${uid}`).get();
    const name = (userSnap.data()?.name as string) ?? "Пользователь";

    const batch = db.batch();
    batch.update(chalRef, {
      participants: admin.firestore.FieldValue.arrayUnion(uid),
    });
    batch.set(db.doc(`challenge_progress/${challengeId}/participants/${uid}`), {
      uid,
      name,
      currentValue: 0,
      lastUpdated: now,
    });
    await batch.commit();

    return {success: true};
  }
);

// ── updateChallengeProgress ────────────────────────────────────────────────────
export const updateChallengeProgress = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: UpdateChallengeProgressData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {challengeId, value} = request.data;

    if (typeof value !== "number" || value < 0 || value > 1_000_000 || !Number.isFinite(value)) {
      throw new HttpsError("invalid-argument", "value must be a finite number between 0 and 1000000");
    }
    if (typeof challengeId !== "string" || challengeId.trim().length === 0) {
      throw new HttpsError("invalid-argument", "challengeId must be a non-empty string");
    }

    const chalSnap = await db.doc(`challenges/${challengeId}`).get();
    if (!chalSnap.exists) throw new HttpsError("not-found", "Challenge not found");

    const chal = chalSnap.data()!;
    if (!(chal.participants as string[]).includes(uid)) {
      throw new HttpsError("permission-denied", "Not a participant");
    }

    const progressRef = db.doc(`challenge_progress/${challengeId}/participants/${uid}`);
    const prevSnap = await progressRef.get();
    const prev = (prevSnap.data()?.currentValue as number) ?? 0;
    const newValue = Math.max(prev, value); // never decrease

    await progressRef.update({
      currentValue: newValue,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Check if challenge completed
    if (newValue >= (chal.targetValue as number) && prev < (chal.targetValue as number)) {
      const userSnap = await db.doc(`users/${uid}`).get();
      const name = (userSnap.data()?.name as string) ?? "Пользователь";

      // Notify creator
      if (chal.createdBy !== uid) {
        await sendPush(
          chal.createdBy as string,
          "Челлендж выполнен!",
          `${name} достиг(ла) цели в челлендже «${chal.title}»`,
          {type: "challenge_completed", challengeId}
        );
      }

      // Write to own activity so friends see it in feed
      await db.collection(`activity_events/${uid}/items`).add({
        type: "challenge_won",
        data: {challengeTitle: chal.title, challengeId},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {newValue};
  }
);

// ── recordWorkout ─────────────────────────────────────────────────────────────
export const recordWorkout = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: RecordWorkoutData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {caloriesBurned, cardioMinutes, streak} = request.data;

    const now = admin.firestore.Timestamp.now();
    const [challengesSnap, userSnap] = await Promise.all([
      db.collection("challenges")
        .where("participants", "array-contains", uid)
        .where("endDate", ">=", now)
        .get(),
      db.doc(`users/${uid}`).get(),
    ]);

    if (challengesSnap.empty) return {updated: 0, completed: []};

    const userName = (userSnap.data()?.name as string) ?? "Пользователь";

    const progressRefs = challengesSnap.docs.map((d) =>
      db.doc(`challenge_progress/${d.id}/participants/${uid}`)
    );
    const progressSnaps = await Promise.all(progressRefs.map((r) => r.get()));

    const batch = db.batch();
    const completedChallenges: string[] = [];

    for (let i = 0; i < challengesSnap.docs.length; i++) {
      const chalDoc = challengesSnap.docs[i];
      const chal = chalDoc.data();
      const prev = (progressSnaps[i].data()?.currentValue as number) ?? 0;

      let newValue: number;
      switch (chal.goalType) {
        case "workout_count":
          newValue = prev + 1;
          break;
        case "calories_burned":
          newValue = prev + Math.max(0, caloriesBurned);
          break;
        case "cardio_minutes":
          newValue = prev + Math.max(0, cardioMinutes);
          break;
        case "workout_streak":
          newValue = Math.max(prev, streak);
          break;
        default:
          newValue = prev + 1;
      }

      batch.set(progressRefs[i], {
        uid,
        name: userName,
        currentValue: newValue,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      if (newValue >= (chal.targetValue as number) && prev < (chal.targetValue as number)) {
        completedChallenges.push(chal.title as string);
        await db.collection(`activity_events/${uid}/items`).add({
          type: "challenge_won",
          data: {challengeTitle: chal.title, challengeId: chalDoc.id},
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        if ((chal.createdBy as string) !== "system" && (chal.createdBy as string) !== uid) {
          await sendPush(
            chal.createdBy as string,
            "Челлендж выполнен!",
            `${userName} достиг цели в «${chal.title}»`,
            {type: "challenge_completed", challengeId: chalDoc.id}
          );
        }
      }
    }

    await batch.commit();
    return {updated: challengesSnap.size, completed: completedChallenges};
  }
);

// ── seedChallenges ────────────────────────────────────────────────────────────
export const seedChallenges = onCall(
  {region: "europe-west1"},
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const existing = await db.collection("challenges")
      .where("isPredefined", "==", true)
      .limit(1)
      .get();
    if (!existing.empty) return {skipped: true, reason: "Already seeded"};

    const farFuture = admin.firestore.Timestamp.fromDate(new Date("2030-01-01"));
    const now = admin.firestore.Timestamp.now();

    const predefined = [
      {
        title: "Первые шаги",
        description: "Выполни 3 тренировки и начни свой путь к здоровью",
        goalType: "workout_count",
        targetValue: 3,
        emoji: "👟",
      },
      {
        title: "Неделя силы",
        description: "Заверши 7 тренировок — докажи свою настойчивость",
        goalType: "workout_count",
        targetValue: 7,
        emoji: "💪",
      },
      {
        title: "Кардио-марафон",
        description: "Набери 120 минут кардио-тренировок суммарно",
        goalType: "cardio_minutes",
        targetValue: 120,
        emoji: "🏃",
      },
      {
        title: "Жиросжигатель",
        description: "Сожги 2000 ккал суммарно в тренировках",
        goalType: "calories_burned",
        targetValue: 2000,
        emoji: "🔥",
      },
      {
        title: "Серия 14 дней",
        description: "Тренируйся 14 дней подряд без пропусков",
        goalType: "workout_streak",
        targetValue: 14,
        emoji: "⚡",
      },
    ];

    const batch = db.batch();
    for (const c of predefined) {
      const ref = db.collection("challenges").doc();
      batch.set(ref, {
        ...c,
        isPublic: true,
        isPredefined: true,
        createdBy: "system",
        creatorName: "FitnesBuster",
        participants: [],
        durationDays: 365,
        startDate: now,
        endDate: farFuture,
        createdAt: now,
      });
    }
    await batch.commit();
    return {seeded: predefined.length};
  }
);
// ═══════════════════════════════════════════════════════════════════════════════
// MAINTENANCE
// ═══════════════════════════════════════════════════════════════════════════════

// Runs every day at 03:00 UTC — deletes feed events older than 30 days
export const cleanOldFeedEvents = onSchedule(
  {schedule: "0 3 * * *", region: "europe-west1"},
  async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 30 * 86_400_000)
    );

  // Get all users
      const usersSnap = await db.collection("users").select().get();
      for (const userDoc of usersSnap.docs) {
        const oldEvents = await db
          .collection(`feed/${userDoc.id}/events`)
          .where("timestamp", "<", cutoff)
          .limit(400)
          .get();
        if (oldEvents.empty) continue;
        const batch = db.batch();
        for (const doc of oldEvents.docs) batch.delete(doc.ref);
        await batch.commit();
    }
  }
);

// ── exerciseDbProxy ───────────────────────────────────────────────────────────
// Proxies a name-search request to ExerciseDB (RapidAPI) and returns the GIF URL.
// The API key lives in Firebase Secret Manager — never shipped in the APK.
export const exerciseDbProxy = onCall(
  {region: "europe-west1", secrets: [exerciseDbApiKey]},
  async (request: {auth?: {uid: string}; data: {exerciseName: string}}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const {exerciseName} = request.data;
    if (!exerciseName?.trim()) throw new HttpsError("invalid-argument", "exerciseName required");

    const encoded = encodeURIComponent(exerciseName.trim().toLowerCase());

    return new Promise<{gifUrl: string | null}>((resolve, reject) => {
      const req = https.request(
        {
          hostname: "exercisedb.p.rapidapi.com",
          path: `/exercises/name/${encoded}?limit=1&offset=0`,
          method: "GET",
          headers: {
            "X-RapidAPI-Key": exerciseDbApiKey.value(),
            "X-RapidAPI-Host": "exercisedb.p.rapidapi.com",
          },
        },
        (res) => {
          let data = "";
          res.on("data", (chunk) => { data += chunk; });
          res.on("end", () => {
            try {
              if (res.statusCode !== 200) {
                reject(new HttpsError("internal", `ExerciseDB error ${res.statusCode}: ${data}`));
                return;
              }
              const json = JSON.parse(data);
              const gifUrl = Array.isArray(json) && json.length > 0
                ? (json[0]?.gifUrl as string | undefined) ?? null
                : null;
              resolve({gifUrl});
            } catch (e) {
              reject(new HttpsError("internal", `Parse error: ${e}`));
            }
          });
        }
      );
      req.on("error", (e) => reject(new HttpsError("internal", `Network error: ${e.message}`)));
      req.end();
    });
  }
);

// ── deepseekProxy ──────────────────────────────────────────────────────────────
export const deepseekProxy = onCall(
  {region: "europe-west1", secrets: [deepseekApiKey]},
  async (request: {auth?: {uid: string}; data: {
    messages: Array<{role: string; content: string}>;
    maxTokens?: number;
    temperature?: number;
  }}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const {messages, maxTokens = 4096, temperature = 0.7} = request.data;

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      throw new HttpsError("invalid-argument", "messages must be a non-empty array");
    }

    const body = JSON.stringify({
      model: "deepseek-chat",
      messages,
      max_tokens: maxTokens,
      temperature,
    });

    return new Promise<{content: string}>((resolve, reject) => {
      const req = https.request(
        {
          hostname: "api.deepseek.com",
          path: "/chat/completions",
          method: "POST",
          headers: {
            "Authorization": `Bearer ${deepseekApiKey.value()}`,
            "Content-Type": "application/json",
            "Content-Length": Buffer.byteLength(body),
          },
        },
        (res) => {
          let data = "";
          res.on("data", (chunk) => { data += chunk; });
          res.on("end", () => {
            try {
              const json = JSON.parse(data);
              if (res.statusCode !== 200) {
                reject(new HttpsError("internal", `DeepSeek error ${res.statusCode}: ${data}`));
                return;
              }
              const content = json?.choices?.[0]?.message?.content as string | undefined;
              if (!content) {
                reject(new HttpsError("internal", "Empty response from DeepSeek"));
                return;
              }
              resolve({content});
            } catch (e) {
              reject(new HttpsError("internal", `Parse error: ${e}`));
            }
          });
        }
      );
      req.on("error", (e) => reject(new HttpsError("internal", `Network error: ${e.message}`)));
      req.write(body);
      req.end();
    });
  }
);
