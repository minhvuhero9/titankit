import { GoogleKeys, type KeySource, verifyFirebaseToken } from "./auth.ts";
import { parseChatRequest } from "./chat.ts";
import { legalLanguage, privacyPage, termsPage } from "./legal.ts";
import { type AIResult, ClaudeReplySource, type ReplyErrorCode, type ReplyEvent, type ReplySource, type RoleplayAI } from "./claude.ts";
import { parseDraftRequest, parseTurnRequest } from "./roleplay.ts";
import { KVUsageStore, today, type UsageStore } from "./usage.ts";

export interface Env {
  /** Set with `wrangler secret put ANTHROPIC_API_KEY`. */
  ANTHROPIC_API_KEY: string;
  /** The Firebase project whose ID tokens are accepted, e.g. "dolingo-prod" (wrangler.toml vars). */
  FIREBASE_PROJECT_ID?: string;
  /** Shared with builds without Firebase (AppConfig.aiClientKey); leave unset to turn that off. */
  CLIENT_KEY?: string;
  /** "true" accepts only signed-in users, even with CLIENT_KEY set. */
  REQUIRE_SIGN_IN?: string;
  /** Requests a signed-in user may make per day (UTC); 100 when unset. */
  DAILY_LIMIT?: string;
  /** KV namespace for the daily counts; without it there is no limit. */
  USAGE?: KVNamespace;
  /** Shown on the Privacy Policy and Terms pages. */
  LEGAL_COMPANY?: string;
  SUPPORT_EMAIL?: string;
}

/** Where answers come from; tests pass fakes. */
export interface Services {
  chat: ReplySource;
  roleplay: RoleplayAI;
  keys: KeySource;
  usage?: UsageStore;
}

/**
 * POST /v1/chat with `{ "turns": [{ "role": "user", "text": "..." }], "learner": { "level": "beginner" } }`.
 * The reply streams back as server-sent events, one JSON `ReplyEvent` per `data:` line, ending
 * with `done` or `error`. Every call needs `Authorization: Bearer <Firebase ID token>`, or the
 * `X-Dolingo-Key` header while builds without Firebase are allowed (see `authorize`).
 */
export async function handle(request: Request, env: Env, services: Services): Promise<Response> {
  const url = new URL(request.url);
  if (url.pathname === "/health") {
    // What the deploy workflow checks: the Worker runs and has its key.
    return env.ANTHROPIC_API_KEY ? new Response("ok") : new Response("missing ANTHROPIC_API_KEY", { status: 503 });
  }
  if (request.method === "GET" && (url.pathname === "/privacy" || url.pathname === "/terms")) {
    const lang = legalLanguage(url, request.headers.get("Accept-Language"));
    const info = { company: env.LEGAL_COMPANY || "Titan Studio", email: env.SUPPORT_EMAIL || "support@example.com" };
    const html = url.pathname === "/privacy" ? privacyPage(lang, info) : termsPage(lang, info);
    return new Response(html, {
      headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "public, max-age=3600" },
    });
  }
  const routes = ["/v1/chat", "/v1/roleplay/draft", "/v1/roleplay/turn"];
  if (!routes.includes(url.pathname)) return json({ error: "not found" }, 404);
  if (request.method !== "POST") return json({ error: "use POST" }, 405);
  const caller = await authorize(request, env, services.keys);
  if (caller instanceof Response) return caller;
  if (caller.uid && services.usage) {
    const count = await services.usage.increment(caller.uid, today());
    if (count > dailyLimit(env)) return json({ error: "limit" }, 429);
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return json({ error: "body must be JSON" }, 400);
  }

  switch (url.pathname) {
    case "/v1/roleplay/draft": {
      const draft = parseDraftRequest(body);
      if (typeof draft === "string") return json({ error: draft }, 400);
      return result(await services.roleplay.draft(draft, request.signal));
    }
    case "/v1/roleplay/turn": {
      const turn = parseTurnRequest(body);
      if (typeof turn === "string") return json({ error: turn }, 400);
      return result(await services.roleplay.turn(turn, request.signal));
    }
    default:
      return chat(body, services.chat, request.signal);
  }
}

/**
 * A valid Firebase ID token gives the user's id; a bad or expired one is a 401 so the app
 * refreshes it and tries again. Without a token, the shared key still works unless
 * REQUIRE_SIGN_IN is "true", for builds that run without Firebase.
 */
export async function authorize(request: Request, env: Env, keys: KeySource): Promise<{ uid: string | null } | Response> {
  const token = /^Bearer\s+(\S+)$/.exec(request.headers.get("Authorization") ?? "")?.[1];
  if (token && env.FIREBASE_PROJECT_ID) {
    try {
      const caller = await verifyFirebaseToken(token, env.FIREBASE_PROJECT_ID, keys);
      return caller ? { uid: caller.uid } : json({ error: "unauthorized" }, 401);
    } catch {
      // Google's keys could not be fetched.
      return json({ error: "unavailable" }, 503);
    }
  }
  const signInOnly = env.REQUIRE_SIGN_IN === "true";
  if (!signInOnly && env.CLIENT_KEY && request.headers.get("X-Dolingo-Key") === env.CLIENT_KEY) {
    return { uid: null };
  }
  return json({ error: "unauthorized" }, 401);
}

function dailyLimit(env: Env): number {
  const limit = Number(env.DAILY_LIMIT);
  return Number.isFinite(limit) && limit > 0 ? limit : 100;
}

/**
 * POST /v1/roleplay/draft and /v1/roleplay/turn answer with the JSON value, or with
 * `{ "error": code }`: 422 when the model declined, 503 when busy, 502 otherwise.
 */
export function result<T>(answer: AIResult<T>): Response {
  if (answer.ok) return json(answer.value, 200);
  return json({ error: answer.code }, STATUS[answer.code]);
}

const STATUS: Record<ReplyErrorCode, number> = { refused: 422, busy: 503, unavailable: 503, failed: 502 };

function chat(body: unknown, source: ReplySource, signal: AbortSignal): Response {
  const chat = parseChatRequest(body);
  if (typeof chat === "string") return json({ error: chat }, 400);

  const encoder = new TextEncoder();
  const events = source.reply(chat, signal);
  const stream = new ReadableStream<Uint8Array>({
    async pull(controller) {
      const next = await events.next();
      if (next.done) {
        controller.close();
        return;
      }
      controller.enqueue(encoder.encode(sse(next.value)));
    },
    async cancel() {
      await events.return(undefined);
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache",
    },
  });
}

export function sse(event: ReplyEvent): string {
  return `data: ${JSON.stringify(event)}\n\n`;
}

function json(value: unknown, status: number): Response {
  return new Response(JSON.stringify(value), { status, headers: { "Content-Type": "application/json" } });
}

/** Kept between requests on the same isolate so Google's keys are fetched only when they change. */
const googleKeys = new GoogleKeys();

export default {
  fetch(request: Request, env: Env): Promise<Response> {
    const claude = new ClaudeReplySource(env.ANTHROPIC_API_KEY);
    return handle(request, env, {
      chat: claude,
      roleplay: claude,
      keys: googleKeys,
      usage: env.USAGE ? new KVUsageStore(env.USAGE) : undefined,
    });
  },
};
