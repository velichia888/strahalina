import fs from "fs";
import path from "path";
import { Router } from "express";
import { STORAGE_ROOT } from "../storage/localStorageProvider";
import { verifyLocalSignature } from "../storage/localSigning";

export const localStorageRouter = Router();

localStorageRouter.get("/local-storage/:key(*)", (req, res) => {
  const { key } = req.params;
  const exp = Number(req.query.exp);
  const sig = String(req.query.sig || "");

  if (!key || !Number.isFinite(exp) || !sig || !verifyLocalSignature(key, exp, sig)) {
    return res.status(403).json({ error: "Invalid or expired signed URL" });
  }

  const filePath = path.resolve(STORAGE_ROOT, key);
  if (!filePath.startsWith(STORAGE_ROOT) || !fs.existsSync(filePath)) {
    return res.status(404).json({ error: "Not found" });
  }

  res.sendFile(filePath);
});
