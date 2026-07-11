"use strict";

const {after, before, beforeEach, test} = require("node:test");
const assert = require("node:assert/strict");
const {deleteApp, initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");

const projectId = process.env.GCLOUD_PROJECT || "demo-fitnesbuster";
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";
const databaseId = "fitnesbuster";

let app;
let db;
let sequence = 0;

function emulatorUrl(host, path) {
  assert.ok(host, `Missing emulator host for ${path}`);
  return `http://${host}${path}`;
}

async function readJson(response) {
  const text = await response.text();
  return text ? JSON.parse(text) : {};
}

async function clearEmulators() {
  const [authResponse, firestoreResponse] = await Promise.all([
    fetch(emulatorUrl(authHost, `/emulator/v1/projects/${projectId}/accounts`), {
      method: "DELETE",
    }),
    fetch(
      emulatorUrl(
        firestoreHost,
        `/emulator/v1/projects/${projectId}/databases/${databaseId}/documents`
      ),
      {method: "DELETE"}
    ),
  ]);
  assert.equal(authResponse.ok, true, await authResponse.text());
  assert.equal(firestoreResponse.ok, true, await firestoreResponse.text());
}

async function createUser(label) {
  sequence += 1;
  const email = `${label}-${sequence}@example.test`;
  const response = await fetch(
    emulatorUrl(
      authHost,
      "/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key"
    ),
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({email, password: "StrongPass123!", returnSecureToken: true}),
    }
  );
  const json = await readJson(response);
  assert.equal(response.ok, true, JSON.stringify(json));
  await db.doc(`users/${json.localId}`).set({
    name: label,
    nameLower: label.toLowerCase(),
    username: label,
    usernameLower: label.toLowerCase(),
    email,
  });
  return {uid: json.localId, token: json.idToken, email};
}

async function callCallable(name, token, data) {
  const headers = {"Content-Type": "application/json"};
  if (token) headers.Authorization = `Bearer ${token}`;
  const response = await fetch(
    `http://${functionsHost}/${projectId}/europe-west1/${name}`,
    {
      method: "POST",
      headers,
      body: JSON.stringify({data}),
    }
  );
  return {response, json: await readJson(response)};
}

function callableResult(result) {
  return result.json.result ?? result.json.data;
}

function assertCallableError(result, status) {
  assert.equal(result.response.ok, false, JSON.stringify(result.json));
  assert.equal(result.json.error?.status, status, JSON.stringify(result.json));
}

async function waitFor(read, predicate, timeoutMs = 10_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const value = await read();
    if (predicate(value)) return value;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  assert.fail("Timed out waiting for emulator state");
}

before(async () => {
  assert.ok(authHost, "FIREBASE_AUTH_EMULATOR_HOST must be set");
  assert.ok(firestoreHost, "FIRESTORE_EMULATOR_HOST must be set");
  app = initializeApp({projectId}, "callable-emulator-tests");
  db = getFirestore(app, databaseId);
});

beforeEach(clearEmulators);

after(async () => {
  await deleteApp(app);
});

test("publishActivity requires auth and writes a validated event", async () => {
  const unauthenticated = await callCallable("publishActivity", null, {
    type: "workout_done",
    data: {},
  });
  assertCallableError(unauthenticated, "UNAUTHENTICATED");

  const user = await createUser("publisher");
  const published = await callCallable("publishActivity", user.token, {
    type: "workout_done",
    data: {durationMinutes: 45},
  });
  assert.equal(published.response.ok, true, JSON.stringify(published.json));
  const eventId = callableResult(published).eventId;
  const event = await db.doc(`activity_events/${user.uid}/items/${eventId}`).get();
  assert.equal(event.exists, true);
  assert.equal(event.data().type, "workout_done");
  assert.deepEqual(event.data().data, {durationMinutes: 45});
});

test("friend request lifecycle is atomic and duplicate-safe", async () => {
  const sender = await createUser("Alice");
  const recipient = await createUser("Bob");

  const sent = await callCallable("sendFriendRequest", sender.token, {
    toUid: recipient.uid,
  });
  assert.equal(sent.response.ok, true, JSON.stringify(sent.json));
  const requestId = callableResult(sent).requestId;

  const duplicate = await callCallable("sendFriendRequest", sender.token, {
    toUid: recipient.uid,
  });
  assertCallableError(duplicate, "ALREADY_EXISTS");

  const accepted = await callCallable("acceptFriendRequest", recipient.token, {
    requestId,
  });
  assert.equal(accepted.response.ok, true, JSON.stringify(accepted.json));

  const [left, right, request] = await Promise.all([
    db.doc(`friends/${sender.uid}/list/${recipient.uid}`).get(),
    db.doc(`friends/${recipient.uid}/list/${sender.uid}`).get(),
    db.doc(`friend_requests/${requestId}`).get(),
  ]);
  assert.equal(left.exists, true);
  assert.equal(right.exists, true);
  assert.equal(request.data().status, "accepted");

  const removed = await callCallable("removeFriend", sender.token, {
    friendUid: recipient.uid,
  });
  assert.equal(removed.response.ok, true, JSON.stringify(removed.json));
  const [removedLeft, removedRight] = await Promise.all([
    left.ref.get(),
    right.ref.get(),
  ]);
  assert.equal(removedLeft.exists, false);
  assert.equal(removedRight.exists, false);
});

