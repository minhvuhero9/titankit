// Roleplays the learner writes themselves: POST /v1/roleplay/draft fills in the form, and
// POST /v1/roleplay/turn plays the AI's role one turn at a time.
import * as z from "zod/v4";
import { type ChatTurn, type Learner, parseLearner } from "./chat.ts";

export const ROLEPLAY_LIMITS = {
  maxFieldChars: 200,
  maxScenarioChars: 1000,
  maxTasks: 5,
  maxTurns: 40,
  maxCharsPerTurn: 1000,
} as const;

/** The form as the learner left it; empty fields are for the AI to fill. */
export interface DraftRequest {
  title: string;
  myRole: string;
  aiRole: string;
  scenario: string;
  withGoals: boolean;
  learner: Learner;
}

export const DraftSchema = z.object({
  emoji: z.string().describe("One emoji that pictures the situation"),
  title: z.string().describe("Two to four words, Title Case"),
  myRole: z.string().describe("The learner's role, a few words"),
  aiRole: z.string().describe("The AI partner's role, a few words"),
  scenario: z.string().describe("Two or three sentences addressed to the learner as 'you'"),
  tasks: z
    .array(
      z.object({
        text: z.string().describe("A short goal in English, starting with a verb"),
        meaning: z.string().describe("The same goal in Vietnamese"),
      }),
    )
    .describe("Three or four goals, or none when goals were not asked for"),
});
export type Draft = z.infer<typeof DraftSchema>;

export interface RoleplaySetup {
  title: string;
  myRole: string;
  aiRole: string;
  scenario: string;
  tasks: { id: string; text: string }[];
}

export interface TurnRequest {
  roleplay: RoleplaySetup;
  /** Empty for the AI's opening line. "assistant" turns are the AI partner's. */
  turns: ChatTurn[];
  learner: Learner;
}

export const TurnSchema = z.object({
  reply: z.string().describe("The partner's next line, in English, in character"),
  translation: z.string().describe("The reply in Vietnamese"),
  completedTaskIds: z.array(z.string()).describe("Ids of tasks the learner's latest message completed"),
  hint: z.string().describe("A natural reply the learner could say next, in English"),
  hintTranslation: z.string().describe("The hint in Vietnamese"),
  isFinished: z.boolean().describe("True when the conversation has reached a natural end"),
});
export type Turn = z.infer<typeof TurnSchema>;

export function parseDraftRequest(body: unknown): DraftRequest | string {
  if (typeof body !== "object" || body === null) return "body must be a JSON object";
  const value = body as Record<string, unknown>;
  const fields: Record<string, string> = {};
  for (const key of ["title", "myRole", "aiRole", "scenario"] as const) {
    const field = value[key] ?? "";
    if (typeof field !== "string") return `${key} must be a string`;
    const limit = key === "scenario" ? ROLEPLAY_LIMITS.maxScenarioChars : ROLEPLAY_LIMITS.maxFieldChars;
    if (field.length > limit) return `${key} is longer than ${limit} characters`;
    fields[key] = field.trim();
  }
  return {
    title: fields.title,
    myRole: fields.myRole,
    aiRole: fields.aiRole,
    scenario: fields.scenario,
    withGoals: value.withGoals === true,
    learner: parseLearner(value.learner),
  };
}

export function parseTurnRequest(body: unknown): TurnRequest | string {
  if (typeof body !== "object" || body === null) return "body must be a JSON object";
  const { roleplay, turns, learner } = body as Record<string, unknown>;
  if (typeof roleplay !== "object" || roleplay === null) return "roleplay must be an object";
  const setup = roleplay as Record<string, unknown>;
  const strings: Record<string, string> = {};
  for (const key of ["title", "myRole", "aiRole", "scenario"] as const) {
    const field = setup[key];
    const limit = key === "scenario" ? ROLEPLAY_LIMITS.maxScenarioChars : ROLEPLAY_LIMITS.maxFieldChars;
    if (typeof field !== "string" || field.trim() === "") return `roleplay.${key} must be a non-empty string`;
    if (field.length > limit) return `roleplay.${key} is longer than ${limit} characters`;
    strings[key] = field.trim();
  }
  const rawTasks = setup.tasks ?? [];
  if (!Array.isArray(rawTasks) || rawTasks.length > ROLEPLAY_LIMITS.maxTasks) return "roleplay.tasks is invalid";
  const tasks: RoleplaySetup["tasks"] = [];
  for (const task of rawTasks) {
    const { id, text } = (task ?? {}) as Record<string, unknown>;
    if (typeof id !== "string" || typeof text !== "string" || text.length > ROLEPLAY_LIMITS.maxFieldChars) {
      return "each task needs an id and a short text";
    }
    tasks.push({ id, text });
  }

  if (!Array.isArray(turns)) return "turns must be an array";
  const parsed: ChatTurn[] = [];
  for (const turn of turns) {
    const { role, text } = (turn ?? {}) as Record<string, unknown>;
    if (role !== "user" && role !== "assistant") return "role must be user or assistant";
    if (typeof text !== "string" || text.trim() === "") return "text must be a non-empty string";
    if (text.length > ROLEPLAY_LIMITS.maxCharsPerTurn) return "text is too long";
    parsed.push({ role, text });
  }
  const recent = parsed.slice(-ROLEPLAY_LIMITS.maxTurns);
  // The AI opens the scene, so a conversation starts with its line and ends with the learner's.
  if (recent.length > 0 && recent[recent.length - 1].role !== "user") return "the last turn must be the user's";
  for (let i = 1; i < recent.length; i++) {
    if (recent[i].role === recent[i - 1].role) return "turns must alternate between user and assistant";
  }

  return {
    roleplay: { title: strings.title, myRole: strings.myRole, aiRole: strings.aiRole, scenario: strings.scenario, tasks },
    turns: recent,
    learner: parseLearner(learner),
  };
}
