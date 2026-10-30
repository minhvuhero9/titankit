import assert from "node:assert/strict";
import { test } from "node:test";
import type { ChatRequest } from "../src/chat.ts";
import type { ReplyEvent, ReplySource } from "../src/claude.ts";
import { handle } from "../src/index.ts";

const env = { ANTHROPIC_API_KEY: "unused", CLIENT_KEY: "secret" };

class FakeSource implements ReplySource {
  requests: ChatRequest[] = [];
  private readonly events: ReplyEvent[];
  constructor(events: ReplyEvent[]) {
    this.events = events;
  }
  async *reply(request: ChatRequest): AsyncGenerator<ReplyEvent> {
    this.requests.push(request);
    yield* this.events;
  }
}

function chat(body: unknown, key = "secret"): Request {
  return new Request("https://ai.dolingo.test/v1/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Dolingo-Key": key },
    body: JSON.stringify(body),
  });
}

test("streams the reply as server-sent events", async () => {
  const source = new FakeSource([
    { type: "text", text: "Hello" },
    { type: "text", text: "!" },
    { type: "done" },
  ]);
  const response = await handle(chat({ turns: [{ role: "user", text: "Hi" }] }), env, source);
  assert.equal(response.status, 200);
  assert.match(response.headers.get("Content-Type") ?? "", /text\/event-stream/);
  const body = await response.text();
  assert.equal(
    body,
    'data: {"type":"text","text":"Hello"}\n\ndata: {"type":"text","text":"!"}\n\ndata: {"type":"done"}\n\n',
  );
  assert.equal(source.requests[0].turns[0].text, "Hi");
});

test("needs the client key", async () => {
  const response = await handle(chat({ turns: [{ role: "user", text: "Hi" }] }, "wrong"), env, new FakeSource([]));
  assert.equal(response.status, 401);
});

test("rejects bad requests before calling the model", async () => {
  const source = new FakeSource([]);
  const response = await handle(chat({ turns: [] }), env, source);
  assert.equal(response.status, 400);
  assert.equal(source.requests.length, 0);
});

test("only POST /v1/chat", async () => {
  const get = await handle(new Request("https://ai.dolingo.test/v1/chat"), env, new FakeSource([]));
  assert.equal(get.status, 405);
  const other = await handle(new Request("https://ai.dolingo.test/v1/other", { method: "POST" }), env, new FakeSource([]));
  assert.equal(other.status, 404);
  const health = await handle(new Request("https://ai.dolingo.test/health"), env, new FakeSource([]));
  assert.equal(await health.text(), "ok");
});