test("private challenge invite fanout, join, leave, and delete honor permissions", async () => {
  const creator = await createUser("Creator");
  const friend = await createUser("Friend");
  const stranger = await createUser("Stranger");
  const addedAt = Timestamp.now();
  await Promise.all([
    db.doc(`friends/${creator.uid}/list/${friend.uid}`).set({name: "Friend", addedAt}),
    db.doc(`friends/${friend.uid}/list/${creator.uid}`).set({name: "Creator", addedAt}),
  ]);

  const created = await callCallable("createChallenge", creator.token, {
    title: "Private sprint",
    description: "Invite-only challenge",
    goalType: "workout_count",
    targetValue: 3,
    durationDays: 7,
    isPublic: false,
  });
  assert.equal(created.response.ok, true, JSON.stringify(created.json));
  const challengeId = callableResult(created).challengeId;

  const friendFeed = await waitFor(
    () => db.collection(`feed/${friend.uid}/events`).get(),
    (snapshot) => !snapshot.empty
  );
  assert.equal(friendFeed.docs[0].data().type, "challenge_created");
  assert.equal(friendFeed.docs[0].data().data.challengeId, challengeId);
  assert.equal((await db.collection(`feed/${stranger.uid}/events`).get()).empty, true);

  const strangerJoin = await callCallable("joinChallenge", stranger.token, {challengeId});
  assertCallableError(strangerJoin, "PERMISSION_DENIED");

  const joined = await callCallable("joinChallenge", friend.token, {challengeId});
  assert.equal(joined.response.ok, true, JSON.stringify(joined.json));
  assert.equal(
    (await db.doc(`challenge_progress/${challengeId}/participants/${friend.uid}`).get()).exists,
    true
  );

  const nonOwnerDelete = await callCallable("deleteChallenge", friend.token, {challengeId});
  assertCallableError(nonOwnerDelete, "PERMISSION_DENIED");

  const left = await callCallable("leaveChallenge", friend.token, {challengeId});
  assert.equal(left.response.ok, true, JSON.stringify(left.json));
  assert.equal(
    (await db.doc(`challenge_progress/${challengeId}/participants/${friend.uid}`).get()).exists,
    false
  );

  const deleted = await callCallable("deleteChallenge", creator.token, {challengeId});
  assert.equal(deleted.response.ok, true, JSON.stringify(deleted.json));
  assert.equal((await db.doc(`challenges/${challengeId}`).get()).exists, false);
});

test("deepseekProxy enforces auth and validates payload before provider access", async () => {
  const unauthenticated = await callCallable("deepseekProxy", null, {messages: []});
  assertCallableError(unauthenticated, "UNAUTHENTICATED");

  const user = await createUser("AIUser");
  const invalid = await callCallable("deepseekProxy", user.token, {messages: []});
  assertCallableError(invalid, "INVALID_ARGUMENT");
});

test("rate limiter caps concurrent publishActivity calls at the remaining quota", async () => {
  const user = await createUser("BurstUser");
  await db.doc(`rate_limits/${user.uid}_publishActivity`).set({
    count: 29,
    windowStart: Date.now(),
  });

  const calls = Array.from({length: 3}, (_, index) =>
    callCallable("publishActivity", user.token, {
      type: "workout_done",
      data: {sequence: index},
    })
  );
  const results = await Promise.all(calls);
  const allowed = results.filter((result) => result.response.ok);
  const denied = results.filter(
    (result) => result.json.error?.status === "RESOURCE_EXHAUSTED"
  );
  const diagnostics = results.map((result) => result.json);
  assert.equal(allowed.length, 1, diagnostics);
  assert.equal(denied.length, 2, diagnostics);
  assert.equal(allowed.length + denied.length, results.length, diagnostics);

  const limiter = await db.doc(`rate_limits/${user.uid}_publishActivity`).get();
  assert.equal(limiter.data()?.count, 30, diagnostics);
});

test("deleteAccount removes owned data, reciprocal links, participation, and Auth user", async () => {
  const user = await createUser("DeleteMe");
  const friend = await createUser("Survivor");
  const now = Timestamp.now();
  const challengeRef = db.collection("challenges").doc();
  await Promise.all([
    db.doc(`friends/${user.uid}/list/${friend.uid}`).set({name: "Survivor", addedAt: now}),
    db.doc(`friends/${friend.uid}/list/${user.uid}`).set({name: "DeleteMe", addedAt: now}),
    db.collection("friend_requests").add({
      fromUid: user.uid,
      toUid: friend.uid,
      status: "pending",
      createdAt: now,
    }),
    db.collection(`activity_events/${user.uid}/items`).add({type: "workout_done", timestamp: now}),
    db.collection(`feed/${user.uid}/events`).add({type: "friend_joined", timestamp: now}),
    db.collection(`notifications/${user.uid}/items`).add({type: "test", createdAt: now}),
    challengeRef.set({
      title: "Cleanup",
      participants: [user.uid, friend.uid],
      createdBy: friend.uid,
      endDate: Timestamp.fromMillis(Date.now() + 86_400_000),
    }),
  ]);
  await db.doc(`challenge_progress/${challengeRef.id}/participants/${user.uid}`).set({
    uid: user.uid,
    currentValue: 1,
  });

  const deleted = await callCallable("deleteAccount", user.token, {});
  assert.equal(deleted.response.ok, true, JSON.stringify(deleted.json));

  assert.equal((await db.doc(`users/${user.uid}`).get()).exists, false);
  assert.equal((await db.doc(`friends/${friend.uid}/list/${user.uid}`).get()).exists, false);
  assert.equal(
    (await db.doc(`challenge_progress/${challengeRef.id}/participants/${user.uid}`).get()).exists,
    false
  );
  const challenge = await challengeRef.get();
  assert.deepEqual(challenge.data().participants, [friend.uid]);

  const lookup = await fetch(
    emulatorUrl(
      authHost,
      "/identitytoolkit.googleapis.com/v1/accounts:lookup?key=fake-api-key"
    ),
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({idToken: user.token}),
    }
  );
  assert.equal(lookup.ok, false, await lookup.text());
});
