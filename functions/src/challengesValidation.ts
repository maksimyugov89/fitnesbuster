import {HttpsError} from "firebase-functions/v2/https";
import {
  CHALLENGE_MAX_DURATION_DAYS,
  CHALLENGE_MAX_PROGRESS,
  WORKOUT_MAX_CALORIES,
  WORKOUT_MAX_CARDIO_MINUTES,
  WORKOUT_MAX_STREAK,
} from "./constants";

export interface ValidatedCreateChallenge {
  title: string;
  description: string;
  goalType: string;
  targetValue: number;
  durationDays: number;
  isPublic: boolean;
}

export function validateChallengeId(challengeId: unknown): string {
  if (typeof challengeId !== "string" || challengeId.trim().length === 0) {
    throw new HttpsError("invalid-argument", "challengeId must be a non-empty string");
  }
  return challengeId.trim();
}

export function validateCreateChallengeData(data: {
  title?: unknown;
  description?: unknown;
  goalType?: unknown;
  targetValue?: unknown;
  durationDays?: unknown;
  isPublic?: unknown;
}): ValidatedCreateChallenge {
  if (typeof data.title !== "string" || data.title.trim().length === 0) {
    throw new HttpsError("invalid-argument", "Title required");
  }
  if (typeof data.targetValue !== "number" || !Number.isFinite(data.targetValue) || data.targetValue <= 0) {
    throw new HttpsError("invalid-argument", "Target must be > 0");
  }
  if (typeof data.durationDays !== "number" || data.durationDays < 1 || data.durationDays > CHALLENGE_MAX_DURATION_DAYS) {
    throw new HttpsError("invalid-argument", `Duration 1–${CHALLENGE_MAX_DURATION_DAYS} days`);
  }
  return {
    title: data.title.trim(),
    description: typeof data.description === "string" ? data.description.trim() : "",
    goalType: typeof data.goalType === "string" ? data.goalType : "workout_count",
    targetValue: data.targetValue,
    durationDays: data.durationDays,
    isPublic: data.isPublic === true,
  };
}

export function validateProgressValue(value: unknown): number {
  if (typeof value !== "number" || value < 0 || value > CHALLENGE_MAX_PROGRESS || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `value must be a finite number between 0 and ${CHALLENGE_MAX_PROGRESS}`);
  }
  return value;
}

export function validateRecordWorkoutData(data: {
  caloriesBurned?: unknown;
  cardioMinutes?: unknown;
}): {caloriesBurned: number; cardioMinutes: number} {
  const {caloriesBurned, cardioMinutes} = data;
  if (typeof caloriesBurned !== "number" || caloriesBurned < 0 || caloriesBurned > WORKOUT_MAX_CALORIES || !Number.isFinite(caloriesBurned)) {
    throw new HttpsError("invalid-argument", `caloriesBurned must be 0-${WORKOUT_MAX_CALORIES}`);
  }
  if (typeof cardioMinutes !== "number" || cardioMinutes < 0 || cardioMinutes > WORKOUT_MAX_CARDIO_MINUTES || !Number.isFinite(cardioMinutes)) {
    throw new HttpsError("invalid-argument", `cardioMinutes must be 0-${WORKOUT_MAX_CARDIO_MINUTES}`);
  }
  return {caloriesBurned, cardioMinutes};
}

export function utcDateKey(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function nextWorkoutStreak(
  lastWorkoutDate: string | undefined,
  previousStreak: number | undefined,
  now: Date
): number {
  const todayKey = utcDateKey(now);
  const yesterdayKey = utcDateKey(new Date(now.getTime() - 86_400_000));
  const prevStreak = Math.min(previousStreak ?? 0, WORKOUT_MAX_STREAK);
  if (lastWorkoutDate === todayKey) return prevStreak;
  if (lastWorkoutDate === yesterdayKey) return Math.min(prevStreak + 1, WORKOUT_MAX_STREAK);
  return 1;
}

export function progressForWorkout(
  goalType: string,
  previousValue: number,
  caloriesBurned: number,
  cardioMinutes: number,
  streak: number
): number {
  switch (goalType) {
    case "workout_count":
      return previousValue + 1;
    case "calories_burned":
      return previousValue + Math.max(0, caloriesBurned);
    case "cardio_minutes":
      return previousValue + Math.max(0, cardioMinutes);
    case "workout_streak":
      return Math.max(previousValue, streak);
    default:
      return previousValue + 1;
  }
}

export function crossesTarget(previousValue: number, newValue: number, targetValue: number): boolean {
  return newValue >= targetValue && previousValue < targetValue;
}
