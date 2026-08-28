export interface RateLimitStore {
  get(key: string): Promise<string | null>;
  put(
    key: string,
    value: string,
    options?: { expirationTtl?: number },
  ): Promise<void>;
}

export interface Env {
  FIREBASE_PROJECT_ID: string;
  RESEND_API_KEY: string;
  RESEND_FROM_EMAIL: string;
  RESEND_FROM_NAME: string;
  RATE_LIMIT: RateLimitStore;
}

export interface SendEmailPayload {
  to: string[];
  subject: string;
  html: string;
  text: string;
}

export interface VerifiedFirebaseUser {
  uid: string;
}

export interface ProviderSendResult {
  success: boolean;
  messageId?: string;
}
