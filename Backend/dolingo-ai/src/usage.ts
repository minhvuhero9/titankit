// How many AI requests each user made today, to cap the cost of one account.

export interface UsageStore {
  /** Adds one request for `uid` today and returns the new count. */
  increment(uid: string, day: string): Promise<number>;
}

/** Counts in Cloudflare KV, one key per user and day that expires after two days. */
export class KVUsageStore implements UsageStore {
  private readonly kv: KVNamespace;

  constructor(kv: KVNamespace) {
    this.kv = kv;
  }

  async increment(uid: string, day: string): Promise<number> {
    // KV has no atomic increment; a few requests racing past the limit is acceptable here.
    const key = `usage:${day}:${uid}`;
    const count = Number((await this.kv.get(key)) ?? "0") + 1;
    await this.kv.put(key, String(count), { expirationTtl: 2 * 24 * 3600 });
    return count;
  }
}

/** In memory, for tests. */
export class MemoryUsageStore implements UsageStore {
  readonly counts = new Map<string, number>();

  async increment(uid: string, day: string): Promise<number> {
    const key = `${day}:${uid}`;
    const count = (this.counts.get(key) ?? 0) + 1;
    this.counts.set(key, count);
    return count;
  }
}

/** "2026-10-30" in UTC. */
export function today(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10);
}
