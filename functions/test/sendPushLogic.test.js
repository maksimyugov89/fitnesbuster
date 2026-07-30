const test = require("node:test");
const assert = require("node:assert/strict");

const {shouldDeleteFcmToken} = require("../lib/sendPushLogic");

test("shouldDeleteFcmToken returns true for dead-token error codes", () => {
  assert.equal(shouldDeleteFcmToken("messaging/registration-token-not-registered"), true);
  assert.equal(shouldDeleteFcmToken("messaging/invalid-registration-token"), true);
});

test("shouldDeleteFcmToken returns false for transient or unrelated error codes", () => {
  assert.equal(shouldDeleteFcmToken("messaging/internal-error"), false);
  assert.equal(shouldDeleteFcmToken("messaging/server-unavailable"), false);
  assert.equal(shouldDeleteFcmToken("messaging/third-party-auth-error"), false);
  assert.equal(shouldDeleteFcmToken(undefined), false);
  assert.equal(shouldDeleteFcmToken(""), false);
});
