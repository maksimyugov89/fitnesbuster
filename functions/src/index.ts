import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Re-export barrel for all Cloud Functions callables and scheduled jobs.
 *
 * Import from this file:
 * ```
 * import {sendFriendRequest, searchUsers, ...} from "./src";
 * ```
 */

// Friends — friend request lifecycle and user search
export {sendFriendRequest, acceptFriendRequest, declineFriendRequest, removeFriend, searchUsers} from "./friends";

// Feed — validated activity publishing and cross-user fan-out
export {publishActivity, fanoutActivityEvent} from "./feed";

// Challenges — creation, participation, progress tracking, seeding
export {createChallenge, joinChallenge, leaveChallenge, deleteChallenge, updateChallengeProgress, recordWorkout, seedChallenges} from "./challenges";

// Maintenance — scheduled cleanup jobs
export {cleanOldFeedEvents, cleanExpiredChallenges} from "./maintenance";

// Proxies — third-party API proxying (DeepSeek AI)
export {deepseekProxy} from "./proxies";

// Account — GDPR-compliant self-service account deletion
export {deleteAccount} from "./account";

// Entitlements — admin-only premium tier management (single write authority
// for users/{uid}.entitlement, which Firestore rules mark server-only)
export {setEntitlement} from "./entitlements";
