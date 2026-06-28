// ─── Shared numeric constants for Cloud Functions ─────────────────────────────

/** 1 minute in milliseconds */
export const ONE_MINUTE_MS = 60_000;

/** 1 day in milliseconds (24 × 60 × 60 × 1000) */
export const ONE_DAY_MS = 86_400_000;

/** Rate-limit window: DeepSeek proxy — 20 AI calls per minute */
export const DEEPSEEK_RATE_LIMIT = 20;

/** Rate-limit window: ExerciseDB proxy — 30 lookups per minute */
export const EXERCISEDB_RATE_LIMIT = 30;

/** Rate-limit window duration in ms (1 minute) */
export const RATE_LIMIT_WINDOW_MS = ONE_MINUTE_MS;

/** Default max tokens for DeepSeek chat completion */
export const DEEPSEEK_DEFAULT_MAX_TOKENS = 4096;

/** Default temperature for DeepSeek chat completion */
export const DEEPSEEK_DEFAULT_TEMPERATURE = 0.7;

// ─── Friends / Search ─────────────────────────────────────────────────────────

/** Maximum search results per query (users) */
export const SEARCH_USERS_LIMIT = 20;

/** Maximum friend list size used for fanout and search deduplication */
export const FRIEND_LIST_LIMIT = 500;

// ─── Challenges ────────────────────────────────────────────────────────────────

/** Maximum challenge duration in days */
export const CHALLENGE_MAX_DURATION_DAYS = 90;

/** Maximum calories burned per single workout submission */
export const WORKOUT_MAX_CALORIES = 10_000;

/** Maximum cardio minutes per single workout submission */
export const WORKOUT_MAX_CARDIO_MINUTES = 300;

/** Maximum workout streak value per submission */
export const WORKOUT_MAX_STREAK = 365;

/** Maximum challenge progress value */
export const CHALLENGE_MAX_PROGRESS = 1_000_000;

/** Default challenge duration for predefined system challenges */
export const PREDEFINED_CHALLENGE_DURATION_DAYS = 365;

// ─── Feed ──────────────────────────────────────────────────────────────────────

/** Maximum documents per Firestore batch write */
export const FEED_CHUNK_SIZE = 499;

/** Retention period for feed events in days */
export const FEED_RETENTION_DAYS = 30;

/** Maximum feed events to delete per user per maintenance run */
export const FEED_CLEANUP_LIMIT = 400;

// ─── Retry ─────────────────────────────────────────────────────────────────────

/** Maximum retry attempts for transient Firestore operations */
export const RETRY_MAX_ATTEMPTS = 3;

/** Base retry delay in milliseconds (exponential backoff: base × 2^attempt) */
export const RETRY_BASE_DELAY_MS = 200;
