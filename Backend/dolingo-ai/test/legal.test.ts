import assert from "node:assert/strict";
import { test } from "node:test";
import { handle } from "../src/index.ts";
import { legalLanguage, privacyPage, termsPage } from "../src/legal.ts";

const info = { company: "Titan Studio", email: "help@dolingo.app" };

test("serves the policy pages without a key", async () => {
  const services = {
    chat: { async *reply() {} },
    roleplay: { draft: async () => ({ ok: false as const, code: "failed" as const }), turn: async () => ({ ok: false as const, code: "failed" as const }) },
    keys: { keys: async () => [] },
  };
  const env = { ANTHROPIC_API_KEY: "", SUPPORT_EMAIL: "help@dolingo.app" };
  const privacy = await handle(new Request("https://ai.dolingo.test/privacy?lang=en"), env, services);
  assert.equal(privacy.status, 200);
  assert.match(privacy.headers.get("Content-Type") ?? "", /text\/html/);
  const html = await privacy.text();
  assert.match(html, /Privacy Policy/);
  assert.match(html, /help@dolingo\.app/);
  const terms = await handle(new Request("https://ai.dolingo.test/terms", { headers: { "Accept-Language": "vi-VN" } }), env, services);
  assert.match(await terms.text(), /Điều khoản sử dụng/);
});

test("both languages cover the same sections", () => {
  for (const page of [privacyPage, termsPage]) {
    const count = (html: string) => (html.match(/<h2>/g) ?? []).length;
    assert.equal(count(page("vi", info)), count(page("en", info)));
  }
  assert.match(termsPage("en", info), /auto-renewable/);
  assert.match(privacyPage("vi", info), /Xoá tài khoản/);
});

test("picks the language from the link, then the browser", () => {
  assert.equal(legalLanguage(new URL("https://x/privacy?lang=en"), "vi"), "en");
  assert.equal(legalLanguage(new URL("https://x/privacy"), "en-US,en;q=0.9"), "en");
  assert.equal(legalLanguage(new URL("https://x/privacy"), null), "vi");
});
