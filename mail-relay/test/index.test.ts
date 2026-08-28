import { describe, expect, it, vi } from 'vitest';
import { createHandler } from '../src/index';
import type { Env, RateLimitStore } from '../src/types';
import type { SendEmailPayload } from '../src/types';
import { LIMITS } from '../src/validation';

class MemoryStore implements RateLimitStore {
  async get(): Promise<string | null> {
    return null;
  }
  async put(): Promise<void> {}
}

const env: Env = {
  FIREBASE_PROJECT_ID: 'evaluapp-test',
  RESEND_API_KEY: 'test-key-not-real',
  RESEND_FROM_EMAIL: 'reports@example.com',
  RESEND_FROM_NAME: 'EvaluApp',
  RATE_LIMIT: new MemoryStore(),
};

const validPayload = {
  to: ['student@example.com'],
  subject: 'Reporte',
  html: '<html>Reporte</html>',
  text: 'Reporte',
};

function request(
  body: string = JSON.stringify(validPayload),
  headers: Record<string, string> = {},
): Request {
  return new Request('https://relay.example.test/send', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer valid-token',
      'Content-Type': 'application/json',
      ...headers,
    },
    body,
  });
}

async function run(
  req: Request,
  overrides: Parameters<typeof createHandler>[0] = {},
): Promise<Response> {
  const handler = createHandler({
    verifyToken: async () => ({ uid: 'user-123' }),
    consumeQuota: async () => true,
    sendEmail: async () => ({ success: true, messageId: 'msg_123' }),
    ...overrides,
  });
  return (handler.fetch as CallableFunction)(
    req,
    env,
    {} as ExecutionContext,
  ) as Promise<Response>;
}

describe('mail relay handler', () => {
  it('GET /health responde sin datos sensibles', async () => {
    const response = await run(
      new Request('https://relay.example.test/health'),
    );
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ success: true, status: 'ok' });
  });

  it('rechaza un método incorrecto con 405', async () => {
    const response = await run(
      new Request('https://relay.example.test/send', { method: 'GET' }),
    );
    expect(response.status).toBe(405);
  });

  it('rechaza Authorization ausente con 401', async () => {
    const response = await run(
      new Request('https://relay.example.test/send', {
        method: 'POST',
        body: JSON.stringify(validPayload),
      }),
    );
    expect(response.status).toBe(401);
  });

  it('rechaza Bearer vacío con 401', async () => {
    const response = await run(request(undefined, { Authorization: 'Bearer ' }));
    expect(response.status).toBe(401);
  });

  it('rechaza token inválido sin procesar el email', async () => {
    const sendEmail = vi.fn();
    const response = await run(request(), {
      verifyToken: async () => {
        throw new Error('invalid');
      },
      sendEmail,
    });
    expect(response.status).toBe(401);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it('rechaza JSON inválido con 400', async () => {
    const response = await run(request('{bad json'));
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({
      success: false,
      error: { code: 'INVALID_JSON' },
    });
  });

  it('rechaza Content-Type distinto de JSON con 400', async () => {
    const response = await run(
      request(undefined, { 'Content-Type': 'text/plain' }),
    );
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({
      error: { code: 'INVALID_CONTENT_TYPE' },
    });
  });

  it('rechaza Content-Length excesivo con 413 antes de leer el body', async () => {
    const response = await run(
      request(undefined, {
        'Content-Length': String(LIMITS.requestBytes + 1),
      }),
    );
    expect(response.status).toBe(413);
  });

  it('devuelve 429 cuando el usuario alcanzó su cuota', async () => {
    const response = await run(request(), {
      consumeQuota: async () => false,
    });
    expect(response.status).toBe(429);
    expect(await response.json()).toMatchObject({
      error: { code: 'RATE_LIMITED' },
    });
  });

  it('envía HTML y texto y devuelve messageId', async () => {
    const sendEmail = vi.fn(
      async (
        _payload: SendEmailPayload,
        _config: { apiKey: string; fromEmail: string; fromName: string },
      ) => ({ success: true, messageId: 'msg_456' }),
    );
    const response = await run(request(), { sendEmail });

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      success: true,
      messageId: 'msg_456',
    });
    expect(sendEmail).toHaveBeenCalledWith(
      expect.objectContaining({
        html: validPayload.html,
        text: validPayload.text,
      }),
      {
        apiKey: env.RESEND_API_KEY,
        fromEmail: env.RESEND_FROM_EMAIL,
        fromName: env.RESEND_FROM_NAME,
      },
    );
  });

  it('no permite que Flutter controle from', async () => {
    const sendEmail = vi.fn(
      async (
        _payload: SendEmailPayload,
        _config: { apiKey: string; fromEmail: string; fromName: string },
      ) => ({ success: true, messageId: 'msg_789' }),
    );
    await run(
      request(JSON.stringify({
        ...validPayload,
        from: 'attacker@example.com',
      })),
      { sendEmail },
    );

    expect(sendEmail.mock.calls[0][0]).not.toHaveProperty('from');
    expect(sendEmail.mock.calls[0][1].fromEmail).toBe(env.RESEND_FROM_EMAIL);
  });

  it('convierte rechazo de Resend en 502 sin filtrar detalles', async () => {
    const response = await run(request(), {
      sendEmail: async () => ({ success: false }),
    });
    expect(response.status).toBe(502);
    const body = JSON.stringify(await response.json());
    expect(body).toContain('EMAIL_PROVIDER_ERROR');
    expect(body).not.toContain(env.RESEND_API_KEY);
  });

  it('convierte excepción de Resend/timeout en 502', async () => {
    const response = await run(request(), {
      sendEmail: async () => {
        throw new Error('provider secret detail');
      },
    });
    expect(response.status).toBe(502);
    expect(await response.text()).not.toContain('provider secret detail');
  });
});
