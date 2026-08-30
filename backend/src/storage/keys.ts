import crypto from "crypto";

export function generateStorageKey(prefix: string, originalFilename: string): string {
  const ext = originalFilename.includes(".") ? originalFilename.split(".").pop() : undefined;
  const random = crypto.randomUUID();
  return ext ? `${prefix}/${random}.${ext}` : `${prefix}/${random}`;
}
