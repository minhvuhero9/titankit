import assert from "node:assert/strict";
import { test } from "node:test";
import { LIMITS, parseChatRequest } from "../src/chat.ts";
import { learnerContext } from "../src/prompts.ts";

test("accepts alternating turns that end with the user", () => {
  const parsed = parseChatRequest({
    turns: [
      { role: "user", text: "Hi" },
      { role: "assistant", text: "Hello!" },
      { role: "user", text: "How do I say cảm ơn?" },
    ],
    learner: { name: " An ", level: "beginner" },
  });
  assert.equal(typeof parsed, "object");
  if (typeof parsed === "string") return;
  assert.equal(parsed.turns.length, 3);
  assert.deepEqual(parsed.learner, { name: "An", level: "beginner" });
});

test("rejects bad shapes", () => {
  assert.equal(typeof parseChatRequest(null), "string");
  assert.equal(typeof parseChatRequest({ turns: [] }), "string");
  assert.equal(typeof parseChatRequest({ turns: [{ role: "system", text: "x" }] }), "string");
  assert.equal(typeof parseChatRequest({ turns: [{ role: "user", text: "  " }] }), "string");
  assert.equal(typeof parseChatRequest({ turns: [{ role: "user", text: "a" }, { role: "assistant", text: "b" }] }), "string");
  assert.equal(typeof parseChatRequest({ turns: [{ role: "user", text: "a" }, { role: "user", text: "b" }] }), "string");
  assert.equal(typeof parseChatRequest({ turns: [{ role: "user", text: "x".repeat(LIMITS.maxCharsPerTurn + 1) }] }), "string");
});

test("cuts long tutor replies instead of refusing them", () => {
  const parsed = parseChatRequest({
    turns: [
      { role: "user", text: "Tell me a story" },
      { role: "assistant", text: "x".repeat(LIMITS.maxCharsPerReply + 50) },
      { role: "user", text: "Thanks" },
    ],
  });
  if (typeof parsed === "string") assert.fail(parsed);
  assert.equal(parsed.turns[1].text.length, LIMITS.maxCharsPerReply);
});

test("keeps the latest turns and starts on a user turn", () => {
  const turns = Array.from({ length: LIMITS.maxTurns + 2 }, (_, i) => ({
    role: i % 2 === 0 ? "user" : "assistant",
    text: `turn ${i}`,
  }));
  turns.push({ role: "user", text: "last" });
  const parsed = parseChatRequest({ turns });
  if (typeof parsed === "string") assert.fail(parsed);
  assert.ok(parsed.turns.length <= LIMITS.maxTurns);
  assert.equal(parsed.turns[0].role, "user");
  assert.equal(parsed.turns.at(-1)?.text, "last");
});

test("ignores unknown levels and empty names", () => {
  const parsed = parseChatRequest({ turns: [{ role: "user", text: "Hi" }], learner: { name: " ", level: "expert" } });
  if (typeof parsed === "string") assert.fail(parsed);
  assert.deepEqual(parsed.learner, {});
  assert.equal(learnerContext(parsed.learner), null);
  assert.match(learnerContext({ level: "advanced" }) ?? "", /advanced/);
});
