// Who is calling: a Firebase ID token in `Authorization: Bearer`, checked against Google's
// public keys the way the Firebase Admin SDK does, without the SDK (it doesn't run on Workers).

export interface Caller {
  /** The Firebase user id. */
  uid: string;
  /** Signed in as a guest. */
  anonymous: boolean;
}

/** A public key from Google's JWK set, with its key id. */
export type SigningKey = JsonWebKey & { kid: string };

/** Where the signing keys come from; tests pass their own. */
export interface KeySource {
  keys(): Promise<SigningKey[]>;
}

const GOOGLE_KEYS_URL = "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com";

/** Google's keys, kept until the time its Cache-Control allows (keys rotate every few hours). */
export class GoogleKeys implements KeySource {
  private cached: SigningKey[] = [];
  private expiresAt = 0;
  private readonly fetcher: typeof fetch;

  constructor(fetcher: typeof fetch = fetch) {
    this.fetcher = fetcher;
  }

  async keys(): Promise<SigningKey[]> {
    if (this.cached.length > 0 && Date.now() < this.expiresAt) return this.cached;
    const response = await this.fetcher(GOOGLE_KEYS_URL);
    if (!response.ok) throw new Error(`Google keys: HTTP ${response.status}`);
    const body = (await response.json()) as { keys?: SigningKey[] };
    this.cached = body.keys ?? [];
    const maxAge = /max-age=(\d+)/.exec(response.headers.get("Cache-Control") ?? "")?.[1];
    this.expiresAt = Date.now() + (maxAge ? Number(maxAge) : 3600) * 1000;
    return this.cached;
  }
}

/** Seconds of clock difference allowed between Google and this server. */
const CLOCK_SKEW = 60;

/**
 * The caller when `token` is a valid Firebase ID token for `projectId`, otherwise null:
 * RS256 signed by one of Google's current keys, issued for this project, not expired.
 */
export async function verifyFirebaseToken(
  token: string,
  projectId: string,
  keys: KeySource,
  now: number = Date.now() / 1000,
): Promise<Caller | null> {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [headerPart, payloadPart, signaturePart] = parts;

  const header = decodeJSON(headerPart) as { alg?: string; kid?: string } | null;
  const payload = decodeJSON(payloadPart) as {
    iss?: string;
    aud?: string;
    sub?: string;
    exp?: number;
    iat?: number;
    auth_time?: number;
    firebase?: { sign_in_provider?: string };
  } | null;
  if (!header || !payload || header.alg !== "RS256" || !header.kid) return null;

  if (payload.aud !== projectId || payload.iss !== `https://securetoken.google.com/${projectId}`) return null;
  if (typeof payload.sub !== "string" || payload.sub === "" || payload.sub.length > 128) return null;
  if (typeof payload.exp !== "number" || payload.exp + CLOCK_SKEW < now) return null;
  if (typeof payload.iat !== "number" || payload.iat - CLOCK_SKEW > now) return null;
  if (typeof payload.auth_time === "number" && payload.auth_time - CLOCK_SKEW > now) return null;

  const jwk = (await keys.keys()).find((key) => key.kid === header.kid);
  if (!jwk) return null;
  const key = await crypto.subtle.importKey(
    "jwk",
    { kty: jwk.kty, n: jwk.n, e: jwk.e, alg: "RS256", ext: true },
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const signature = base64urlBytes(signaturePart);
  if (!signature) return null;
  const signed = new TextEncoder().encode(`${headerPart}.${payloadPart}`);
  const valid = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", key, signature, signed);
  if (!valid) return null;

  return { uid: payload.sub, anonymous: payload.firebase?.sign_in_provider === "anonymous" };
}

function decodeJSON(part: string): unknown {
  const bytes = base64urlBytes(part);
  if (!bytes) return null;
  try {
    return JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    return null;
  }
}

export function base64urlBytes(text: string): Uint8Array<ArrayBuffer> | null {
  if (!/^[A-Za-z0-9_-]*$/.test(text)) return null;
  const base64 = text.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (text.length % 4)) % 4);
  try {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    return bytes;
  } catch {
    return null;
  }
}
