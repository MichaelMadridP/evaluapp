import {
  exportJWK,
  generateKeyPair,
  importJWK,
  SignJWT,
  type CryptoKey,
} from 'jose';
import { beforeAll, describe, expect, it } from 'vitest';
import { verifyFirebaseIdToken } from '../src/auth';

const projectId = 'evaluapp-test';
const issuer = `https://securetoken.google.com/${projectId}`;
const now = 1_800_000_000;
let privateKey: CryptoKey;
let publicKey: CryptoKey;

beforeAll(async () => {
  const pair = await generateKeyPair('RS256', { extractable: true });
  privateKey = pair.privateKey;
  const jwk = await exportJWK(pair.publicKey);
  publicKey = (await importJWK({ ...jwk, alg: 'RS256' }, 'RS256')) as CryptoKey;
});

async function token(
  overrides: Partial<{
    subject: string;
    audience: string;
    issuer: string;
    issuedAt: number;
    expiration: number;
    authTime: number;
  }> = {},
  signingKey = privateKey,
): Promise<string> {
  const issuedAt = overrides.issuedAt ?? now - 60;
  return new SignJWT({ auth_time: overrides.authTime ?? issuedAt })
    .setProtectedHeader({ alg: 'RS256', kid: 'test-key' })
    .setSubject(overrides.subject ?? 'user-123')
    .setAudience(overrides.audience ?? projectId)
    .setIssuer(overrides.issuer ?? issuer)
    .setIssuedAt(issuedAt)
    .setExpirationTime(overrides.expiration ?? now + 3600)
    .sign(signingKey);
}

const resolver = async () => publicKey;

describe('Firebase ID token verification', () => {
  it('rechaza un JWT mal formado', async () => {
    await expect(
      verifyFirebaseIdToken('not-a-jwt', projectId, resolver, now),
    ).rejects.toThrow();
  });

  it('rechaza un JWT expirado', async () => {
    await expect(
      verifyFirebaseIdToken(
        await token({ expiration: now - 1 }),
        projectId,
        resolver,
        now,
      ),
    ).rejects.toThrow();
  });

  it('rechaza un JWT sin exp', async () => {
    const issuedAt = now - 60;
    const value = await new SignJWT({ auth_time: issuedAt })
      .setProtectedHeader({ alg: 'RS256', kid: 'test-key' })
      .setSubject('user-123')
      .setAudience(projectId)
      .setIssuer(issuer)
      .setIssuedAt(issuedAt)
      .sign(privateKey);

    await expect(
      verifyFirebaseIdToken(value, projectId, resolver, now),
    ).rejects.toThrow();
  });

  it('rechaza una firma inválida', async () => {
    const otherPair = await generateKeyPair('RS256');
    await expect(
      verifyFirebaseIdToken(
        await token({}, otherPair.privateKey),
        projectId,
        resolver,
        now,
      ),
    ).rejects.toThrow();
  });

  it('rechaza aud incorrecto', async () => {
    await expect(
      verifyFirebaseIdToken(
        await token({ audience: 'other-project' }),
        projectId,
        resolver,
        now,
      ),
    ).rejects.toThrow();
  });

  it('rechaza iss incorrecto', async () => {
    await expect(
      verifyFirebaseIdToken(
        await token({ issuer: 'https://issuer.invalid' }),
        projectId,
        resolver,
        now,
      ),
    ).rejects.toThrow();
  });

  it('rechaza iat futuro', async () => {
    await expect(
      verifyFirebaseIdToken(
        await token({ issuedAt: now + 60 }),
        projectId,
        resolver,
        now,
      ),
    ).rejects.toThrow();
  });

  it('rechaza sub vacío', async () => {
    await expect(
      verifyFirebaseIdToken(
        await token({ subject: '' }),
        projectId,
        resolver,
        now,
      ),
    ).rejects.toThrow();
  });

  it('acepta un token válido y obtiene el uid de sub', async () => {
    await expect(
      verifyFirebaseIdToken(await token(), projectId, resolver, now),
    ).resolves.toEqual({ uid: 'user-123' });
  });
});
