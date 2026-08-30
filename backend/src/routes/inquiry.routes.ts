import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { requireAdmin } from "../middleware/requireAdmin";
import { createInquiry, listInquiries, respondToInquiry } from "../controllers/inquiry.controller";

// Mounted at /listings/:id/inquiries — any signed-in user can submit.
export const listingInquiryRouter = Router({ mergeParams: true });
listingInquiryRouter.post("/:id/inquiries", requireAuth, createInquiry);

// Mounted at /inquiries — admin inbox.
export const inquiryRouter = Router();
inquiryRouter.get("/", requireAuth, requireAdmin, listInquiries);
inquiryRouter.post("/:id/respond", requireAuth, requireAdmin, respondToInquiry);
