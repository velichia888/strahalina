import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { requireAdmin } from "../middleware/requireAdmin";
import { uploadPhoto } from "../middleware/upload";
import {
  createListing,
  listListings,
  getListing,
  updateListing,
  deleteListing,
  uploadListingPhoto,
  deleteListingPhoto,
} from "../controllers/listing.controller";

export const listingRouter = Router();

// Public browsing — no auth required.
listingRouter.get("/", listListings);
listingRouter.get("/:id", getListing);

// Admin-only writes.
listingRouter.post("/", requireAuth, requireAdmin, createListing);
listingRouter.patch("/:id", requireAuth, requireAdmin, updateListing);
listingRouter.delete("/:id", requireAuth, requireAdmin, deleteListing);
listingRouter.post("/:id/photos", requireAuth, requireAdmin, uploadPhoto.single("photo"), uploadListingPhoto);
listingRouter.delete("/:id/photos/:photoId", requireAuth, requireAdmin, deleteListingPhoto);
