import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { HttpError } from "../utils/HttpError";
import { asyncHandler } from "../utils/asyncHandler";
import { getStorageProvider } from "../storage";
import { generateStorageKey } from "../storage/keys";

const MAX_PHOTOS_PER_LISTING = 10;

const listingTypeEnum = z.enum(["property", "investment"]);
const listingStatusEnum = z.enum(["active", "pending", "sold"]);
const keyFactSchema = z.object({ label: z.string().min(1).max(60), value: z.string().min(1).max(120) });

export async function serializeListing(listing: {
  id: string;
  title: string;
  description: string;
  type: string;
  status: string;
  priceCents: number;
  location: string;
  keyFacts: unknown;
  createdAt: Date;
  updatedAt: Date;
  photos: { id: string; storageKey: string; order: number }[];
}) {
  const storage = getStorageProvider();
  const photos = await Promise.all(
    listing.photos
      .sort((a, b) => a.order - b.order)
      .map(async (photo) => ({ id: photo.id, url: await storage.createSignedReadUrl(photo.storageKey) }))
  );

  return {
    id: listing.id,
    title: listing.title,
    description: listing.description,
    type: listing.type,
    status: listing.status,
    priceCents: listing.priceCents,
    location: listing.location,
    keyFacts: listing.keyFacts,
    createdAt: listing.createdAt,
    updatedAt: listing.updatedAt,
    photos,
  };
}

const listingInclude = { photos: true };

const createListingSchema = z.object({
  title: z.string().min(1).max(120),
  description: z.string().min(1).max(4000),
  type: listingTypeEnum,
  priceCents: z.number().int().positive(),
  location: z.string().min(1).max(160),
  keyFacts: z.array(keyFactSchema).max(20).default([]),
});

export const createListing = asyncHandler(async (req: Request, res: Response) => {
  const body = createListingSchema.parse(req.body);
  const listing = await prisma.listing.create({
    data: { ...body, keyFacts: body.keyFacts },
    include: listingInclude,
  });
  res.status(201).json({ listing: await serializeListing(listing) });
});

const listQuerySchema = z.object({
  type: listingTypeEnum.optional(),
  status: listingStatusEnum.optional(),
  minPriceCents: z.coerce.number().int().nonnegative().optional(),
  maxPriceCents: z.coerce.number().int().positive().optional(),
  // Substring match against the real, couple-entered location field —
  // not a curated list of regions, since that would imply coverage
  // areas the app doesn't actually track.
  location: z.string().min(1).max(160).optional(),
});

export const listListings = asyncHandler(async (req: Request, res: Response) => {
  const query = listQuerySchema.parse(req.query);

  const where = {
    ...(query.type ? { type: query.type } : {}),
    // Public browsing defaults to active listings only; an explicit
    // status filter (used by the admin inbox) can still ask for others.
    status: query.status ?? "active",
    ...(query.location ? { location: { contains: query.location, mode: "insensitive" as const } } : {}),
    ...(query.minPriceCents !== undefined || query.maxPriceCents !== undefined
      ? {
          priceCents: {
            ...(query.minPriceCents !== undefined ? { gte: query.minPriceCents } : {}),
            ...(query.maxPriceCents !== undefined ? { lte: query.maxPriceCents } : {}),
          },
        }
      : {}),
  };

  const listings = await prisma.listing.findMany({
    where,
    include: listingInclude,
    orderBy: { createdAt: "desc" },
  });

  res.json({ listings: await Promise.all(listings.map(serializeListing)) });
});

export const getListing = asyncHandler(async (req: Request, res: Response) => {
  const listing = await prisma.listing.findUnique({
    where: { id: req.params.id },
    include: listingInclude,
  });
  if (!listing) {
    throw new HttpError(404, "Listing not found");
  }
  res.json({ listing: await serializeListing(listing) });
});

const updateListingSchema = createListingSchema.partial().extend({
  status: listingStatusEnum.optional(),
});

export const updateListing = asyncHandler(async (req: Request, res: Response) => {
  const body = updateListingSchema.parse(req.body);
  const existing = await prisma.listing.findUnique({ where: { id: req.params.id } });
  if (!existing) {
    throw new HttpError(404, "Listing not found");
  }

  const listing = await prisma.listing.update({
    where: { id: req.params.id },
    data: { ...body, ...(body.keyFacts ? { keyFacts: body.keyFacts } : {}) },
    include: listingInclude,
  });
  res.json({ listing: await serializeListing(listing) });
});

export const deleteListing = asyncHandler(async (req: Request, res: Response) => {
  const existing = await prisma.listing.findUnique({ where: { id: req.params.id } });
  if (!existing) {
    throw new HttpError(404, "Listing not found");
  }
  await prisma.listing.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

export const uploadListingPhoto = asyncHandler(async (req: Request, res: Response) => {
  const listing = await prisma.listing.findUnique({
    where: { id: req.params.id },
    include: { photos: true },
  });
  if (!listing) {
    throw new HttpError(404, "Listing not found");
  }
  if (listing.photos.length >= MAX_PHOTOS_PER_LISTING) {
    throw new HttpError(400, `A listing can have at most ${MAX_PHOTOS_PER_LISTING} photos`);
  }
  if (!req.file) {
    throw new HttpError(400, "No photo uploaded");
  }

  const key = generateStorageKey(`listings/${listing.id}`, req.file.originalname);
  await getStorageProvider().upload({ key, buffer: req.file.buffer, contentType: req.file.mimetype });

  const photo = await prisma.listingPhoto.create({
    data: { listingId: listing.id, storageKey: key, order: listing.photos.length },
  });

  res.status(201).json({
    photo: { id: photo.id, url: await getStorageProvider().createSignedReadUrl(photo.storageKey) },
  });
});

export const deleteListingPhoto = asyncHandler(async (req: Request, res: Response) => {
  const photo = await prisma.listingPhoto.findUnique({ where: { id: req.params.photoId } });
  if (!photo || photo.listingId !== req.params.id) {
    throw new HttpError(404, "Photo not found");
  }
  await getStorageProvider().delete(photo.storageKey);
  await prisma.listingPhoto.delete({ where: { id: photo.id } });
  res.status(204).send();
});
