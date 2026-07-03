import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db, logInfo, logWarn, sendPush, checkRateLimit} from "./shared";
import {
  ONE_DAY_MS,
  CHALLENGE_MAX_DURATION_DAYS,
  WORKOUT_MAX_CALORIES,
  WORKOUT_MAX_CARDIO_MINUTES,
  WORKOUT_MAX_STREAK,
  CHALLENGE_MAX_PROGRESS,
  PREDEFINED_CHALLENGE_DURATION_DAYS,
  CREATE_CHALLENGE_RATE_LIMIT,
  CHALLENGE_ACTION_RATE_LIMIT,
  RATE_LIMIT_WINDOW_MS,
} from "./constants";
import type {CreateChallengeData, JoinChallengeData, UpdateChallengeProgressData, RecordWorkoutData} from "./types";

/**
 * Creates a new challenge document and registers the creator as the first
 * participant with zero progress.
 *
 * Duration is clamped between 1 and {@link CHALLENGE_MAX_DURATION_DAYS} days.
 * The end date is calculated as `startDate + durationDays × ONE_DAY_MS`.
 */
export const createChallenge = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: CreateChallengeData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {title, description, goalType, targetValue, durationDays, isPublic} = request.data;

    const allowed = await checkRateLimit(uid, "createChallenge", CREATE_CHALLENGE_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    if (!title?.trim()) throw new HttpsError("invalid-argument", "Title required");
    if (targetValue <= 0) throw new HttpsError("invalid-argument", "Target must be > 0");
    if (durationDays < 1 || durationDays > CHALLENGE_MAX_DURATION_DAYS) throw new HttpsError("invalid-argument", `Duration 1–${CHALLENGE_MAX_DURATION_DAYS} days`);

    const now = admin.firestore.Timestamp.now();
    const endDate = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + durationDays * ONE_DAY_MS)
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

    await db.doc(`challenge_progress/${ref.id}/participants/${uid}`).set({
      uid,
      name: creatorName,
      currentValue: 0,
      lastUpdated: now,
    });

    return {challengeId: ref.id};
  }
);

/**
 * Adds the authenticated user as a participant of an existing challenge.
 *
 * Validates that the challenge has not yet ended and the user is not
 * already a participant. Runs inside a transaction for consistency.
 */
export const joinChallenge = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: JoinChallengeData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {challengeId} = request.data;

    const allowed = await checkRateLimit(uid, "joinChallenge", CHALLENGE_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    if (typeof challengeId !== "string" || challengeId.trim().length === 0) {
      throw new HttpsError("invalid-argument", "challengeId must be a non-empty string");
    }

    const chalRef = db.doc(`challenges/${challengeId}`);

    // maxAttempts raised from the SDK default (5): a popular public challenge
    // can draw many simultaneous joiners, all contending on this single
    // chalRef document — under load-test conditions (60 concurrent joins)
    // the default retry budget was exhausted and threw ABORTED for over
    // half the requests.
    await db.runTransaction(async (tx) => {
      const chalSnap = await tx.get(chalRef);
      if (!chalSnap.exists) throw new HttpsError("not-found", "Challenge not found");

      const chal = chalSnap.data()!;
      const now = admin.firestore.Timestamp.now();
      if (chal.endDate.toMillis() < now.toMillis()) {
        throw new HttpsError("failed-precondition", "Challenge already ended");
      }
      if ((chal.participants as string[]).includes(uid)) {
        throw new HttpsError("already-exists", "Already joined");
      }

      tx.update(chalRef, {
        participants: admin.firestore.FieldValue.arrayUnion(uid),
      });
      tx.set(db.doc(`challenge_progress/${challengeId}/participants/${uid}`), {
        uid,
        name: "",
        currentValue: 0,
        lastUpdated: now,
      });
    }, {maxAttempts: 15});

    const userSnap = await db.doc(`users/${uid}`).get();
    const name = (userSnap.data()?.name as string) ?? "Пользователь";
    await db.doc(`challenge_progress/${challengeId}/participants/${uid}`).update({name});

    logInfo("User joined challenge", {uid, challengeId});
    return {success: true};
  }
);

/**
 * Removes the authenticated user as a participant from a challenge they've
 * joined. The creator cannot leave their own challenge — they must use
 * {@link deleteChallenge} instead, since the challenge has no owner otherwise.
 */
export const leaveChallenge = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: JoinChallengeData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {challengeId} = request.data;

    const allowed = await checkRateLimit(uid, "leaveChallenge", CHALLENGE_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    if (typeof challengeId !== "string" || challengeId.trim().length === 0) {
      throw new HttpsError("invalid-argument", "challengeId must be a non-empty string");
    }

    const chalRef = db.doc(`challenges/${challengeId}`);
    const progressRef = db.doc(`challenge_progress/${challengeId}/participants/${uid}`);

    await db.runTransaction(async (tx) => {
      const chalSnap = await tx.get(chalRef);
      if (!chalSnap.exists) throw new HttpsError("not-found", "Challenge not found");

      const chal = chalSnap.data()!;
      if ((chal.createdBy as string) === uid) {
        throw new HttpsError("failed-precondition", "Creator cannot leave — delete the challenge instead");
      }
      if (!(chal.participants as string[]).includes(uid)) {
        throw new HttpsError("failed-precondition", "Not a participant");
      }

      tx.update(chalRef, {
        participants: admin.firestore.FieldValue.arrayRemove(uid),
      });
      tx.delete(progressRef);
    }, {maxAttempts: 15});

    logInfo("User left challenge", {uid, challengeId});
    return {success: true};
  }
);

