"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupDuplicateRequests = exports.fixNameLower = exports.deepseekProxy = exports.exerciseDbProxy = exports.cleanOldFeedEvents = exports.seedChallenges = exports.recordWorkout = exports.updateChallengeProgress = exports.joinChallenge = exports.createChallenge = exports.fanoutActivityEvent = exports.searchUsers = exports.removeFriend = exports.declineFriendRequest = exports.acceptFriendRequest = exports.sendFriendRequest = void 0;
const admin = require("firebase-admin");
const https = require("https");
const params_1 = require("firebase-functions/params");
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const deepseekApiKey = (0, params_1.defineSecret)("DEEPSEEK_API_KEY");
const exerciseDbApiKey = (0, params_1.defineSecret)("EXERCISE_DB_API_KEY");
// ─── Helper: send FCM to a single user ───────────────────────────────────────
async function sendPush(toUid, title, body, data = {}) {
    var _a;
    const snap = await db.doc(`users/${toUid}`).get();
    const token = (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
    if (!token)
        return;
    try {
        await messaging.send({
            token,
            notification: { title, body },
            data,
            android: { priority: "high" },
            apns: { payload: { aps: { sound: "default" } } },
        });
    }
    catch (e) {
        // Token stale — remove it
        await db.doc(`users/${toUid}`).update({ fcmToken: admin.firestore.FieldValue.delete() });
    }
}
// ─── Helper: create in-app notification ──────────────────────────────────────
async function createNotification(toUid, type, message, fromUid, fromName, extraData = {}) {
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
exports.sendFriendRequest = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    var _a, _b;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const fromUid = request.auth.uid;
    const { toUid } = request.data;
    if (fromUid === toUid)
        throw new https_1.HttpsError("invalid-argument", "Cannot add yourself");
    // Check not already friends
    const friendDoc = await db.doc(`friends/${fromUid}/list/${toUid}`).get();
    if (friendDoc.exists)
        throw new https_1.HttpsError("already-exists", "Already friends");
    // Check no pending request
    const existing = await db
        .collection("friend_requests")
        .where("fromUid", "==", fromUid)
        .where("toUid", "==", toUid)
        .where("status", "==", "pending")
        .limit(1)
        .get();
    if (!existing.empty)
        return { requestId: existing.docs[0].id }; // already sent
    const fromSnap = await db.doc(`users/${fromUid}`).get();
    const fromName = (_b = (_a = fromSnap.data()) === null || _a === void 0 ? void 0 : _a.name) !== null && _b !== void 0 ? _b : "Пользователь";
    const ref = await db.collection("friend_requests").add({
        fromUid,
        toUid,
        fromName,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await createNotification(toUid, "friend_request", `${fromName} хочет добавить вас в друзья`, fromUid, fromName, { requestId: ref.id });
    await sendPush(toUid, "Запрос в друзья", `${fromName} хочет добавить вас в друзья`, { type: "friend_request", requestId: ref.id });
    return { requestId: ref.id };
});
// ── acceptFriendRequest ───────────────────────────────────────────────────────
exports.acceptFriendRequest = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    var _a, _b, _c, _d;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const { requestId } = request.data;
    const reqRef = db.doc(`friend_requests/${requestId}`);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists)
        throw new https_1.HttpsError("not-found", "Request not found");
    const req = reqSnap.data();
    if (req.toUid !== uid)
        throw new https_1.HttpsError("permission-denied", "Not your request");
    if (req.status !== "pending")
        throw new https_1.HttpsError("failed-precondition", "Request already handled");
    const fromUid = req.fromUid;
    // Load both user names
    const [fromSnap, toSnap] = await Promise.all([
        db.doc(`users/${fromUid}`).get(),
        db.doc(`users/${uid}`).get(),
    ]);
    const fromName = (_b = (_a = fromSnap.data()) === null || _a === void 0 ? void 0 : _a.name) !== null && _b !== void 0 ? _b : "Пользователь";
    const toName = (_d = (_c = toSnap.data()) === null || _c === void 0 ? void 0 : _c.name) !== null && _d !== void 0 ? _d : "Пользователь";
    const now = admin.firestore.FieldValue.serverTimestamp();
    const batch = db.batch();
    // Update request status
    batch.update(reqRef, { status: "accepted" });
    // Add to both friends lists (bidirectional)
    batch.set(db.doc(`friends/${fromUid}/list/${uid}`), { addedAt: now, name: toName });
    batch.set(db.doc(`friends/${uid}/list/${fromUid}`), { addedAt: now, name: fromName });
    await batch.commit();
    await createNotification(fromUid, "friend_accepted", `${toName} принял(а) ваш запрос в друзья`, uid, toName);
    await sendPush(fromUid, "Запрос принят", `${toName} теперь ваш друг!`, { type: "friend_accepted" });
    return { success: true };
});
// ── declineFriendRequest ──────────────────────────────────────────────────────
exports.declineFriendRequest = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const { requestId } = request.data;
    const reqRef = db.doc(`friend_requests/${requestId}`);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists)
        throw new https_1.HttpsError("not-found", "Request not found");
    if (reqSnap.data().toUid !== uid)
        throw new https_1.HttpsError("permission-denied", "Not your request");
    await reqRef.update({ status: "declined" });
    return { success: true };
});
// ── removeFriend ──────────────────────────────────────────────────────────────
exports.removeFriend = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const { friendUid } = request.data;
    const batch = db.batch();
    batch.delete(db.doc(`friends/${uid}/list/${friendUid}`));
    batch.delete(db.doc(`friends/${friendUid}/list/${uid}`));
    await batch.commit();
    return { success: true };
});
// ── searchUsers ─────────────────────────────────────────────────────────────────────────────
exports.searchUsers = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const { query } = request.data;
    if (!query || query.length < 2)
        throw new https_1.HttpsError("invalid-argument", "Query too short");
    const q = query.toLowerCase().trim();
    const qEnd = q + "";
    const [nameSnap, emailSnap, callerFriendsSnap] = await Promise.all([
        db.collection("users")
            .where("nameLower", ">=", q)
            .where("nameLower", "<=", qEnd)
            .limit(20)
            .get(),
        db.collection("users")
            .where("email", ">=", q)
            .where("email", "<=", qEnd)
            .limit(20)
            .get(),
        db.collection(`friends/${request.auth.uid}/list`).get(),
    ]);
    const friendUids = new Set(callerFriendsSnap.docs.map((d) => d.id));
    const seen = new Set();
    const allDocs = [...nameSnap.docs, ...emailSnap.docs].filter((d) => {
        if (d.id === request.auth.uid || seen.has(d.id)) return false;
        seen.add(d.id);
        return true;
    });
    return allDocs.map((d) => {
        const data = d.data();
        return {
            uid: d.id,
            name: data.name || "",
            email: data.email || "",
            username: data.username || "",
            isFriend: friendUids.has(d.id),
        };
    });
});
// ═══════════════════════════════════════════════════════════════════════════════
// FEED FANOUT
// ═══════════════════════════════════════════════════════════════════════════════
// Triggered when the app writes to /activity_events/{uid}/items/{eventId}
// Fans out to all friends' /feed/{friendUid}/events/
exports.fanoutActivityEvent = (0, firestore_1.onDocumentCreated)({ document: "activity_events/{uid}/items/{eventId}", region: "europe-west1" }, async (event) => {
    var _a, _b, _c, _d;
    const uid = event.params.uid;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const userSnap = await db.doc(`users/${uid}`).get();
    const fromName = (_c = (_b = userSnap.data()) === null || _b === void 0 ? void 0 : _b.name) !== null && _c !== void 0 ? _c : "Пользователь";
    // Get all friends
    const friendsSnap = await db.collection(`friends/${uid}/list`).get();
    if (friendsSnap.empty)
        return;
    const feedEntry = {
        type: data.type,
        fromUid: uid,
        fromName,
        data: (_d = data.data) !== null && _d !== void 0 ? _d : {},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
    // Fan out to each friend's feed (batched writes, max 500 per batch)
    const chunks = [[]];
    for (const friendDoc of friendsSnap.docs) {
        const last = chunks[chunks.length - 1];
        if (last.length >= 499)
            chunks.push([]);
        chunks[chunks.length - 1].push(db.collection(`feed/${friendDoc.id}/events`).doc());
    }
    for (const chunk of chunks) {
        const batch = db.batch();
        for (const ref of chunk)
            batch.set(ref, feedEntry);
        await batch.commit();
    }
});
// ═══════════════════════════════════════════════════════════════════════════════
// CHALLENGES
// ═══════════════════════════════════════════════════════════════════════════════
// ── createChallenge ───────────────────────────────────────────────────────────
exports.createChallenge = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    var _a, _b, _c;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const { title, description, goalType, targetValue, durationDays, isPublic } = request.data;
    if (!(title === null || title === void 0 ? void 0 : title.trim()))
        throw new https_1.HttpsError("invalid-argument", "Title required");
    if (targetValue <= 0)
        throw new https_1.HttpsError("invalid-argument", "Target must be > 0");
    if (durationDays < 1 || durationDays > 90)
        throw new https_1.HttpsError("invalid-argument", "Duration 1–90 days");
    const now = admin.firestore.Timestamp.now();
    const endDate = admin.firestore.Timestamp.fromDate(new Date(Date.now() + durationDays * 86400000));
    const userSnap = await db.doc(`users/${uid}`).get();
    const creatorName = (_b = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.name) !== null && _b !== void 0 ? _b : "Пользователь";
    const ref = await db.collection("challenges").add({
        title: title.trim(),
        description: (_c = description === null || description === void 0 ? void 0 : description.trim()) !== null && _c !== void 0 ? _c : "",
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
    return { challengeId: ref.id };
});
// ── joinChallenge ─────────────────────────────────────────────────────────────
exports.joinChallenge = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    var _a, _b;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const { challengeId } = request.data;
    const chalRef = db.doc(`challenges/${challengeId}`);
    const chalSnap = await chalRef.get();
    if (!chalSnap.exists)
        throw new https_1.HttpsError("not-found", "Challenge not found");
    const chal = chalSnap.data();
    const now = admin.firestore.Timestamp.now();
    if (chal.endDate.toMillis() < now.toMillis()) {
        throw new https_1.HttpsError("failed-precondition", "Challenge already ended");
    }
    if (chal.participants.includes(uid)) {
        throw new https_1.HttpsError("already-exists", "Already joined");
    }
    const userSnap = await db.doc(`users/${uid}`).get();
    const name = (_b = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.name) !== null && _b !== void 0 ? _b : "Пользователь";
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
    return { success: true };
});
// ── updateChallengeProgress ────────────────────────────────────────────────────
exports.updateChallengeProgress = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    var _a, _b, _c, _d;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const { challengeId, value } = request.data;
    if (typeof value !== "number" || value < 0 || value > 1000000 || !Number.isFinite(value)) {
        throw new https_1.HttpsError("invalid-argument", "value must be a finite number between 0 and 1000000");
    }
    if (typeof challengeId !== "string" || challengeId.trim().length === 0) {
        throw new https_1.HttpsError("invalid-argument", "challengeId must be a non-empty string");
    }
    const chalSnap = await db.doc(`challenges/${challengeId}`).get();
    if (!chalSnap.exists)
        throw new https_1.HttpsError("not-found", "Challenge not found");
    const chal = chalSnap.data();
    if (!chal.participants.includes(uid)) {
        throw new https_1.HttpsError("permission-denied", "Not a participant");
    }
    const progressRef = db.doc(`challenge_progress/${challengeId}/participants/${uid}`);
    const prevSnap = await progressRef.get();
    const prev = (_b = (_a = prevSnap.data()) === null || _a === void 0 ? void 0 : _a.currentValue) !== null && _b !== void 0 ? _b : 0;
    const newValue = Math.max(prev, value); // never decrease
    await progressRef.update({
        currentValue: newValue,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Check if challenge completed
    if (newValue >= chal.targetValue && prev < chal.targetValue) {
        const userSnap = await db.doc(`users/${uid}`).get();
        const name = (_d = (_c = userSnap.data()) === null || _c === void 0 ? void 0 : _c.name) !== null && _d !== void 0 ? _d : "Пользователь";
        // Notify creator
        if (chal.createdBy !== uid) {
            await sendPush(chal.createdBy, "Челлендж выполнен!", `${name} достиг(ла) цели в челлендже «${chal.title}»`, { type: "challenge_completed", challengeId });
        }
        // Write to own activity so friends see it in feed
        await db.collection(`activity_events/${uid}/items`).add({
            type: "challenge_won",
            data: { challengeTitle: chal.title, challengeId },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    return { newValue };
});
// ── recordWorkout ─────────────────────────────────────────────────────────────
exports.recordWorkout = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    var _a, _b, _c, _d;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const { caloriesBurned, cardioMinutes, streak } = request.data;
    const now = admin.firestore.Timestamp.now();
    const [challengesSnap, userSnap] = await Promise.all([
        db.collection("challenges")
            .where("participants", "array-contains", uid)
            .where("endDate", ">=", now)
            .get(),
        db.doc(`users/${uid}`).get(),
    ]);
    if (challengesSnap.empty)
        return { updated: 0, completed: [] };
    const userName = (_b = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.name) !== null && _b !== void 0 ? _b : "Пользователь";
    const progressRefs = challengesSnap.docs.map((d) => db.doc(`challenge_progress/${d.id}/participants/${uid}`));
    const progressSnaps = await Promise.all(progressRefs.map((r) => r.get()));
    const batch = db.batch();
    const completedChallenges = [];
    for (let i = 0; i < challengesSnap.docs.length; i++) {
        const chalDoc = challengesSnap.docs[i];
        const chal = chalDoc.data();
        const prev = (_d = (_c = progressSnaps[i].data()) === null || _c === void 0 ? void 0 : _c.currentValue) !== null && _d !== void 0 ? _d : 0;
        let newValue;
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
        }, { merge: true });
        if (newValue >= chal.targetValue && prev < chal.targetValue) {
            completedChallenges.push(chal.title);
            await db.collection(`activity_events/${uid}/items`).add({
                type: "challenge_won",
                data: { challengeTitle: chal.title, challengeId: chalDoc.id },
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            if (chal.createdBy !== "system" && chal.createdBy !== uid) {
                await sendPush(chal.createdBy, "Челлендж выполнен!", `${userName} достиг цели в «${chal.title}»`, { type: "challenge_completed", challengeId: chalDoc.id });
            }
        }
    }
    await batch.commit();
    return { updated: challengesSnap.size, completed: completedChallenges };
});
// ── seedChallenges ────────────────────────────────────────────────────────────
exports.seedChallenges = (0, https_1.onCall)({ region: "europe-west1" }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const existing = await db.collection("challenges")
        .where("isPredefined", "==", true)
        .limit(1)
        .get();
    if (!existing.empty)
        return { skipped: true, reason: "Already seeded" };
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
        batch.set(ref, Object.assign(Object.assign({}, c), { isPublic: true, isPredefined: true, createdBy: "system", creatorName: "FitnesBuster", participants: [], durationDays: 365, startDate: now, endDate: farFuture, createdAt: now }));
    }
    await batch.commit();
    return { seeded: predefined.length };
});
// ═══════════════════════════════════════════════════════════════════════════════
// MAINTENANCE
// ═══════════════════════════════════════════════════════════════════════════════
// Runs every day at 03:00 UTC — deletes feed events older than 30 days
exports.cleanOldFeedEvents = (0, scheduler_1.onSchedule)({ schedule: "0 3 * * *", region: "europe-west1" }, async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 30 * 86400000));
    // Get all users
    const usersSnap = await db.collection("users").select().get();
    for (const userDoc of usersSnap.docs) {
        const oldEvents = await db
            .collection(`feed/${userDoc.id}/events`)
            .where("timestamp", "<", cutoff)
            .limit(400)
            .get();
        if (oldEvents.empty)
            continue;
        const batch = db.batch();
        for (const doc of oldEvents.docs)
            batch.delete(doc.ref);
        await batch.commit();
    }
});
// ── exerciseDbProxy ───────────────────────────────────────────────────────────
// Proxies a name-search request to ExerciseDB (RapidAPI) and returns the GIF URL.
// The API key lives in Firebase Secret Manager — never shipped in the APK.
exports.exerciseDbProxy = (0, https_1.onCall)({ region: "europe-west1", secrets: [exerciseDbApiKey] }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const { exerciseName } = request.data;
    if (!(exerciseName === null || exerciseName === void 0 ? void 0 : exerciseName.trim()))
        throw new https_1.HttpsError("invalid-argument", "exerciseName required");
    const encoded = encodeURIComponent(exerciseName.trim().toLowerCase());
    return new Promise((resolve, reject) => {
        const req = https.request({
            hostname: "exercisedb.p.rapidapi.com",
            path: `/exercises/name/${encoded}?limit=1&offset=0`,
            method: "GET",
            headers: {
                "X-RapidAPI-Key": exerciseDbApiKey.value(),
                "X-RapidAPI-Host": "exercisedb.p.rapidapi.com",
            },
        }, (res) => {
            let data = "";
            res.on("data", (chunk) => { data += chunk; });
            res.on("end", () => {
                var _a, _b;
                try {
                    if (res.statusCode !== 200) {
                        reject(new https_1.HttpsError("internal", `ExerciseDB error ${res.statusCode}: ${data}`));
                        return;
                    }
                    const json = JSON.parse(data);
                    const gifUrl = Array.isArray(json) && json.length > 0
                        ? (_b = (_a = json[0]) === null || _a === void 0 ? void 0 : _a.gifUrl) !== null && _b !== void 0 ? _b : null
                        : null;
                    resolve({ gifUrl });
                }
                catch (e) {
                    reject(new https_1.HttpsError("internal", `Parse error: ${e}`));
                }
            });
        });
        req.on("error", (e) => reject(new https_1.HttpsError("internal", `Network error: ${e.message}`)));
        req.end();
    });
});
// ── deepseekProxy ──────────────────────────────────────────────────────────────
exports.deepseekProxy = (0, https_1.onCall)({ region: "europe-west1", secrets: [deepseekApiKey] }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const { messages, maxTokens = 4096, temperature = 0.7 } = request.data;
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "messages must be a non-empty array");
    }
    const body = JSON.stringify({
        model: "deepseek-chat",
        messages,
        max_tokens: maxTokens,
        temperature,
    });
    return new Promise((resolve, reject) => {
        const req = https.request({
            hostname: "api.deepseek.com",
            path: "/chat/completions",
            method: "POST",
            headers: {
                "Authorization": `Bearer ${deepseekApiKey.value()}`,
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(body),
            },
        }, (res) => {
            let data = "";
            res.on("data", (chunk) => { data += chunk; });
            res.on("end", () => {
                var _a, _b, _c;
                try {
                    const json = JSON.parse(data);
                    if (res.statusCode !== 200) {
                        reject(new https_1.HttpsError("internal", `DeepSeek error ${res.statusCode}: ${data}`));
                        return;
                    }
                    const content = (_c = (_b = (_a = json === null || json === void 0 ? void 0 : json.choices) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.message) === null || _c === void 0 ? void 0 : _c.content;
                    if (!content) {
                        reject(new https_1.HttpsError("internal", "Empty response from DeepSeek"));
                        return;
                    }
                    resolve({ content });
                }
                catch (e) {
                    reject(new https_1.HttpsError("internal", `Parse error: ${e}`));
                }
            });
        });
        req.on("error", (e) => reject(new https_1.HttpsError("internal", `Network error: ${e.message}`)));
        req.write(body);
        req.end();
    });
});

