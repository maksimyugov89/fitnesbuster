import * as https from "https";
import {defineSecret} from "firebase-functions/params";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logInfo, logError, checkRateLimit, enforceAppCheck} from "./shared";
import {
  DEEPSEEK_RATE_LIMIT,
  RATE_LIMIT_WINDOW_MS,
} from "./constants";
import {validateDeepSeekRequest} from "./proxiesValidation";
import type {DeepSeekRequest} from "./types";

const deepseekApiKey = defineSecret("DEEPSEEK_API_KEY");

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
  {region: "europe-west1", enforceAppCheck, secrets: [deepseekApiKey]},
  async (request: {auth?: {uid: string}; data: DeepSeekRequest}) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Login required");

    const uid = request.auth.uid;
    const allowed = await checkRateLimit(
      uid, "deepseekProxy", DEEPSEEK_RATE_LIMIT, RATE_LIMIT_WINDOW_MS, {failClosed: true}
    );
    if (!allowed) throw new HttpsError("resource-exhausted", "Too many AI requests. Try again later.");

    const {messages, maxTokens, temperature} = validateDeepSeekRequest(request.data);
    logInfo("deepseekProxy request", {uid, messageCount: messages?.length ?? 0, maxTokens, temperature});

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
