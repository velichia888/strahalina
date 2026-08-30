import multer from "multer";
import { HttpError } from "../utils/HttpError";

const ALLOWED_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]);
const MAX_FILE_SIZE_BYTES = 15 * 1024 * 1024;

export const uploadPhoto = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE_BYTES },
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_MIME_TYPES.has(file.mimetype)) {
      cb(new HttpError(400, "Unsupported photo type. Use JPEG, PNG, WEBP, or HEIC."));
      return;
    }
    cb(null, true);
  },
});
