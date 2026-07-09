const test = require("node:test");
const assert = require("node:assert/strict");

const {
  evaluateRateLimit,
  isRateLimitContentionError,
} = require("../lib/rateLimitLogic");

test("evaluateRateLimit allows first request and starts a window", () => {
  assert.deepEqual(evaluateRateLimit(undefined, 1000, 2, 60000), {
    allowed: true,
    nextState: {count: 1, windowStart: 1000},
    exceeded: false,
  });
});

test("evaluateRateLimit increments inside active window", () => {
  assert.deepEqual(evaluateRateLimit({count: 1, windowStart: 1000}, 2000, 2, 60000), {
    allowed: true,
    nextState: {count: 2, windowStart: 1000},
    exceeded: false,
  });
});

test("evaluateRateLimit denies when max is reached", () => {
  assert.deepEqual(evaluateRateLimit({count: 2, windowStart: 1000}, 2000, 2, 60000), {
    allowed: false,
    exceeded: true,
  });
});

test("evaluateRateLimit resets expired windows", () => {
  assert.deepEqual(evaluateRateLimit({count: 2, windowStart: 1000}, 62001, 2, 60000), {
    allowed: true,
    nextState: {count: 1, windowStart: 62001},
    exceeded: false,
  });
});

test("isRateLimitContentionError detects Firestore ABORTED", () => {
  assert.equal(isRateLimitContentionError({code: 10}), true);
  assert.equal(isRateLimitContentionError({code: 14}), false);
});
