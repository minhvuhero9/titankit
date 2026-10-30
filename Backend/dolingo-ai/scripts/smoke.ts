// Checks a deployed Worker without spending AI credit: node scripts/smoke.ts https://dolingo-ai.<account>.workers.dev
// Exits non-zero, listing what failed, when the server is not ready for the app.

export {};

const base = process.argv[2]?.replace(/\/+$/, "");
if (!base) {
  console.error("usage: node --experimental-strip-types scripts/smoke.ts <server URL>");
  process.exit(2);
}

const failures: string[] = [];

async function check(name: string, run: () => Promise<string | null>): Promise<void> {
  try {
    const problem = await run();
    if (problem) failures.push(`${name}: ${problem}`);
    console.log(`${problem ? "✗" : "✓"} ${name}${problem ? ` (${problem})` : ""}`);
  } catch (error) {
    failures.push(`${name}: ${String(error)}`);
    console.log(`✗ ${name} (${String(error)})`);
  }
}

await check("GET /health answers ok", async () => {
  const response = await fetch(`${base}/health`);
  const text = await response.text();
  return response.ok && text === "ok" ? null : `HTTP ${response.status} ${text}`;
});

for (const page of ["/privacy", "/terms", "/privacy?lang=en", "/terms?lang=en"]) {
  await check(`GET ${page} is a page`, async () => {
    const response = await fetch(`${base}${page}`);
    const type = response.headers.get("Content-Type") ?? "";
    return response.ok && type.startsWith("text/html") ? null : `HTTP ${response.status} ${type}`;
  });
}

await check("POST /v1/chat without a token is refused", async () => {
  const response = await fetch(`${base}/v1/chat`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ turns: [{ role: "user", text: "Hi" }] }),
  });
  return response.status === 401 ? null : `HTTP ${response.status}, expected 401`;
});

if (failures.length > 0) {
  console.error(`\n${failures.length} check(s) failed.`);
  process.exit(1);
}
console.log("\nThe server is ready.");
