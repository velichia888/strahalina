import fs from "fs/promises";
import path from "path";
import { StorageProvider, UploadParams } from "./StorageProvider";
import { createSignedLocalUrl } from "./localSigning";

const STORAGE_ROOT = path.resolve(__dirname, "..", "..", ".local-storage");

function resolveKeyPath(key: string): string {
  const resolved = path.resolve(STORAGE_ROOT, key);
  if (!resolved.startsWith(STORAGE_ROOT)) {
    throw new Error("Invalid storage key");
  }
  return resolved;
}

export class LocalStorageProvider implements StorageProvider {
  async upload({ key, buffer }: UploadParams): Promise<void> {
    const filePath = resolveKeyPath(key);
    await fs.mkdir(path.dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, buffer);
  }

  async delete(key: string): Promise<void> {
    const filePath = resolveKeyPath(key);
    await fs.rm(filePath, { force: true });
  }

  async createSignedReadUrl(key: string, expiresInSeconds = 3600): Promise<string> {
    return createSignedLocalUrl(key, expiresInSeconds);
  }
}

export { STORAGE_ROOT };
