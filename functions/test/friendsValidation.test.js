const test = require("node:test");
const assert = require("node:assert/strict");

const {
  mergeSearchResults,
  normalizeSearchQuery,
  validateFriendRequestId,
  validateFriendUid,
  validateSendFriendRequest,
} = require("../lib/friendsValidation");

test("validateSendFriendRequest accepts another user and trims uid", () => {
  assert.equal(validateSendFriendRequest("u1", " u2 "), "u2");
});

test("validateSendFriendRequest rejects self request", () => {
  assert.throws(() => validateSendFriendRequest("u1", "u1"), /Cannot add yourself/);
});

test("friend id validators reject blank values", () => {
  assert.throws(() => validateFriendRequestId(" "), /requestId must be a non-empty string/);
  assert.throws(() => validateFriendUid(null), /friendUid must be a non-empty string/);
});

test("normalizeSearchQuery trims and lowercases", () => {
  assert.equal(normalizeSearchQuery("  Al "), "al");
});

test("normalizeSearchQuery rejects short queries after trim", () => {
  assert.throws(() => normalizeSearchQuery(" a "), /Query too short/);
});

test("mergeSearchResults deduplicates, excludes caller, and marks friends", () => {
  const results = mergeSearchResults(
    "caller",
    [
      {id: "caller", data: {name: "Me"}},
      {id: "u1", data: {name: "Alex", username: "alex"}},
    ],
    [
      {id: "u1", data: {name: "Alex Duplicate", username: "alex2"}},
      {id: "u2", data: {name: "Bree"}},
    ],
    new Set(["u2"])
  );

  assert.deepEqual(results, [
    {uid: "u1", name: "Alex", username: "alex", isFriend: false},
    {uid: "u2", name: "Bree", username: "", isFriend: true},
  ]);
});
