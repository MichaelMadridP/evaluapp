import type { RateLimitStore } from './types';

export const DAILY_SEND_LIMIT = 10;

export async function consumeDailyQuota(
  store: RateLimitStore,
  uid: string,
  now = new Date(),
): Promise<boolean> {
  const day = now.toISOString().slice(0, 10);
  const key = `email-send:${day}:${uid}`;
  const current = Number.parseInt((await store.get(key)) ?? '0', 10) || 0;
  if (current >= DAILY_SEND_LIMIT) {
    return false;
  }

  const nextDay = new Date(`${day}T00:00:00.000Z`);
  nextDay.setUTCDate(nextDay.getUTCDate() + 1);
  const secondsUntilExpiry = Math.max(
    60,
    Math.ceil((nextDay.getTime() - now.getTime()) / 1000) + 3600,
  );
  await store.put(key, String(current + 1), {
    expirationTtl: secondsUntilExpiry,
  });
  return true;
}
