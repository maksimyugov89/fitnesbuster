import * as https from "https";
import {defineSecret} from "firebase-functions/params";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logInfo, logError, checkRateLimit} from "./shared";
import {
  DEEPSEEK_RATE_LIMIT,
  EXERCISEDB_RATE_LIMIT,
  RATE_LIMIT_WINDOW_MS,
  DEEPSEEK_DEFAULT_MAX_TOKENS,
  DEEPSEEK_DEFAULT_TEMPERATURE,
} from "./constants";
import type {DeepSeekRequest, ExerciseDbRequest} from "./types";

const deepseekApiKey = defineSecret("DEEPSEEK_API_KEY");
const exerciseDbApiKey = defineSecret("EXERCISE_DB_API_KEY");

/**
 * Proxies exercise GIF lookups to the ExerciseDB RapidAPI.
 *
 * Rate-limited to {@link EXERCISEDB_RATE_LIMIT} requests per minute per user.
 * Returns the first matching GIF URL or `null`.
 */
export const exerciseDbProxy = onCall(
  {region: "europe-west1", secrets: [exerciseDbApiKey]},
  async (request: {auth?: {uid: string}; data: ExerciseDbRequest}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const uid = request.auth.uid;
    const allowed = await checkRateLimit(uid, "exerciseDbProxy", EXERCISEDB_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many requests. Try again later.");

    const {exerciseName} = request.data;
    if (!exerciseName?.trim()) throw new HttpsError("invalid-argument", "exerciseName required");
    logInfo("exerciseDbProxy lookup", {uid, exerciseName: exerciseName.trim().toLowerCase()});

    const encoded = encodeURIComponent(exerciseName.trim().toLowerCase());

    return new Promise<{gifUrl: string | null}>((resolve, reject) => {
      const req = https.request(
        {
          hostname: "exercisedb.p.rapidapi.com",
          path: `/exercises/name/${encoded}?limit=1&offset=0`,
          method: "GET",
          headers: {
            "X-RapidAPI-Key": exerciseDbApiKey.value(),
            "X-RapidAPI-Host": "exercisedb.p.rapidapi.com",
          },
        },
        (res) => {
          let data = "";
          res.on("data", (chunk) => { data += chunk; });
          res.on("end", () => {
            try {
              if (res.statusCode !== 200) {
                logError("ExerciseDB proxy error", `${res.statusCode}: ${data}`, {exerciseName});
                reject(new HttpsError("internal", `ExerciseDB error ${res.statusCode}`));
                return;
              }
              const json = JSON.parse(data);
              const gifUrl = Array.isArray(json) && json.length > 0
                ? (json[0]?.gifUrl as string | undefined) ?? null
                : null;
              resolve({gifUrl});
            } catch (e) {
              logError("ExerciseDB parse error", e, {exerciseName});
              reject(new HttpsError("internal", "Parse error"));
            }
          });
        }
      );
      req.on("error", (e) => {
        logError("ExerciseDB network error", e, {exerciseName});
        reject(new HttpsError("internal", "Network error"));
      });
      req.end();
    });
  }
);

/**
 * Proxies AI requests to the DeepSeek API.
 *
 * Rate-limited to {@link DEEPSEEK_RATE_LIMIT} requests per minute per user.
 * Accepts a conversation-style messages array and returns the model's
 * completion text.
 *
 * Optional parameters:
 * - `maxTokens` — defaults to {@link DEEPSEEK_DEFAULT_MAX_TOKENS}
 * - `temperature` — defaults to {@link DEEPSEEK_DEFAULT_TEMPERATURE}
 */
export const deepseekProxy = onCall(
  {region: "europe-west1", secrets: [deepseekApiKey]},
  async (request: {auth?: {uid: string}; data: DeepSeekRequest}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const uid = request.auth.uid;
    const allowed = await checkRateLimit(uid, "deepseekProxy", DEEPSEEK_RATE_LIMIT, RATE_LIMIT_WINDOW_MS);
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many AI requests. Try again later.");

    const {messages, maxTokens = DEEPSEEK_DEFAULT_MAX_TOKENS, temperature = DEEPSEEK_DEFAULT_TEMPERATURE} = request.data;
    logInfo("deepseekProxy request", {uid, messageCount: messages?.length ?? 0, maxTokens, temperature});

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      throw new HttpsError("invalid-argument", "messages must be a non-empty array");
    }

    const body = JSON.stringify({
      model: "deepseek-chat",
      messages,
      max_tokens: maxTokens,
      temperature,
    });

    return new Promise<{content: string}>((resolve, reject) => {
      const req = https.request(
        {
          hostname: "api.deepseek.com",
          path: "/chat/completions",
          method: "POST",
          headers: {
            "Authorization": `Bearer ${deepseekApiKey.value()}`,
            "Content-Type": "application/json",
            "Content-Length": Buffer.byteLength(body),
          },
        },
        (res) => {
          let data = "";
          res.on("data", (chunk) => { data += chunk; });
          res.on("end", () => {
            try {
              const json = JSON.parse(data);
              if (res.statusCode !== 200) {
                logError("DeepSeek proxy error", `${res.statusCode}: ${data}`, {uid});
                reject(new HttpsError("internal", `DeepSeek error ${res.statusCode}`));
                return;
              }
              const content = json?.choices?.[0]?.message?.content as string | undefined;
              if (!content) {
                logError("DeepSeek empty response", "No content in response", {uid});
                reject(new HttpsError("internal", "Empty response from DeepSeek"));
                return;
              }
              resolve({content});
            } catch (e) {
              logError("DeepSeek parse error", e, {uid});
              reject(new HttpsError("internal", "Parse error"));
            }
          });
        }
      );
      req.on("error", (e) => {
        logError("DeepSeek network error", e, {uid});
        reject(new HttpsError("internal", "Network error"));
      });
      req.write(body);
      req.end();
    });
  }
);
