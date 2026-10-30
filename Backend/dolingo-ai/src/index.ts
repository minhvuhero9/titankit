import { parseChatRequest } from "./chat.ts";
import { ClaudeReplySource, type ReplyEvent, type ReplySource } from "./claude.ts";

export interface Env {
  /** Set with `wrangler secret put ANTHROPIC_API_KEY`. */
  ANTHROPIC_API_KEY: string;
  /** Shared with the app (AppConfig.aiClientKey) so random callers can't spend the API key. */
  CLIENT_KEY: string;
}

/**
 * POST /v1/chat with `{ "turns": [{ "role": "user", "text": "..." }], "learner": { "level": "beginner" } }`
 * and the header `X-Dolingo-Key`. The reply streams back as server-sent events, one JSON
 * `ReplyEvent` per `data:` line, ending with `done` or `error`.
 */
export async function handle(request: Request, env: Env, source: ReplySource): Promise<Response> {
  const url = new URL(request.url);
  if (url.pathname === "/health") return new Response("ok");
  if (url.pathname !== "/v1/chat") return json({ error: "not found" }, 404);
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
  const chat = parseChatRequest(body);
  if (typeof chat === "string") return json({ error: chat }, 400);

  const encoder = new TextEncoder();
  const events = source.reply(chat, request.signal);
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
    return handle(request, env, new ClaudeReplySource(env.ANTHROPIC_API_KEY));
  },
};
