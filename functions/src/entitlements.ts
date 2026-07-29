import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db, logInfo, logWarn} from "./shared";
import {validateSetEntitlementData} from "./entitlementsValidation";

/**
 * Grants or revokes a user's entitlement tier (admin-only, guarded by the same
 * custom-claims check as seedChallenges).
 *
 * The entitlement lives at `users/{uid}.entitlement` with the shape:
 * `{tier, source, updatedAt, expiresAt}`. Firestore rules reject client writes
 * to this field (server-only list), so this callable is the single write
 * authority. A future billing backend will write through the same path with
 * `source: "billing"`.
 */
export const setEntitlement = onCall(
  {region: "europe-west1"},
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const callerToken = request.auth.token;
    if (callerToken?.role !== "admin" && callerToken?.admin !== true) {
      logWarn("setEntitlement denied: non-admin caller", {uid: request.auth.uid});
      throw new HttpsError("permission-denied", "Admin access required");
    }

    const {targetUid, tier, expiresAt} = validateSetEntitlementData(request.data);

    await db.doc(`users/${targetUid}`).set(
      {
        entitlement: {
          tier,
          source: "admin",
          updatedAt: FieldValue.serverTimestamp(),
          expiresAt: expiresAt ? Timestamp.fromDate(expiresAt) : null,
        },
      },
      {merge: true}
    );

    logInfo("Entitlement updated", {targetUid, tier, by: request.auth.uid});
    return {success: true};
  }
);
