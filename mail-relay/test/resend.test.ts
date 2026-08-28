import { describe, expect, it } from 'vitest';
import { sendWithResend } from '../src/resend';

const payload = {
  to: ['student@example.com'],
  subject: 'Reporte',
  html: '<html>Reporte</html>',
  text: 'Reporte',
};
const config = {
  apiKey: 'test-key-not-real',
  fromEmail: 'reports@example.com',
  fromName: 'EvaluApp',
};

describe('Resend transport', () => {
  for (const status of [200, 201]) {
    it(`interpreta ${status} como éxito`, async () => {
      let requestInit: RequestInit | undefined;
      const fetcher: typeof fetch = async (_input, init) => {
        requestInit = init;
        return new Response(JSON.stringify({ id: 'msg_123' }), { status });
      };

      const result = await sendWithResend(payload, config, fetcher);

      expect(result).toEqual({ success: true, messageId: 'msg_123' });
      expect(requestInit?.headers).toMatchObject({
        Authorization: 'Bearer test-key-not-real',
        'Content-Type': 'application/json',
      });
      const body = JSON.parse(String(requestInit?.body));
      expect(body).toMatchObject({
        from: 'EvaluApp <reports@example.com>',
        html: payload.html,
        text: payload.text,
      });
    });
  }

  for (const status of [400, 401, 429, 500]) {
    it(`convierte Resend ${status} en error controlado`, async () => {
      const fetcher: typeof fetch = async () =>
        new Response(JSON.stringify({ secretDetail: 'not exposed' }), {
          status,
        });

      await expect(sendWithResend(payload, config, fetcher)).resolves.toEqual({
        success: false,
      });
    });
  }

  it('aborta un request que supera el timeout', async () => {
    const fetcher: typeof fetch = async (_input, init) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener('abort', () => {
          reject(new DOMException('Aborted', 'AbortError'));
        });
      });

    await expect(
      sendWithResend(payload, config, fetcher, 5),
    ).rejects.toThrow();
  });
});