/**
 * Deletes a challenge and all of its participants' progress documents.
 * Only the challenge's creator may delete it.
 */
export const deleteChallenge = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: JoinChallengeData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {challengeId} = request.data;

    const allowed = await checkRateLimit(uid, "deleteChallenge", CHALLENGE_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    if (typeof challengeId !== "string" || challengeId.trim().length === 0) {
      throw new HttpsError("invalid-argument", "challengeId must be a non-empty string");
    }

    const chalRef = db.doc(`challenges/${challengeId}`);
    const chalSnap = await chalRef.get();
    if (!chalSnap.exists) throw new HttpsError("not-found", "Challenge not found");

    const chal = chalSnap.data()!;
    if ((chal.createdBy as string) !== uid) {
      throw new HttpsError("permission-denied", "Only the creator can delete this challenge");
    }

    const progressSnap = await db.collection(`challenge_progress/${challengeId}/participants`).get();
    const batch = db.batch();
    for (const doc of progressSnap.docs) batch.delete(doc.ref);
    batch.delete(chalRef);
    await batch.commit();

    logInfo("Challenge deleted", {uid, challengeId, participantsRemoved: progressSnap.size});
    return {success: true};
  }
);

/**
 * Updates a participant's progress in a challenge. Progress is monotonic
 * (the higher of the previous or submitted value is stored).
 *
 * When the target is reached for the first time (`crossed` transition),
 * the creator is notified and a `challenge_won` activity event is written
 * to the participant's feed.
 */
