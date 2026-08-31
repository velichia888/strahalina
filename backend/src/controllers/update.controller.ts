import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { HttpError } from "../utils/HttpError";
import { asyncHandler } from "../utils/asyncHandler";
import { getStorageProvider } from "../storage";
import { generateStorageKey } from "../storage/keys";

function serializeUpdate(update: {
  id: string;
  body: string;
  photoStorageKey: string | null;
  externalVideoUrl: string | null;
  category: string;
  listingId: string | null;
  createdAt: Date;
  author: { id: string; displayName: string };
}) {
  return {
    id: update.id,
    body: update.body,
    externalVideoUrl: update.externalVideoUrl,
    category: update.category,
    listingId: update.listingId,
    createdAt: update.createdAt,
    author: update.author,
    // photoUrl resolved async below where needed
  };
}

const updateInclude = { author: { select: { id: true, displayName: true } } };
const updateCategoryEnum = z.enum(["general", "market_insight", "content"]);

const listUpdatesQuerySchema = z.object({
  category: updateCategoryEnum.optional(),
});

export const listUpdates = asyncHandler(async (req: Request, res: Response) => {
  const query = listUpdatesQuerySchema.parse(req.query);
  const updates = await prisma.update.findMany({
    where: query.category ? { category: query.category } : {},
    include: updateInclude,
    orderBy: { createdAt: "desc" },
  });
  const storage = getStorageProvider();
  const serialized = await Promise.all(
    updates.map(async (u) => ({
      ...serializeUpdate(u),
      photoUrl: u.photoStorageKey ? await storage.createSignedReadUrl(u.photoStorageKey) : null,
    }))
  );
  res.json({ updates: serialized });
});

const createUpdateSchema = z.object({
  body: z.string().min(1).max(2000),
  listingId: z.string().uuid().optional(),
  category: updateCategoryEnum.optional().default("general"),
  externalVideoUrl: z.string().url().max(500).optional(),
});

export const createUpdate = asyncHandler(async (req: Request, res: Response) => {
  const body = createUpdateSchema.parse(req.body);

  if (body.listingId) {
    const listing = await prisma.listing.findUnique({ where: { id: body.listingId } });
    if (!listing) {
      throw new HttpError(404, "Listing not found");
    }
  }

  let photoStorageKey: string | undefined;
  if (req.file) {
    const key = generateStorageKey("updates", req.file.originalname);
    await getStorageProvider().upload({ key, buffer: req.file.buffer, contentType: req.file.mimetype });
    photoStorageKey = key;
  }

  const update = await prisma.update.create({
    data: {
      authorId: req.userId!,
      body: body.body,
      listingId: body.listingId,
      category: body.category,
      externalVideoUrl: body.externalVideoUrl,
      photoStorageKey,
    },
    include: updateInclude,
  });

  res.status(201).json({
    update: {
      ...serializeUpdate(update),
      photoUrl: photoStorageKey ? await getStorageProvider().createSignedReadUrl(photoStorageKey) : null,
    },
  });
});

export const deleteUpdate = asyncHandler(async (req: Request, res: Response) => {
  const existing = await prisma.update.findUnique({ where: { id: req.params.id } });
  if (!existing) {
    throw new HttpError(404, "Update not found");
  }
  if (existing.photoStorageKey) {
    await getStorageProvider().delete(existing.photoStorageKey);
  }
  await prisma.update.delete({ where: { id: req.params.id } });
  res.status(204).send();
});
