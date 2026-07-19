export interface RateLimitState {
  count?: unknown;
  windowStart?: unknown;
}

export interface RateLimitDecision {
  allowed: boolean;
  nextState?: {count: number; windowStart: number};
  exceeded: boolean;
}

export function evaluateRateLimit(
  state: RateLimitState | undefined,
  now: number,
  maxRequests: number,
  windowMs: number
): RateLimitDecision {
  const windowStart = typeof state?.windowStart === "number" ? state.windowStart : undefined;
  const count = typeof state?.count === "number" ? state.count : 0;

  if (windowStart === undefined || now - windowStart > windowMs) {
    return {allowed: true, nextState: {count: 1, windowStart: now}, exceeded: false};
  }
  if (count >= maxRequests) {
    return {allowed: false, exceeded: true};
  }
  return {allowed: true, nextState: {count: count + 1, windowStart}, exceeded: false};
}

export function isRateLimitContentionError(error: unknown): boolean {
  return (error as {code?: number}).code === 10;
}

export type RateLimitFailureAction = "deny" | "throw" | "allow";

export function rateLimitFailureAction(
  error: unknown,
  failClosed: boolean
): RateLimitFailureAction {
  if (isRateLimitContentionError(error)) return "deny";
  return failClosed ? "throw" : "allow";
}
