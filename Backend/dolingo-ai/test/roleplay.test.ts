import assert from "node:assert/strict";
import { test } from "node:test";
import { parseDraftRequest, parseTurnRequest, ROLEPLAY_LIMITS } from "../src/roleplay.ts";
import { roleplayContext } from "../src/prompts.ts";

const setup = { title: "Pizza", myRole: "Customer", aiRole: "Waiter", scenario: "You order a pizza.", tasks: [{ id: "t1", text: "Ask the price" }] };

test("an empty form is fine: the AI invents a roleplay", () => {
  const draft = parseDraftRequest({});
  if (typeof draft === "string") assert.fail(draft);
  assert.equal(draft.title, "");
  assert.equal(draft.withGoals, false);
});

test("draft fields must be short strings", () => {
  assert.equal(typeof parseDraftRequest({ title: 3 }), "string");
  assert.equal(typeof parseDraftRequest({ scenario: "x".repeat(ROLEPLAY_LIMITS.maxScenarioChars + 1) }), "string");
});

test("the AI opens, then turns alternate and end with the learner", () => {
  const opening = parseTurnRequest({ roleplay: setup, turns: [] });
  assert.equal(typeof opening, "object");
  const next = parseTurnRequest({
    roleplay: setup,
    turns: [
      { role: "assistant", text: "Hi! What can I get you?" },
      { role: "user", text: "A pizza, please." },
    ],
  });
  if (typeof next === "string") assert.fail(next);
  assert.equal(next.turns.length, 2);
  assert.equal(typeof parseTurnRequest({ roleplay: setup, turns: [{ role: "assistant", text: "Hi" }] }), "string");
  assert.equal(
    typeof parseTurnRequest({ roleplay: setup, turns: [{ role: "user", text: "a" }, { role: "user", text: "b" }] }),
    "string",
  );
});

test("the context lists the tasks with their ids", () => {
  const context = roleplayContext(setup);
  assert.match(context, /Your role: Waiter/);
  assert.match(context, /- t1: Ask the price/);
});
