const test = require("node:test");
const assert = require("node:assert/strict");

const {
  DEEPSEEK_DEFAULT_MAX_TOKENS,
  DEEPSEEK_DEFAULT_TEMPERATURE,
  DEEPSEEK_MAX_MESSAGE_LENGTH,
  DEEPSEEK_MAX_MESSAGES,
  DEEPSEEK_MAX_TOKENS_CAP,
} = require("../lib/constants");
const {validateDeepSeekRequest} = require("../lib/proxiesValidation");

test("validateDeepSeekRequest accepts messages and applies defaults", () => {
  const result = validateDeepSeekRequest({
    messages: [{role: "user", content: "hello"}],
  });

  assert.deepEqual(result, {
    messages: [{role: "user", content: "hello"}],
    maxTokens: DEEPSEEK_DEFAULT_MAX_TOKENS,
    temperature: DEEPSEEK_DEFAULT_TEMPERATURE,
  });
});

test("validateDeepSeekRequest rejects missing messages", () => {
  assert.throws(
    () => validateDeepSeekRequest({messages: []}),
    /messages must be a non-empty array/
  );
});

test("validateDeepSeekRequest rejects missing request object", () => {
  assert.throws(
    () => validateDeepSeekRequest(undefined),
    /request data must be an object/
  );
});

test("validateDeepSeekRequest rejects too many messages", () => {
  assert.throws(
    () => validateDeepSeekRequest({
      messages: Array.from({length: DEEPSEEK_MAX_MESSAGES + 1}, () => ({
        role: "user",
        content: "hello",
      })),
    }),
    /messages must not exceed/
  );
});

test("validateDeepSeekRequest rejects oversized message content", () => {
  assert.throws(
    () => validateDeepSeekRequest({
      messages: [{role: "user", content: "x".repeat(DEEPSEEK_MAX_MESSAGE_LENGTH + 1)}],
    }),
    /each message content must be a string/
  );
});

test("validateDeepSeekRequest rejects maxTokens above cap", () => {
  assert.throws(
    () => validateDeepSeekRequest({
      messages: [{role: "user", content: "hello"}],
      maxTokens: DEEPSEEK_MAX_TOKENS_CAP + 1,
    }),
    /maxTokens must be a number between/
  );
});

test("validateDeepSeekRequest rejects invalid temperature", () => {
  assert.throws(
    () => validateDeepSeekRequest({
      messages: [{role: "user", content: "hello"}],
      temperature: Number.NaN,
    }),
    /temperature must be a finite number/
  );
});
