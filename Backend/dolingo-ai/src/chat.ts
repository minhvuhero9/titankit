// What the app sends to POST /v1/chat, checked before anything reaches Claude.

export type ChatRole = "user" | "assistant";

export interface ChatTurn {
  role: ChatRole;
  text: string;
}

/** What the app knows about the learner, from the sign-up questions. All optional. */
export interface Learner {
  name?: string;
  /** "beginner", "elementary", "intermediate", "advanced". */
  level?: string;
}

export interface ChatRequest {
  turns: ChatTurn[];
  learner: Learner;
}

export const LIMITS = {
  /** Older turns are dropped first; the app keeps the whole thread on screen. */
  maxTurns: 40,
  maxCharsPerTurn: 2000,
  /** The tutor's own replies come back in later requests; long ones are cut, not refused. */
  maxCharsPerReply: 8000,
  maxNameChars: 40,
} as const;

const LEVELS = new Set(["beginner", "elementary", "intermediate", "advanced"]);

/** Returns the request, or a short reason it is rejected (sent back as HTTP 400). */
export function parseChatRequest(body: unknown): ChatRequest | string {
  if (typeof body !== "object" || body === null) return "body must be a JSON object";
  const { turns, learner } = body as { turns?: unknown; learner?: unknown };
  if (!Array.isArray(turns) || turns.length === 0) return "turns must be a non-empty array";

  const parsed: ChatTurn[] = [];
  for (const turn of turns) {
    if (typeof turn !== "object" || turn === null) return "each turn must be an object";
    const { role, text } = turn as { role?: unknown; text?: unknown };
    if (role !== "user" && role !== "assistant") return "role must be user or assistant";
    if (typeof text !== "string" || text.trim() === "") return "text must be a non-empty string";
    if (role === "user" && text.length > LIMITS.maxCharsPerTurn) {
      return `text is longer than ${LIMITS.maxCharsPerTurn} characters`;
    }
    parsed.push({ role, text: role === "assistant" ? text.slice(0, LIMITS.maxCharsPerReply) : text });
  }

  // Keep the latest turns, starting on a user turn as the Messages API expects.
  let recent = parsed.slice(-LIMITS.maxTurns);
  while (recent.length > 0 && recent[0].role !== "user") recent = recent.slice(1);
  if (recent.length === 0 || recent[recent.length - 1].role !== "user") return "the last turn must be the user's";
  for (let i = 1; i < recent.length; i++) {
    if (recent[i].role === recent[i - 1].role) return "turns must alternate between user and assistant";
  }

  return { turns: recent, learner: parseLearner(learner) };
}

export function parseLearner(value: unknown): Learner {
  if (typeof value !== "object" || value === null) return {};
  const { name, level } = value as { name?: unknown; level?: unknown };
  const learner: Learner = {};
  if (typeof name === "string" && name.trim() !== "") learner.name = name.trim().slice(0, LIMITS.maxNameChars);
  if (typeof level === "string" && LEVELS.has(level)) learner.level = level;
  return learner;
}
