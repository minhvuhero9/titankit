import assert from "node:assert/strict";
import { test } from "node:test";
import type { ChatRequest } from "../src/chat.ts";
import type { AIResult, ReplyEvent, ReplySource, RoleplayAI } from "../src/claude.ts";
import { handle, type Services } from "../src/index.ts";
import type { Draft, DraftRequest, Turn, TurnRequest } from "../src/roleplay.ts";

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

class FakeRoleplay implements RoleplayAI {
  drafts: DraftRequest[] = [];
  turns: TurnRequest[] = [];
  draftResult: AIResult<Draft> = {
    ok: true,
    value: { emoji: "🍕", title: "Ordering Pizza", myRole: "Customer", aiRole: "Waiter", scenario: "You order.", tasks: [] },
  };
  turnResult: AIResult<Turn> = { ok: false, code: "refused" };
  async draft(request: DraftRequest): Promise<AIResult<Draft>> {
    this.drafts.push(request);
    return this.draftResult;
  }
  async turn(request: TurnRequest): Promise<AIResult<Turn>> {
    this.turns.push(request);
    return this.turnResult;
  }
}

function services(chat: ReplySource = new FakeSource([]), roleplay: RoleplayAI = new FakeRoleplay()): Services {
  return { chat, roleplay };
}

function post(path: string, body: unknown, key = "secret"): Request {
  return new Request(`https://ai.dolingo.test${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Dolingo-Key": key },
    body: JSON.stringify(body),
  });
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
  const response = await handle(chat({ turns: [{ role: "user", text: "Hi" }] }), env, services(source));
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
  const response = await handle(chat({ turns: [{ role: "user", text: "Hi" }] }, "wrong"), env, services());
  assert.equal(response.status, 401);
});

test("rejects bad requests before calling the model", async () => {
  const source = new FakeSource([]);
  const response = await handle(chat({ turns: [] }), env, services(source));
  assert.equal(response.status, 400);
  assert.equal(source.requests.length, 0);
});

test("only POST /v1/chat", async () => {
  const get = await handle(new Request("https://ai.dolingo.test/v1/chat"), env, services());
  assert.equal(get.status, 405);
  const other = await handle(new Request("https://ai.dolingo.test/v1/other", { method: "POST" }), env, services());
  assert.equal(other.status, 404);
  const health = await handle(new Request("https://ai.dolingo.test/health"), env, services());
  assert.equal(await health.text(), "ok");
});

test("drafts a roleplay from the form", async () => {
  const roleplay = new FakeRoleplay();
  const response = await handle(
    post("/v1/roleplay/draft", { title: " Ordering Pizza ", myRole: "", withGoals: true }),
    env,
    services(undefined, roleplay),
  );
  assert.equal(response.status, 200);
  assert.equal(((await response.json()) as Draft).emoji, "🍕");
  assert.equal(roleplay.drafts[0].title, "Ordering Pizza");
  assert.equal(roleplay.drafts[0].withGoals, true);
});

test("a declined turn is a 422", async () => {
  const roleplay = new FakeRoleplay();
  const setup = { title: "Pizza", myRole: "Customer", aiRole: "Waiter", scenario: "You order.", tasks: [{ id: "t1", text: "Order" }] };
  const response = await handle(post("/v1/roleplay/turn", { roleplay: setup, turns: [] }), env, services(undefined, roleplay));
  assert.equal(response.status, 422);
  assert.deepEqual(await response.json(), { error: "refused" });
  assert.equal(roleplay.turns[0].roleplay.tasks[0].id, "t1");
});

test("a turn needs the roleplay set up", async () => {
  const response = await handle(post("/v1/roleplay/turn", { roleplay: { title: "x" }, turns: [] }), env, services());
  assert.equal(response.status, 400);
});
