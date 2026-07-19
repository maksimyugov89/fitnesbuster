"use strict";

const {after, before, beforeEach, test} = require("node:test");
const assert = require("node:assert/strict");
const {deleteApp, initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");

const projectId = process.env.GCLOUD_PROJECT || "demo-fitnesbuster";
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const databaseId = "fitnesbuster";

let app;
let db;
let sequence = 0;

function emulatorUrl(host, path) {
  assert.ok(host, `Missing emulator host for ${path}`);
  return `http://${host}${path}`;
}

function firestoreDocUrl(path) {
  return emulatorUrl(
    firestoreHost,
    `/v1/projects/${projectId}/databases/${databaseId}/documents/${path}`
  );
}

function firestoreCommitUrl() {
  return emulatorUrl(
    firestoreHost,
    `/v1/projects/${projectId}/databases/${databaseId}/documents:commit`
  );
}

async function readJson(response) {
  const text = await response.text();
  return text ? JSON.parse(text) : {};
}

function authHeaders(token) {
  const headers = {"Content-Type": "application/json"};
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

function fieldValue(value) {
  if (value === null) return {nullValue: null};
  if (typeof value === "boolean") return {booleanValue: value};
  if (typeof value === "number") {
    return Number.isInteger(value) ? {integerValue: String(value)} : {doubleValue: value};
  }
  if (typeof value === "string") return {stringValue: value};
  if (value instanceof Date) return {timestampValue: value.toISOString()};
  if (Array.isArray(value)) return {arrayValue: {values: value.map(fieldValue)}};
  if (typeof value === "object") return {mapValue: {fields: firestoreFields(value)}};
  throw new Error(`Unsupported Firestore test value: ${value}`);
}

function firestoreFields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, fieldValue(value)]));
}

async function getDoc(path, token) {
  const response = await fetch(firestoreDocUrl(path), {headers: authHeaders(token)});
  return {response, json: await readJson(response)};
}

async function createDoc(collectionPath, token, data, documentId) {
  const query = documentId ? `?documentId=${encodeURIComponent(documentId)}` : "";
  const response = await fetch(`${firestoreDocUrl(collectionPath)}${query}`, {
    method: "POST",
    headers: authHeaders(token),
    body: JSON.stringify({fields: firestoreFields(data)}),
  });
  return {response, json: await readJson(response)};
}

async function commitWrites(token, writes) {
  const response = await fetch(firestoreCommitUrl(), {
    method: "POST",
    headers: authHeaders(token),
    body: JSON.stringify({writes}),
  });
  return {response, json: await readJson(response)};
}

async function patchDoc(path, token, data) {
  const response = await fetch(firestoreDocUrl(path), {
    method: "PATCH",
    headers: authHeaders(token),
    body: JSON.stringify({fields: firestoreFields(data)}),
  });
  return {response, json: await readJson(response)};
}

function assertOk(result) {
  assert.equal(result.response.ok, true, JSON.stringify(result.json));
}

function assertDenied(result) {
  assert.equal(result.response.status, 403, JSON.stringify(result.json));
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
    email,
    updatedAt: Timestamp.now(),
  });
  return {uid: json.localId, token: json.idToken, email};
}

async function createAuthOnlyUser(label) {
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
  return {uid: json.localId, token: json.idToken, email};
}

function legalConsentWrite(uid, source = "email_registration") {
  const recordId = "terms-2026-07-07-privacy-2026-07-17";
  return {
    update: {
      name:
        `projects/${projectId}/databases/${databaseId}/documents/` +
        `users/${uid}/legal_consents/${recordId}`,
      fields: firestoreFields({
        termsVersion: "2026-07-07",
        privacyPolicyVersion: "2026-07-17",
        source,
        locale: "ru",
      }),
    },
    currentDocument: {exists: false},
    updateTransforms: [
      {fieldPath: "acceptedAt", setToServerValue: "REQUEST_TIME"},
    ],
  };
}

before(async () => {
  assert.ok(authHost, "FIREBASE_AUTH_EMULATOR_HOST must be set");
  assert.ok(firestoreHost, "FIRESTORE_EMULATOR_HOST must be set");
  app = initializeApp({projectId}, "firestore-rules-emulator-tests");
  db = getFirestore(app, databaseId);
});

beforeEach(clearEmulators);

after(async () => {
  await deleteApp(app);
});

test("users documents are owner-only for reads and writes", async () => {
  const owner = await createUser("Owner");
  const other = await createUser("Other");

  assertOk(await getDoc(`users/${owner.uid}`, owner.token));
  assertDenied(await getDoc(`users/${other.uid}`, owner.token));
  assertDenied(await getDoc(`users/${owner.uid}`, null));

  assertOk(await patchDoc(`users/${owner.uid}`, owner.token, {name: "Owner Updated"}));
  assertDenied(await patchDoc(`users/${other.uid}`, owner.token, {name: "Hacked"}));
  assertDenied(await patchDoc(`users/${owner.uid}`, null, {name: "Anonymous"}));
});

