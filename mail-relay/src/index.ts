import { verifyFirebaseIdToken } from './auth';
import { consumeDailyQuota } from './rate_limit';
import { sendWithResend } from './resend';
import type {
  Env,
  ProviderSendResult,
  SendEmailPayload,
  VerifiedFirebaseUser,
} from './types';
import { LIMITS, validatePayload } from './validation';

interface HandlerDependencies {
  verifyToken: (
    token: string,
    projectId: string,
  ) => Promise<VerifiedFirebaseUser>;
  consumeQuota: (
    store: Env['RATE_LIMIT'],
    uid: string,
  ) => Promise<boolean>;
  sendEmail: (
    payload: SendEmailPayload,
    config: { apiKey: string; fromEmail: string; fromName: string },
  ) => Promise<ProviderSendResult>;
}

const defaultDependencies: HandlerDependencies = {
  verifyToken: verifyFirebaseIdToken,
  consumeQuota: consumeDailyQuota,
  sendEmail: sendWithResend,
};

export function createHandler(
  overrides: Partial<HandlerDependencies> = {},
): ExportedHandler<Env> {
  const dependencies = { ...defaultDependencies, ...overrides };

  return {
    async fetch(request, env): Promise<Response> {
      const url = new URL(request.url);

      if (url.pathname === '/health') {
        if (request.method !== 'GET') {
          return errorResponse(405, 'METHOD_NOT_ALLOWED', 'Method not allowed.');
        }
        return jsonResponse(200, { success: true, status: 'ok' });
      }

      if (url.pathname !== '/send') {
        return errorResponse(404, 'NOT_FOUND', 'Endpoint not found.');
      }
      if (request.method !== 'POST') {
        return errorResponse(405, 'METHOD_NOT_ALLOWED', 'Method not allowed.');
      }

      const token = readBearerToken(request.headers.get('authorization'));
      if (!token) {
        return errorResponse(401, 'INVALID_TOKEN', 'Authentication required.');
      }

      let user: VerifiedFirebaseUser;
      try {
        user = await dependencies.verifyToken(token, env.FIREBASE_PROJECT_ID);
      } catch {
        return errorResponse(401, 'INVALID_TOKEN', 'Authentication required.');
      }

      const contentType = request.headers.get('content-type') ?? '';
      if (!contentType.toLowerCase().includes('application/json')) {
        return errorResponse(
          400,
          'INVALID_CONTENT_TYPE',
          'Content-Type must be application/json.',
        );
      }

      const declaredLength = Number.parseInt(
        request.headers.get('content-length') ?? '0',
        10,
      );
      if (declaredLength > LIMITS.requestBytes) {
        return errorResponse(
          413,
          'PAYLOAD_TOO_LARGE',
          'Request payload is too large.',
        );
      }

      let rawBody: string;
      try {
        rawBody = await request.text();
      } catch {
        return errorResponse(400, 'INVALID_JSON', 'Invalid JSON body.');
      }
      if (new TextEncoder().encode(rawBody).byteLength > LIMITS.requestBytes) {
        return errorResponse(
          413,
          'PAYLOAD_TOO_LARGE',
          'Request payload is too large.',
        );
      }

      let decoded: unknown;
      try {
        decoded = JSON.parse(rawBody);
      } catch {
        return errorResponse(400, 'INVALID_JSON', 'Invalid JSON body.');
      }

      const validation = validatePayload(decoded);
      if (!validation.ok) {
        return errorResponse(
          validation.status,
          validation.code,
          validation.message,
        );
      }

      let allowed: boolean;
      try {
        allowed = await dependencies.consumeQuota(env.RATE_LIMIT, user.uid);
      } catch {
        return errorResponse(
          500,
          'INTERNAL_ERROR',
          'Unable to process the request.',
        );
      }
      if (!allowed) {
        return errorResponse(
          429,
          'RATE_LIMITED',
          'Daily email limit reached.',
        );
      }

      try {
        const result = await dependencies.sendEmail(validation.value, {
          apiKey: env.RESEND_API_KEY,
          fromEmail: env.RESEND_FROM_EMAIL,
          fromName: env.RESEND_FROM_NAME,
        });
        if (!result.success || !result.messageId) {
          return errorResponse(
            502,
            'EMAIL_PROVIDER_ERROR',
            'Unable to send email.',
          );
        }
        return jsonResponse(200, {
          success: true,
          messageId: result.messageId,
        });
      } catch {
        return errorResponse(
          502,
          'EMAIL_PROVIDER_ERROR',
          'Unable to send email.',
        );
      }
    },
  };
}

function readBearerToken(authorization: string | null): string | null {
  if (!authorization) return null;
  const match = authorization.match(/^Bearer\s+([^\s]+)$/i);
  return match?.[1] ?? null;
}

function errorResponse(status: number, code: string, message: string): Response {
  return jsonResponse(status, {
    success: false,
    error: { code, message },
  });
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}

export default createHandler();
