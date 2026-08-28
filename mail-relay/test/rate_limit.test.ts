import { describe, expect, it } from 'vitest';
import { consumeDailyQuota, DAILY_SEND_LIMIT } from '../src/rate_limit';
import type { RateLimitStore } from '../src/types';

class MemoryStore implements RateLimitStore {
  values = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.values.get(key) ?? null;
  }

  async put(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

describe('daily rate limit', () => {
  it('permite al usuario bajo el límite', async () => {
    const store = new MemoryStore();
    await expect(
      consumeDailyQuota(store, 'user-a', new Date('2026-08-26T12:00:00Z')),
    ).resolves.toBe(true);
  });

  it('bloquea al usuario que alcanzó el límite', async () => {
    const store = new MemoryStore();
    for (let i = 0; i < DAILY_SEND_LIMIT; i++) {
      expect(
        await consumeDailyQuota(
          store,
          'user-a',
          new Date('2026-08-26T12:00:00Z'),
        ),
      ).toBe(true);
    }
    await expect(
      consumeDailyQuota(store, 'user-a', new Date('2026-08-26T12:00:00Z')),
    ).resolves.toBe(false);
  });

  it('mantiene contadores independientes por usuario', async () => {
    const store = new MemoryStore();
    for (let i = 0; i < DAILY_SEND_LIMIT; i++) {
      await consumeDailyQuota(
        store,
        'user-a',
        new Date('2026-08-26T12:00:00Z'),
      );
    }
    await expect(
      consumeDailyQuota(store, 'user-b', new Date('2026-08-26T12:00:00Z')),
    ).resolves.toBe(true);
  });
});
