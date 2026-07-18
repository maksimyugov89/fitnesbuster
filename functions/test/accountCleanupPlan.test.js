const test = require("node:test");
const assert = require("node:assert/strict");

const {
  DELETE_ACCOUNT_BATCH_LIMIT,
  challengeProgressPath,
  ownDeleteAccountCollectionPaths,
  reciprocalFriendPath,
} = require("../lib/accountCleanupPlan");

test("delete account batch limit stays under Firestore write batch maximum", () => {
  assert.equal(DELETE_ACCOUNT_BATCH_LIMIT, 450);
  assert.equal(DELETE_ACCOUNT_BATCH_LIMIT < 500, true);
});

test("ownDeleteAccountCollectionPaths lists user-owned subcollections", () => {
  assert.deepEqual(ownDeleteAccountCollectionPaths("u1"), [
    "users/u1/legal_consents",
    "activity_events/u1/items",
    "feed/u1/events",
    "notifications/u1/items",
  ]);
});

test("delete account path helpers build reciprocal and challenge progress paths", () => {
  assert.equal(reciprocalFriendPath("u1", "u2"), "friends/u2/list/u1");
  assert.equal(
    challengeProgressPath("c1", "u1"),
    "challenge_progress/c1/participants/u1"
  );
});
