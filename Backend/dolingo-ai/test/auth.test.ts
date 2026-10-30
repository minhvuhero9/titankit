import assert from "node:assert/strict";
import { test } from "node:test";
import { base64urlBytes, type SigningKey, verifyFirebaseToken } from "../src/auth.ts";
import type { ReplyEvent, ReplySource } from "../src/claude.ts";
import { handle } from "../src/index.ts";
import { MemoryUsageStore } from "../src/usage.ts";

const PROJECT = "dolingo-test";
const NOW = 1_800_000_000;

const pair = (await crypto.subtle.generateKey(
  { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
  true,
  ["sign", "verify"],
)) as CryptoKeyPair;
const publicJwk = { ...(await crypto.subtle.exportKey("jwk", pair.publicKey)), kid: "key-1" } as SigningKey;
const keys = { keys: async () => [publicJwk] };

function base64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function token(claims: Record<string, unknown> = {}, header: Record<string, unknown> = {}): Promise<string> {
  const head = base64url(JSON.stringify({ alg: "RS256", kid: "key-1", typ: "JWT", ...header }));
  const body = base64url(JSON.stringify({
    iss: `https://securetoken.google.com/${PROJECT}`,
    aud: PROJECT,
    sub: "user-1",
    iat: NOW - 10,
    exp: NOW + 3600,
    auth_time: NOW - 10,
    firebase: { sign_in_provider: "password" },
    ...claims,
  }));
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", pair.privateKey, new TextEncoder().encode(`${head}.${body}`));
  return `${head}.${body}.${base64url(new Uint8Array(signature))}`;
}

test("accepts a token Google's key signed for this project", async () => {
  const caller = await verifyFirebaseToken(await token(), PROJECT, keys, NOW);
  assert.deepEqual(caller, { uid: "user-1", anonymous: false });
  const guest = await verifyFirebaseToken(await token({ firebase: { sign_in_provider: "anonymous" } }), PROJECT, keys, NOW);
  assert.equal(guest?.anonymous, true);
});

test("rejects tokens for another project, expired, from the future or tampered with", async () => {
  assert.equal(await verifyFirebaseToken(await token({ aud: "other" }), PROJECT, keys, NOW), null);
  assert.equal(await verifyFirebaseToken(await token({ iss: "https://evil.example" }), PROJECT, keys, NOW), null);
  assert.equal(await verifyFirebaseToken(await token({ exp: NOW - 3600 }), PROJECT, keys, NOW), null);
  assert.equal(await verifyFirebaseToken(await token({ iat: NOW + 3600 }), PROJECT, keys, NOW), null);
  assert.equal(await verifyFirebaseToken(await token({ sub: "" }), PROJECT, keys, NOW), null);
  assert.equal(await verifyFirebaseToken(await token({}, { alg: "none" }), PROJECT, keys, NOW), null);
  assert.equal(await verifyFirebaseToken(await token({}, { kid: "unknown" }), PROJECT, keys, NOW), null);

  const [head, , signature] = (await token()).split(".");
  const forged = base64url(JSON.stringify({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, sub: "admin", iat: NOW, exp: NOW + 60 }));
  assert.equal(await verifyFirebaseToken(`${head}.${forged}.${signature}`, PROJECT, keys, NOW), null);
  assert.equal(await verifyFirebaseToken("not-a-token", PROJECT, keys, NOW), null);
});

test("base64url decoding refuses other alphabets", () => {
  assert.deepEqual(base64urlBytes("aGk"), new Uint8Array([104, 105]));
  assert.equal(base64urlBytes("a+b/"), null);
});

class Done implements ReplySource {
  async *reply(): AsyncGenerator<ReplyEvent> {
    yield { type: "done" };
  }
}

const roleplay = { draft: async () => ({ ok: false as const, code: "failed" as const }), turn: async () => ({ ok: false as const, code: "failed" as const }) };

function chat(headers: Record<string, string>): Request {
  return new Request("https://ai.dolingo.test/v1/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body: JSON.stringify({ turns: [{ role: "user", text: "Hi" }] }),
  });
}

test("the server lets signed-in users in and counts their requests", async () => {
  // The real clock: the token must be valid now.
  const now = Math.floor(Date.now() / 1000);
  const valid = await token({ iat: now - 10, exp: now + 3600, auth_time: now - 10 });
  const usage = new MemoryUsageStore();
  const env = { ANTHROPIC_API_KEY: "", FIREBASE_PROJECT_ID: PROJECT, DAILY_LIMIT: "2" };
  const services = { chat: new Done(), roleplay, keys, usage };

  for (let i = 0; i < 2; i++) {
    const response = await handle(chat({ Authorization: `Bearer ${valid}` }), env, services);
    assert.equal(response.status, 200);
    await response.text();
  }
  const third = await handle(chat({ Authorization: `Bearer ${valid}` }), env, services);
  assert.equal(third.status, 429);
  assert.deepEqual(await third.json(), { error: "limit" });

  const expired = await token({ iat: now - 7200, exp: now - 3600 });
  assert.equal((await handle(chat({ Authorization: `Bearer ${expired}` }), env, services)).status, 401);
});

test("the shared key works until sign-in is required", async () => {
  const services = { chat: new Done(), roleplay, keys };
  const open = { ANTHROPIC_API_KEY: "", FIREBASE_PROJECT_ID: PROJECT, CLIENT_KEY: "secret" };
  assert.equal((await handle(chat({ "X-Dolingo-Key": "secret" }), open, services)).status, 200);
  assert.equal((await handle(chat({}), open, services)).status, 401);
  const closed = { ...open, REQUIRE_SIGN_IN: "true" };
  assert.equal((await handle(chat({ "X-Dolingo-Key": "secret" }), closed, services)).status, 401);
});

test("an unreachable key server is a 503, not a 401", async () => {
  const now = Math.floor(Date.now() / 1000);
  const valid = await token({ iat: now - 10, exp: now + 3600, auth_time: now - 10 });
  const broken = { keys: async () => { throw new Error("offline"); } };
  const response = await handle(chat({ Authorization: `Bearer ${valid}` }),
    { ANTHROPIC_API_KEY: "", FIREBASE_PROJECT_ID: PROJECT }, { chat: new Done(), roleplay, keys: broken });
  assert.equal(response.status, 503);
});

test("Google's keys are fetched once and kept while Cache-Control allows", async () => {
  const { GoogleKeys } = await import("../src/auth.ts");
  let calls = 0;
  const fetcher = (async () => {
    calls += 1;
    return new Response(JSON.stringify({ keys: [publicJwk] }), { headers: { "Cache-Control": "public, max-age=21600" } });
  }) as unknown as typeof fetch;
  const google = new GoogleKeys(fetcher);
  assert.equal((await google.keys())[0].kid, "key-1");
  await google.keys();
  assert.equal(calls, 1);
});
