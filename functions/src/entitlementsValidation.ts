import {HttpsError} from "firebase-functions/v2/https";

/** Tiers recognised by the entitlement model. */
export const ENTITLEMENT_TIERS = ["free", "premium"] as const;
export type EntitlementTier = (typeof ENTITLEMENT_TIERS)[number];

export interface ValidatedSetEntitlement {
  targetUid: string;
  tier: EntitlementTier;
  expiresAt: Date | null;
}

/**
 * Validates the payload of the admin-only setEntitlement callable.
 * Pure module so bounds and malformed input are unit-testable without
 * the emulator.
 */
export function validateSetEntitlementData(
  rawData: unknown
): ValidatedSetEntitlement {
  if (typeof rawData !== "object" || rawData === null || Array.isArray(rawData)) {
    throw new HttpsError("invalid-argument", "request data must be an object");
  }
  const data = rawData as {
    targetUid?: unknown;
    tier?: unknown;
    expiresAt?: unknown;
  };

  if (
    typeof data.targetUid !== "string" ||
    data.targetUid.trim().length === 0 ||
    data.targetUid.length > 128
  ) {
    throw new HttpsError(
      "invalid-argument",
      "targetUid must be a non-empty string of at most 128 characters"
    );
  }

  if (
    typeof data.tier !== "string" ||
    !(ENTITLEMENT_TIERS as readonly string[]).includes(data.tier)
  ) {
    throw new HttpsError(
      "invalid-argument",
      `tier must be one of: ${ENTITLEMENT_TIERS.join(", ")}`
    );
  }

  let expiresAt: Date | null = null;
  if (data.expiresAt !== null && data.expiresAt !== undefined) {
    if (
      typeof data.expiresAt !== "string" ||
      Number.isNaN(Date.parse(data.expiresAt))
    ) {
      throw new HttpsError(
        "invalid-argument",
        "expiresAt must be an ISO date string or null"
      );
    }
    expiresAt = new Date(data.expiresAt);
  }

  return {
    targetUid: data.targetUid.trim(),
    tier: data.tier as EntitlementTier,
    expiresAt,
  };
}
