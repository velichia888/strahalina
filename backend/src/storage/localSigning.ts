import crypto from "crypto";
import { env } from "../config/env";

function sign(key: string, expiresAt: number): string {
  return crypto
    .createHmac("sha256", env.LOCAL_STORAGE_SIGNING_SECRET)
    .update(`${key}:${expiresAt}`)
    .digest("hex");
}

export function createSignedLocalUrl(key: string, expiresInSeconds: number): string {
  const expiresAt = Date.now() + expiresInSeconds * 1000;
  const signature = sign(key, expiresAt);
  const encodedKey = encodeURIComponent(key);
  return `/local-storage/${encodedKey}?exp=${expiresAt}&sig=${signature}`;
}

export function verifyLocalSignature(key: string, expiresAt: number, signature: string): boolean {
  if (Date.now() > expiresAt) {
    return false;
  }
  const expected = sign(key, expiresAt);
  const expectedBuf = Buffer.from(expected);
  const actualBuf = Buffer.from(signature);
  if (expectedBuf.length !== actualBuf.length) {
    return false;
  }
  return crypto.timingSafeEqual(expectedBuf, actualBuf);
}
