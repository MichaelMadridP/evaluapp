import type { ProviderSendResult, SendEmailPayload } from './types';

interface ResendConfig {
  apiKey: string;
  fromEmail: string;
  fromName: string;
}

export async function sendWithResend(
  payload: SendEmailPayload,
  config: ResendConfig,
  fetcher: typeof fetch = fetch,
  timeoutMs = 15_000,
): Promise<ProviderSendResult> {
  if (!config.apiKey || !config.fromEmail || !config.fromName) {
    throw new Error('Email provider is not configured.');
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetcher('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: `${config.fromName} <${config.fromEmail}>`,
        to: payload.to,
        subject: payload.subject,
        html: payload.html,
        text: payload.text,
      }),
      signal: controller.signal,
    });

    if (response.status !== 200 && response.status !== 201) {
      return { success: false };
    }
    const decoded = (await response.json()) as { id?: unknown };
    if (typeof decoded.id !== 'string' || decoded.id.length === 0) {
      return { success: false };
    }
    return { success: true, messageId: decoded.id };
  } finally {
    clearTimeout(timeout);
  }
}
