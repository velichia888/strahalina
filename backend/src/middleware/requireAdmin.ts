import { NextFunction, Request, Response } from "express";
import { prisma } from "../db/prisma";
import { HttpError } from "../utils/HttpError";
import { asyncHandler } from "../utils/asyncHandler";

/**
 * Gates the admin-only moderation endpoints. Must run after requireAuth
 * (needs req.userId already set) — mounted as a second middleware on
 * the admin router, not a replacement for it.
 */
export const requireAdmin = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user?.isAdmin) {
    throw new HttpError(403, "Admin access required");
  }
  next();
});
