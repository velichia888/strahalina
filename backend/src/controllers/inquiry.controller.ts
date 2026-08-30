import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { HttpError } from "../utils/HttpError";
import { asyncHandler } from "../utils/asyncHandler";

function serializeInquiry(inquiry: {
  id: string;
  listingId: string;
  message: string;
  respondedAt: Date | null;
  createdAt: Date;
  buyer: { id: string; displayName: string; email: string };
  listing?: { id: string; title: string };
}) {
  return {
    id: inquiry.id,
    listingId: inquiry.listingId,
    listing: inquiry.listing,
    message: inquiry.message,
    respondedAt: inquiry.respondedAt,
    createdAt: inquiry.createdAt,
    buyer: inquiry.buyer,
  };
}

const createInquirySchema = z.object({
  message: z.string().min(1).max(2000),
});

// Mounted at POST /listings/:id/inquiries — the buyer submitting the
// inquiry is req.userId (any signed-in user), never an admin action.
export const createInquiry = asyncHandler(async (req: Request, res: Response) => {
  const body = createInquirySchema.parse(req.body);

  const listing = await prisma.listing.findUnique({ where: { id: req.params.id } });
  if (!listing) {
    throw new HttpError(404, "Listing not found");
  }

  const inquiry = await prisma.inquiry.create({
    data: { listingId: listing.id, buyerId: req.userId!, message: body.message },
    include: { buyer: { select: { id: true, displayName: true, email: true } } },
  });

  res.status(201).json({ inquiry: serializeInquiry(inquiry) });
});

// Admin inbox — every inquiry across every listing.
export const listInquiries = asyncHandler(async (_req: Request, res: Response) => {
  const inquiries = await prisma.inquiry.findMany({
    include: {
      buyer: { select: { id: true, displayName: true, email: true } },
      listing: { select: { id: true, title: true } },
    },
    orderBy: { createdAt: "desc" },
  });
  res.json({ inquiries: inquiries.map(serializeInquiry) });
});

export const respondToInquiry = asyncHandler(async (req: Request, res: Response) => {
  const existing = await prisma.inquiry.findUnique({ where: { id: req.params.id } });
  if (!existing) {
    throw new HttpError(404, "Inquiry not found");
  }
  const inquiry = await prisma.inquiry.update({
    where: { id: req.params.id },
    data: { respondedAt: new Date() },
    include: {
      buyer: { select: { id: true, displayName: true, email: true } },
      listing: { select: { id: true, title: true } },
    },
  });
  res.json({ inquiry: serializeInquiry(inquiry) });
});
