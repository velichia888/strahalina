import { env } from "../config/env";
import { StorageProvider } from "./StorageProvider";
import { LocalStorageProvider } from "./localStorageProvider";

let provider: StorageProvider | null = null;

export function getStorageProvider(): StorageProvider {
  if (provider) {
    return provider;
  }

  if (env.STORAGE_PROVIDER === "s3") {
    const { S3StorageProvider } = require("./s3StorageProvider") as typeof import("./s3StorageProvider");
    provider = new S3StorageProvider();
  } else {
    provider = new LocalStorageProvider();
  }

  return provider;
}

export type { StorageProvider, UploadParams } from "./StorageProvider";
