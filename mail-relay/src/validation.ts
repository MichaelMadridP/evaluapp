import type { SendEmailPayload } from './types';

export const LIMITS = {
  recipients: 5,
  subjectCharacters: 200,
  htmlBytes: 200 * 1024,
  textBytes: 100 * 1024,
  requestBytes: 310 * 1024,
} as const;

const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const encoder = new TextEncoder();

export type ValidationResult =
  | { ok: true; value: SendEmailPayload }
  | { ok: false; code: string; message: string; status: 400 | 413 };

export function validatePayload(value: unknown): ValidationResult {
  if (!isRecord(value)) {
    return invalid('INVALID_REQUEST', 'Request body must be a JSON object.');
  }

  const to = value.to;
  const subject = value.subject;
  const html = value.html;
  const text = value.text;

  if (!Array.isArray(to) || to.length === 0) {
    return invalid('RECIPIENTS_REQUIRED', 'At least one recipient is required.');
  }
  if (to.length > LIMITS.recipients) {
    return invalid('TOO_MANY_RECIPIENTS', 'Too many recipients.');
  }
  if (to.some((item) => typeof item !== 'string')) {
    return invalid('INVALID_RECIPIENT', 'Invalid recipient.');
  }

  const recipients = [...new Set(to.map((email) => email.trim().toLowerCase()))];
  if (
    recipients.length === 0 ||
    recipients.some((email) => !emailPattern.test(email))
  ) {
    return invalid('INVALID_RECIPIENT', 'Invalid recipient.');
  }

  if (typeof subject !== 'string' || subject.trim().length === 0) {
    return invalid('INVALID_SUBJECT', 'Subject is required.');
  }
  if ([...subject].length > LIMITS.subjectCharacters) {
    return invalid('SUBJECT_TOO_LONG', 'Subject is too long.');
  }
  if (typeof html !== 'string' || typeof text !== 'string') {
    return invalid('INVALID_CONTENT', 'HTML and text content are required.');
  }
  if (encoder.encode(html).byteLength > LIMITS.htmlBytes) {
    return tooLarge('HTML content is too large.');
  }
  if (encoder.encode(text).byteLength > LIMITS.textBytes) {
    return tooLarge('Text content is too large.');
  }

  return {
    ok: true,
    value: {
      to: recipients,
      subject: subject.trim(),
      html,
      text,
    },
  };
}

function invalid(code: string, message: string): ValidationResult {
  return { ok: false, code, message, status: 400 };
}

function tooLarge(message: string): ValidationResult {
  return { ok: false, code: 'PAYLOAD_TOO_LARGE', message, status: 413 };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
