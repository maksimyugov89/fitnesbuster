const test = require("node:test");
const assert = require("node:assert/strict");

const {validateSetEntitlementData} = require("../lib/entitlementsValidation");

test("validateSetEntitlementData accepts a valid premium grant with expiry", () => {
  const result = validateSetEntitlementData({
    targetUid: "user-123",
    tier: "premium",
    expiresAt: "2027-01-01T00:00:00.000Z",
  });

  assert.equal(result.targetUid, "user-123");
  assert.equal(result.tier, "premium");
  assert.ok(result.expiresAt instanceof Date);
  assert.equal(result.expiresAt.toISOString(), "2027-01-01T00:00:00.000Z");
});

test("validateSetEntitlementData accepts free tier with null expiry", () => {
  const result = validateSetEntitlementData({
    targetUid: "user-123",
    tier: "free",
    expiresAt: null,
  });

  assert.deepEqual(result, {targetUid: "user-123", tier: "free", expiresAt: null});
});

test("validateSetEntitlementData defaults missing expiresAt to null", () => {
  const result = validateSetEntitlementData({targetUid: "user-123", tier: "premium"});
  assert.equal(result.expiresAt, null);
});

test("validateSetEntitlementData rejects non-object payloads", () => {
  for (const payload of [null, undefined, "string", 42, []]) {
    assert.throws(() => validateSetEntitlementData(payload), /must be an object/);
  }
});

test("validateSetEntitlementData rejects invalid targetUid", () => {
  for (const targetUid of ["", "   ", 42, null, undefined, "x".repeat(129)]) {
    assert.throws(
      () => validateSetEntitlementData({targetUid, tier: "premium"}),
      /targetUid/
    );
  }
});

test("validateSetEntitlementData rejects unknown tiers", () => {
  for (const tier of ["gold", "PREMIUM", "", 1, null]) {
    assert.throws(
      () => validateSetEntitlementData({targetUid: "user-123", tier}),
      /tier must be one of/
    );
  }
});

test("validateSetEntitlementData rejects malformed expiresAt", () => {
  for (const expiresAt of ["not-a-date", 12345, {}, "2026-13-45"]) {
    assert.throws(
      () =>
        validateSetEntitlementData({targetUid: "user-123", tier: "free", expiresAt}),
      /expiresAt/
    );
  }
});
