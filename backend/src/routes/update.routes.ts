import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { requireAdmin } from "../middleware/requireAdmin";
import { uploadPhoto } from "../middleware/upload";
import { listUpdates, createUpdate, deleteUpdate } from "../controllers/update.controller";

export const updateRouter = Router();

updateRouter.get("/", listUpdates);
updateRouter.post("/", requireAuth, requireAdmin, uploadPhoto.single("photo"), createUpdate);
updateRouter.delete("/:id", requireAuth, requireAdmin, deleteUpdate);
