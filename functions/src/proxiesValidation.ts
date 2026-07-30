import {HttpsError} from "firebase-functions/v2/https";
import {
  DEEPSEEK_DEFAULT_MAX_TOKENS,
  DEEPSEEK_DEFAULT_TEMPERATURE,
  DEEPSEEK_MAX_MESSAGE_LENGTH,
  DEEPSEEK_MAX_MESSAGES,
  DEEPSEEK_MAX_TOKENS_CAP,
  DEEPSEEK_MAX_SYSTEM_MESSAGES,
} from "./constants";

const VALID_ROLES = new Set(["system", "user", "assistant"]);
export interface ValidatedDeepSeekRequest {
  messages: Array<{role: string; content: string}>;
  maxTokens: number;
  temperature: number;
}

export function validateDeepSeekRequest(
  rawData: unknown
): ValidatedDeepSeekRequest {
  if (typeof rawData !== "object" || rawData === null || Array.isArray(rawData)) {
    throw new HttpsError("invalid-argument", "request data must be an object");
  }
  const data = rawData as {
    messages?: unknown;
    maxTokens?: unknown;
    temperature?: unknown;
  };
  const {
    messages,
    maxTokens = DEEPSEEK_DEFAULT_MAX_TOKENS,
    temperature = DEEPSEEK_DEFAULT_TEMPERATURE,
  } = data;

  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    throw new HttpsError("invalid-argument", "messages must be a non-empty array");
  }
  if (messages.length > DEEPSEEK_MAX_MESSAGES) {
    throw new HttpsError("invalid-argument", `messages must not exceed ${DEEPSEEK_MAX_MESSAGES} entries`);
  }
  const validatedMessages = messages as Array<{role: string; content: string}>;
  let systemCount = 0;
  for (const m of validatedMessages) {
    if (!VALID_ROLES.has(m.role)) {
      throw new HttpsError("invalid-argument", `invalid message role: "${m.role}". Must be one of: system, user, assistant`);
    }
    if (m.role === "system") {
      systemCount++;
      if (systemCount > DEEPSEEK_MAX_SYSTEM_MESSAGES) {
        throw new HttpsError("invalid-argument", `at most ${DEEPSEEK_MAX_SYSTEM_MESSAGES} system messages allowed per request`);
      }
    }
    if (typeof m?.content !== "string" || m.content.length > DEEPSEEK_MAX_MESSAGE_LENGTH) {
      throw new HttpsError("invalid-argument", `each message content must be a string under ${DEEPSEEK_MAX_MESSAGE_LENGTH} characters`);
    }
  }
  if (typeof maxTokens !== "number" || !Number.isFinite(maxTokens) || maxTokens <= 0 || maxTokens > DEEPSEEK_MAX_TOKENS_CAP) {
    throw new HttpsError("invalid-argument", `maxTokens must be a number between 1 and ${DEEPSEEK_MAX_TOKENS_CAP}`);
  }
  if (typeof temperature !== "number" || !Number.isFinite(temperature)) {
    throw new HttpsError("invalid-argument", "temperature must be a finite number");
  }

  return {messages: validatedMessages, maxTokens, temperature};
}