// ── fixNameLower (one-time patch) ─────────────────────────────────────────────
exports.fixNameLower = (0, https_1.onRequest)({ region: "europe-west1" }, async (req, res) => {
    if (req.query.secret !== "fb_seed_2026") { res.status(403).send("Forbidden"); return; }
    try {
        const snap = await db.collection("users").get();
        const results = [];
        for (const doc of snap.docs) {
            const d = doc.data();
            const name = (d.name || "").trim();
            const currentLower = d.nameLower || "";
            const correctLower = name.toLowerCase();
            if (name && currentLower !== correctLower) {
                await doc.ref.update({ nameLower: correctLower });
                results.push({ uid: doc.id, was: currentLower, now: correctLower });
            } else {
                results.push({ uid: doc.id, ok: true, nameLower: currentLower });
            }
        }
        res.json({ ok: true, results });
    } catch (e) { res.status(500).json({ error: e.message }); }
});


// ── cleanupDuplicateRequests (one-time) ──────────────────────────────────────
exports.cleanupDuplicateRequests = (0, https_1.onRequest)({ region: "europe-west1" }, async (req, res) => {
    if (req.query.secret !== "fb_seed_2026") { res.status(403).send("Forbidden"); return; }
    try {
        const snap = await db.collection("friend_requests").where("status", "==", "pending").get();
        // Group by fromUid+toUid, keep newest, delete rest
        const groups = {};
        for (const doc of snap.docs) {
            const d = doc.data();
            const key = d.fromUid + "_" + d.toUid;
            if (!groups[key]) groups[key] = [];
            groups[key].push(doc);
        }
        let deleted = 0;
        for (const [key, docs] of Object.entries(groups)) {
            if (docs.length <= 1) continue;
            // Sort by createdAt desc, keep first, delete rest
            docs.sort((a, b) => {
                const ta = a.data().createdAt?.toMillis() || 0;
                const tb = b.data().createdAt?.toMillis() || 0;
                return tb - ta;
            });
            for (let i = 1; i < docs.length; i++) {
                await docs[i].ref.delete();
                deleted++;
            }
        }
        res.json({ ok: true, deleted, groups: Object.keys(groups).length });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

//# sourceMappingURL=index.js.map
