import { parseChatRequest } from "./chat.ts";
import { type AIResult, ClaudeReplySource, type ReplyErrorCode, type ReplyEvent, type ReplySource, type RoleplayAI } from "./claude.ts";
import { parseDraftRequest, parseTurnRequest } from "./roleplay.ts";

export interface Env {
  /** Set with `wrangler secret put ANTHROPIC_API_KEY`. */
  ANTHROPIC_API_KEY: string;
  /** Shared with the app (AppConfig.aiClientKey) so random callers can't spend the API key. */
  CLIENT_KEY: string;
}

/** Where answers come from; tests pass fakes. */
export interface Services {
  chat: ReplySource;
  roleplay: RoleplayAI;
}

/**
 * POST /v1/chat with `{ "turns": [{ "role": "user", "text": "..." }], "learner": { "level": "beginner" } }`
 * and the header `X-Dolingo-Key`. The reply streams back as server-sent events, one JSON
 * `ReplyEvent` per `data:` line, ending with `done` or `error`.
 */
export async function handle(request: Request, env: Env, services: Services): Promise<Response> {
  const url = new URL(request.url);
  if (url.pathname === "/health") return new Response("ok");
  const routes = ["/v1/chat", "/v1/roleplay/draft", "/v1/roleplay/turn"];
  if (!routes.includes(url.pathname)) return json({ error: "not found" }, 404);
  if (request.method !== "POST") return json({ error: "use POST" }, 405);
  if (!env.CLIENT_KEY || request.headers.get("X-Dolingo-Key") !== env.CLIENT_KEY) {
    return json({ error: "unauthorized" }, 401);
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

export default {
  fetch(request: Request, env: Env): Promise<Response> {
    const claude = new ClaudeReplySource(env.ANTHROPIC_API_KEY);
    return handle(request, env, { chat: claude, roleplay: claude });
  },
};