test("user profile creation requires immutable current legal consent", async () => {
  const user = await createAuthOnlyUser("Consent");
  const profile = {
    name: "Consent",
    nameLower: "consent",
    email: user.email,
  };

  assertDenied(await createDoc("users", user.token, profile, user.uid));
  assertOk(await commitWrites(user.token, [legalConsentWrite(user.uid)]));
  assertOk(await createDoc("users", user.token, profile, user.uid));

  const migratedGoogleUser = await createAuthOnlyUser("GoogleConsent");
  assertOk(
    await commitWrites(migratedGoogleUser.token, [
      legalConsentWrite(migratedGoogleUser.uid, "google_login"),
    ])
  );

  const migratedCachedUser = await createAuthOnlyUser("LoginConsent");
  assertOk(
    await commitWrites(migratedCachedUser.token, [
      legalConsentWrite(migratedCachedUser.uid, "login"),
    ])
  );

  assertDenied(
    await patchDoc(
      `users/${user.uid}/legal_consents/terms-2026-07-07-privacy-2026-07-17`,
      user.token,
      {locale: "en"}
    )
  );
});

test("direct client writes to callable-owned social collections are denied", async () => {
  const user = await createUser("User");
  const friend = await createUser("Friend");
  const now = new Date();

  const deniedWrites = [
    createDoc("friend_requests", user.token, {
      fromUid: user.uid,
      toUid: friend.uid,
      status: "pending",
      createdAt: now,
    }),
    createDoc(`activity_events/${user.uid}/items`, user.token, {
      type: "workout_done",
      timestamp: now,
    }),
    createDoc(`feed/${user.uid}/events`, user.token, {
      type: "workout_done",
      timestamp: now,
    }),
    createDoc("challenges", user.token, {
      title: "Client-created challenge",
      createdBy: user.uid,
      participants: [user.uid],
      endDate: now,
    }),
    patchDoc(`challenge_progress/challenge-id/participants/${user.uid}`, user.token, {
      uid: user.uid,
      currentValue: 1,
    }),
    createDoc(`notifications/${user.uid}/items`, user.token, {
      type: "friend_request",
      createdAt: now,
    }),
  ];

  for (const result of await Promise.all(deniedWrites)) {
    assertDenied(result);
  }
});

test("social read scopes match ownership and authenticated challenge visibility", async () => {
  const owner = await createUser("Owner");
  const friend = await createUser("Friend");
  const stranger = await createUser("Stranger");
  const now = Timestamp.now();

  await Promise.all([
    db.doc("friend_requests/request-owned").set({
      fromUid: owner.uid,
      toUid: friend.uid,
      status: "pending",
      createdAt: now,
    }),
    db.doc("friend_requests/request-unrelated").set({
      fromUid: friend.uid,
      toUid: stranger.uid,
      status: "pending",
      createdAt: now,
    }),
    db.doc(`activity_events/${owner.uid}/items/event-1`).set({
      type: "workout_done",
      timestamp: now,
    }),
    db.doc(`feed/${owner.uid}/events/event-1`).set({
      type: "workout_done",
      timestamp: now,
    }),
    db.doc(`notifications/${owner.uid}/items/notif-1`).set({
      type: "friend_request",
      createdAt: now,
    }),
    db.doc("challenges/challenge-1").set({
      title: "Visible to authenticated users",
      createdBy: owner.uid,
      participants: [owner.uid],
      endDate: now,
    }),
    db.doc("challenge_progress/challenge-1/participants/owner").set({
      uid: owner.uid,
      currentValue: 1,
    }),
  ]);

  assertOk(await getDoc("friend_requests/request-owned", owner.token));
  assertOk(await getDoc("friend_requests/request-owned", friend.token));
  assertDenied(await getDoc("friend_requests/request-owned", stranger.token));
  assertDenied(await getDoc("friend_requests/request-unrelated", owner.token));

  for (const path of [
    `activity_events/${owner.uid}/items/event-1`,
    `feed/${owner.uid}/events/event-1`,
    `notifications/${owner.uid}/items/notif-1`,
  ]) {
    assertOk(await getDoc(path, owner.token));
    assertDenied(await getDoc(path, friend.token));
    assertDenied(await getDoc(path, null));
  }

  assertOk(await getDoc("challenges/challenge-1", owner.token));
  assertOk(await getDoc("challenges/challenge-1", stranger.token));
  assertDenied(await getDoc("challenges/challenge-1", null));

  assertOk(await getDoc("challenge_progress/challenge-1/participants/owner", friend.token));
  assertDenied(await getDoc("challenge_progress/challenge-1/participants/owner", null));
});
