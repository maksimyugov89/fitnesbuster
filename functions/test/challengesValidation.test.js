const test = require("node:test");
const assert = require("node:assert/strict");

const {
  crossesTarget,
  nextWorkoutStreak,
  progressForWorkout,
  validateChallengeId,
  validateCreateChallengeData,
  validateProgressValue,
  validateRecordWorkoutData,
} = require("../lib/challengesValidation");
const {
  CHALLENGE_MAX_DURATION_DAYS,
  CHALLENGE_MAX_PROGRESS,
  WORKOUT_MAX_CALORIES,
  WORKOUT_MAX_STREAK,
} = require("../lib/constants");

test("validateCreateChallengeData sanitizes valid challenge input", () => {
  assert.deepEqual(
    validateCreateChallengeData({
      title: "  Steps ",
      description: "  Desc ",
      goalType: "workout_count",
      targetValue: 3,
      durationDays: 7,
      isPublic: true,
    }),
    {
      title: "Steps",
      description: "Desc",
      goalType: "workout_count",
      targetValue: 3,
      durationDays: 7,
      isPublic: true,
    }
  );
});

test("validateCreateChallengeData rejects invalid bounds", () => {
  assert.throws(
    () => validateCreateChallengeData({title: "", targetValue: 1, durationDays: 1}),
    /Title required/
  );
  assert.throws(
    () => validateCreateChallengeData({title: "x", targetValue: 0, durationDays: 1}),
    /Target must be > 0/
  );
  assert.throws(
    () => validateCreateChallengeData({
      title: "x",
      targetValue: 1,
      durationDays: CHALLENGE_MAX_DURATION_DAYS + 1,
    }),
    /Duration/
  );
});

test("challenge id and progress validators reject bad values", () => {
  assert.throws(() => validateChallengeId(" "), /challengeId must be a non-empty string/);
  assert.throws(() => validateProgressValue(CHALLENGE_MAX_PROGRESS + 1), /value must be/);
});

test("validateRecordWorkoutData enforces workout metric caps", () => {
  assert.deepEqual(
    validateRecordWorkoutData({caloriesBurned: 300, cardioMinutes: 20}),
    {caloriesBurned: 300, cardioMinutes: 20, streak: undefined}
  );
  assert.throws(
    () => validateRecordWorkoutData({caloriesBurned: WORKOUT_MAX_CALORIES + 1, cardioMinutes: 0}),
    /caloriesBurned must be/
  );
});

test("nextWorkoutStreak keeps same-day streak, extends yesterday, restarts gaps", () => {
  const now = new Date("2026-07-10T12:00:00.000Z");
  assert.equal(nextWorkoutStreak("2026-07-10", 4, now), 4);
  assert.equal(nextWorkoutStreak("2026-07-09", 4, now), 5);
  assert.equal(nextWorkoutStreak("2026-07-08", 4, now), 1);
});

test("progressForWorkout updates each supported goal type", () => {
  assert.equal(progressForWorkout("workout_count", 2, 100, 10, 3), 3);
  assert.equal(progressForWorkout("calories_burned", 2, 100, 10, 3), 102);
  assert.equal(progressForWorkout("cardio_minutes", 2, 100, 10, 3), 12);
  assert.equal(progressForWorkout("workout_streak", 2, 100, 10, 3), 3);
});

test("crossesTarget only fires on first crossing", () => {
  assert.equal(crossesTarget(9, 10, 10), true);
  assert.equal(crossesTarget(10, 11, 10), false);
  assert.equal(crossesTarget(8, 9, 10), false);
});

test("validateRecordWorkoutData accepts a valid streak seed", () => {
  const result = validateRecordWorkoutData({caloriesBurned: 100, cardioMinutes: 10, streak: 7});
  assert.deepEqual(result, {caloriesBurned: 100, cardioMinutes: 10, streak: 7});
});

test("validateRecordWorkoutData treats a missing streak seed as undefined", () => {
  const result = validateRecordWorkoutData({caloriesBurned: 100, cardioMinutes: 10});
  assert.equal(result.streak, undefined);
});

test("validateRecordWorkoutData rejects malformed streak seeds", () => {
  for (const streak of [-1, WORKOUT_MAX_STREAK + 1, 1.5, "7", NaN]) {
    assert.throws(
      () => validateRecordWorkoutData({caloriesBurned: 100, cardioMinutes: 10, streak}),
      /streak must be an integer/
    );
  }
});