export const updateChallengeProgress = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: UpdateChallengeProgressData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {challengeId, value} = request.data;

    const allowed = await checkRateLimit(uid, "updateChallengeProgress", CHALLENGE_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    if (typeof value !== "number" || value < 0 || value > CHALLENGE_MAX_PROGRESS || !Number.isFinite(value)) {
      throw new HttpsError("invalid-argument", `value must be a finite number between 0 and ${CHALLENGE_MAX_PROGRESS}`);
    }
    if (typeof challengeId !== "string" || challengeId.trim().length === 0) {
      throw new HttpsError("invalid-argument", "challengeId must be a non-empty string");
    }

    const chalRef = db.doc(`challenges/${challengeId}`);
    const progressRef = db.doc(`challenge_progress/${challengeId}/participants/${uid}`);

    const crossed = await db.runTransaction(async (tx) => {
      const chalSnap = await tx.get(chalRef);
      if (!chalSnap.exists) throw new HttpsError("not-found", "Challenge not found");

      const chal = chalSnap.data()!;
      if (!(chal.participants as string[]).includes(uid)) {
        throw new HttpsError("permission-denied", "Not a participant");
      }

      const prevSnap = await tx.get(progressRef);
      const prev = (prevSnap.data()?.currentValue as number) ?? 0;
      const newValue = Math.max(prev, value);

      tx.update(progressRef, {
        currentValue: newValue,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });

      return newValue >= (chal.targetValue as number) && prev < (chal.targetValue as number);
    });

    if (crossed) {
      const chalSnap = await chalRef.get();
      const chal = chalSnap.data()!;
      const userSnap = await db.doc(`users/${uid}`).get();
      const name = (userSnap.data()?.name as string) ?? "Пользователь";

      if (chal.createdBy !== uid) {
        await sendPush(
          chal.createdBy as string,
          "Челлендж выполнен!",
          `${name} достиг(ла) цели в челлендже «${chal.title}»`,
          {type: "challenge_completed", challengeId}
        );
      }

      await db.collection(`activity_events/${uid}/items`).add({
        type: "challenge_won",
        data: {challengeTitle: chal.title, challengeId},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {newValue: value};
  }
);

/**
 * Records workout data against all active challenges the user participates in.
 *
 * Iterates over each active challenge and updates progress according to the
 * challenge's `goalType`:
 * - `workout_count` — increments by 1
 * - `calories_burned` — accumulates calories (max {@link WORKOUT_MAX_CALORIES})
 * - `cardio_minutes` — accumulates minutes (max {@link WORKOUT_MAX_CARDIO_MINUTES})
 * - `workout_streak` — stores the higher of previous or current streak
 *   (max {@link WORKOUT_MAX_STREAK})
 *
 * When a target is newly crossed, a challenge_won event is emitted and the
 * creator is notified via push (unless the creator is the participant).
 */
export const recordWorkout = onCall(
  {region: "europe-west1"},
  async (request: {auth?: {uid: string}; data: RecordWorkoutData}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");
    const uid = request.auth.uid;
    const {caloriesBurned, cardioMinutes, streak} = request.data;

    const allowed = await checkRateLimit(uid, "recordWorkout", CHALLENGE_ACTION_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    if (typeof caloriesBurned !== "number" || caloriesBurned < 0 || caloriesBurned > WORKOUT_MAX_CALORIES) {
      throw new HttpsError("invalid-argument", `caloriesBurned must be 0-${WORKOUT_MAX_CALORIES}`);
    }
    if (typeof cardioMinutes !== "number" || cardioMinutes < 0 || cardioMinutes > WORKOUT_MAX_CARDIO_MINUTES) {
      throw new HttpsError("invalid-argument", `cardioMinutes must be 0-${WORKOUT_MAX_CARDIO_MINUTES}`);
    }
    if (typeof streak !== "number" || streak < 0 || streak > WORKOUT_MAX_STREAK) {
      throw new HttpsError("invalid-argument", `streak must be 0-${WORKOUT_MAX_STREAK}`);
    }

    const now = admin.firestore.Timestamp.now();
    const [challengesSnap, userSnap] = await Promise.all([
      db.collection("challenges")
        .where("participants", "array-contains", uid)
        .where("endDate", ">=", now)
        .get(),
      db.doc(`users/${uid}`).get(),
    ]);

    if (challengesSnap.empty) {
      logInfo("recordWorkout: no active challenges", {uid});
      return {updated: 0, completed: []};
    }

    const userName = (userSnap.data()?.name as string) ?? "Пользователь";
    logInfo("recordWorkout", {uid, challengeCount: challengesSnap.size});

    const completedChallenges: string[] = [];

    for (const chalDoc of challengesSnap.docs) {
      const chal = chalDoc.data();
      const challengeId = chalDoc.id;
      const progressRef = db.doc(`challenge_progress/${challengeId}/participants/${uid}`);

      const crossed = await db.runTransaction(async (tx) => {
        const prevSnap = await tx.get(progressRef);
        const prev = (prevSnap.data()?.currentValue as number) ?? 0;

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

        tx.set(progressRef, {
          uid,
          name: userName,
          currentValue: newValue,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        return newValue >= (chal.targetValue as number) && prev < (chal.targetValue as number);
      });

      if (crossed) {
        completedChallenges.push(chal.title as string);
        await db.collection(`activity_events/${uid}/items`).add({
          type: "challenge_won",
          data: {challengeTitle: chal.title, challengeId},
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        if ((chal.createdBy as string) !== "system" && (chal.createdBy as string) !== uid) {
          await sendPush(
            chal.createdBy as string,
            "Челлендж выполнен!",
            `${userName} достиг цели в «${chal.title}»`,
            {type: "challenge_completed", challengeId}
          );
        }
      }
    }

    return {updated: challengesSnap.size, completed: completedChallenges};
  }
);

/**
 * Seeds predefined system challenges into Firestore (admin-only).
 *
 * The caller must have either `role === "admin"` or `admin === true` in
 * their auth token custom claims. Idempotent: skips if any predefined
 * challenge document already exists.
 */
export const seedChallenges = onCall(
  {region: "europe-west1"},
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const callerToken = request.auth.token;
    if (callerToken?.role !== "admin" && callerToken?.admin !== true) {
      logWarn("seedChallenges denied: non-admin caller", {uid: request.auth.uid});
      throw new HttpsError("permission-denied", "Admin access required");
    }
    logInfo("seedChallenges called", {uid: request.auth.uid});

    const existing = await db.collection("challenges")
      .where("isPredefined", "==", true)
      .limit(1)
      .get();
    if (!existing.empty) return {skipped: true, reason: "Already seeded"};

    const farFuture = admin.firestore.Timestamp.fromDate(new Date("2030-01-01"));
    const now = admin.firestore.Timestamp.now();

    const predefined = [
      {title: "Первые шаги", description: "Выполни 3 тренировки и начни свой путь к здоровью", goalType: "workout_count", targetValue: 3, emoji: "👟"},
      {title: "Неделя силы", description: "Заверши 7 тренировок — докажи свою настойчивость", goalType: "workout_count", targetValue: 7, emoji: "💪"},
      {title: "Кардио-марафон", description: "Набери 120 минут кардио-тренировок суммарно", goalType: "cardio_minutes", targetValue: 120, emoji: "🏃"},
      {title: "Жиросжигатель", description: "Сожги 2000 ккал суммарно в тренировках", goalType: "calories_burned", targetValue: 2000, emoji: "🔥"},
      {title: "Серия 14 дней", description: "Тренируйся 14 дней подряд без пропусков", goalType: "workout_streak", targetValue: 14, emoji: "⚡"},
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
        durationDays: PREDEFINED_CHALLENGE_DURATION_DAYS,
        startDate: now,
        endDate: farFuture,
        createdAt: now,
      });
    }
    await batch.commit();
    return {seeded: predefined.length};
  }
);
