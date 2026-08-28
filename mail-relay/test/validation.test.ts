import { describe, expect, it } from 'vitest';
import { LIMITS, validatePayload } from '../src/validation';

const validPayload = {
  to: ['student@example.com'],
  subject: 'Reporte',
  html: '<html>Reporte</html>',
  text: 'Reporte',
};

describe('request validation', () => {
  it('acepta y normaliza un payload válido', () => {
    const result = validatePayload({
      ...validPayload,
      to: [' Student@Example.com ', 'student@example.com'],
    });
    expect(result).toEqual({
      ok: true,
      value: { ...validPayload, to: ['student@example.com'] },
    });
  });

  it('rechaza destinatarios vacíos', () => {
    expect(validatePayload({ ...validPayload, to: [] })).toMatchObject({
      ok: false,
      code: 'RECIPIENTS_REQUIRED',
    });
  });

  it('rechaza más de cinco destinatarios', () => {
    expect(
      validatePayload({
        ...validPayload,
        to: Array.from({ length: 6 }, (_, i) => `user${i}@example.com`),
      }),
    ).toMatchObject({ ok: false, code: 'TOO_MANY_RECIPIENTS' });
  });

  it('rechaza destinatarios inválidos', () => {
    expect(
      validatePayload({ ...validPayload, to: ['invalid'] }),
    ).toMatchObject({ ok: false, code: 'INVALID_RECIPIENT' });
  });

  it('rechaza subject demasiado largo', () => {
    expect(
      validatePayload({
        ...validPayload,
        subject: 'x'.repeat(LIMITS.subjectCharacters + 1),
      }),
    ).toMatchObject({ ok: false, code: 'SUBJECT_TOO_LONG' });
  });

  it('rechaza HTML demasiado grande con 413', () => {
    expect(
      validatePayload({
        ...validPayload,
        html: 'x'.repeat(LIMITS.htmlBytes + 1),
      }),
    ).toMatchObject({
      ok: false,
      status: 413,
      code: 'PAYLOAD_TOO_LARGE',
    });
  });

  it('rechaza texto demasiado grande con 413', () => {
    expect(
      validatePayload({
        ...validPayload,
        text: 'x'.repeat(LIMITS.textBytes + 1),
      }),
    ).toMatchObject({
      ok: false,
      status: 413,
      code: 'PAYLOAD_TOO_LARGE',
    });
  });
});
