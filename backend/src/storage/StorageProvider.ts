export interface UploadParams {
  key: string;
  buffer: Buffer;
  contentType: string;
}

export interface StorageProvider {
  upload(params: UploadParams): Promise<void>;
  delete(key: string): Promise<void>;
  createSignedReadUrl(key: string, expiresInSeconds?: number): Promise<string>;
}
