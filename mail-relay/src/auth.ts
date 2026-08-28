import { importX509, jwtVerify, type CryptoKey } from 'jose';
import type { VerifiedFirebaseUser } from './types';

const FIREBASE_CERTIFICATES_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

interface CertificateCache {
  keys: Map<string, CryptoKey>;
  expiresAt: number;
}

let certificateCache: CertificateCache | undefined;

export type FirebaseKeyResolver = (kid: string) => Promise<CryptoKey>;

export async function verifyFirebaseIdToken(
  token: string,
  projectId: string,
  keyResolver: FirebaseKeyResolver = getFirebasePublicKey,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<VerifiedFirebaseUser> {
  if (!projectId || projectId.startsWith('REPLACE_WITH_')) {
    throw new Error('Firebase project is not configured.');
  }

  const { payload, protectedHeader } = await jwtVerify(
    token,
    async (header) => {
      if (header.alg !== 'RS256' || !header.kid) {
        throw new Error('Invalid Firebase token header.');
      }
      return keyResolver(header.kid);
    },
    {
      algorithms: ['RS256'],
      audience: projectId,
      issuer: `https://securetoken.google.com/${projectId}`,
      currentDate: new Date(nowSeconds * 1000),
    },
  );

  if (protectedHeader.alg !== 'RS256' || !protectedHeader.kid) {
    throw new Error('Invalid Firebase token header.');
  }
  if (
    typeof payload.sub !== 'string' ||
    payload.sub.length === 0 ||
    payload.sub.length > 128
  ) {
    throw new Error('Invalid Firebase token subject.');
  }
  if (typeof payload.iat !== 'number' || payload.iat > nowSeconds) {
    throw new Error('Invalid Firebase token issued-at time.');
  }
  if (typeof payload.exp !== 'number' || payload.exp <= nowSeconds) {
    throw new Error('Invalid Firebase token expiration time.');
  }
  if (
    typeof payload.auth_time !== 'number' ||
    payload.auth_time > nowSeconds
  ) {
    throw new Error('Invalid Firebase authentication time.');
  }

  return { uid: payload.sub };
}

async function getFirebasePublicKey(kid: string): Promise<CryptoKey> {
  let cache = await loadCertificates(false);
  let key = cache.keys.get(kid);
  if (!key) {
    cache = await loadCertificates(true);
    key = cache.keys.get(kid);
  }
  if (!key) {
    throw new Error('Unknown Firebase signing key.');
  }
  return key;
}

async function loadCertificates(forceRefresh: boolean): Promise<CertificateCache> {
  const now = Date.now();
  if (!forceRefresh && certificateCache && certificateCache.expiresAt > now) {
    return certificateCache;
  }

  const response = await fetch(FIREBASE_CERTIFICATES_URL, {
    headers: { Accept: 'application/json' },
  });
  if (!response.ok) {
    throw new Error('Unable to load Firebase certificates.');
  }

  const certificates = (await response.json()) as Record<string, unknown>;
  const keys = new Map<string, CryptoKey>();
  for (const [kid, certificate] of Object.entries(certificates)) {
    if (typeof certificate === 'string') {
      keys.set(kid, await importX509(certificate, 'RS256'));
    }
  }
  if (keys.size === 0) {
    throw new Error('Firebase returned no usable certificates.');
  }

  const maxAgeSeconds = parseMaxAge(response.headers.get('cache-control'));
  certificateCache = {
    keys,
    expiresAt: now + maxAgeSeconds * 1000,
  };
  return certificateCache;
}

function parseMaxAge(cacheControl: string | null): number {
  const match = cacheControl?.match(/(?:^|,)\s*max-age=(\d+)/i);
  const parsed = match ? Number.parseInt(match[1], 10) : Number.NaN;
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 3600;
}
