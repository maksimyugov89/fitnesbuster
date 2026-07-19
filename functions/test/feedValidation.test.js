const test = require("node:test");
const assert = require("node:assert/strict");

const {
  validatePublishActivityRequest,
  validatePublishActivityPayload,
} = require("../lib/feedValidation");

test("validatePublishActivityPayload accepts known activity type", () => {
  const result = validatePublishActivityPayload("workout_done", {
    workoutId: "w1",
    calories: 250,
  });

  assert.deepEqual(result, {
    type: "workout_done",
    data: {workoutId: "w1", calories: 250},
  });
});

test("validatePublishActivityPayload defaults missing data to empty object", () => {
  const result = validatePublishActivityPayload("achievement", undefined);

  assert.deepEqual(result, {type: "achievement", data: {}});
});

test("validatePublishActivityRequest accepts callable request object", () => {
  const result = validatePublishActivityRequest({
    type: "pr_set",
    data: {exercise: "bench"},
  });

  assert.deepEqual(result, {type: "pr_set", data: {exercise: "bench"}});
});

test("validatePublishActivityRequest rejects missing request object", () => {
  assert.throws(
    () => validatePublishActivityRequest(undefined),
    /request data must be an object/
  );
});

test("validatePublishActivityPayload rejects unknown activity type", () => {
  assert.throws(
    () => validatePublishActivityPayload("admin_event", {}),
    /Unsupported activity type/
  );
});

test("validatePublishActivityPayload rejects non-object data", () => {
  assert.throws(
    () => validatePublishActivityPayload("pr_set", ["not", "an", "object"]),
    /data must be an object/
  );
});

test("validatePublishActivityPayload rejects oversized data", () => {
  assert.throws(
    () => validatePublishActivityPayload("challenge_won", {
      text: "x".repeat(10_001),
    }),
    /data payload is too large/
  );
});
