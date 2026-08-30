import { NextFunction, Request, Response } from "express";
import { prisma } from "../db/prisma";
import { HttpError } from "../utils/HttpError";
import { verifyAccessToken } from "../utils/jwt";
import { asyncHandler } from "../utils/asyncHandler";

export const requireAuth = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    throw new HttpError(401, "Missing or malformed Authorization header");
  }

  const token = header.slice("Bearer ".length);

  let payload;
  try {
    payload = verifyAccessToken(token);
  } catch {
    throw new HttpError(401, "Invalid or expired access token");
  }

  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  if (!user || user.status !== "active" || user.tokenVersion !== payload.tokenVersion) {
    throw new HttpError(401, "Session is no longer valid");
  }

  req.userId = user.id;
  next();
});

export const optionalAuth = asyncHandler(async (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return next();
  }

  const token = header.slice("Bearer ".length);

  try {
    const payload = verifyAccessToken(token);
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (user && user.status === "active" && user.tokenVersion === payload.tokenVersion) {
      req.userId = user.id;
    }
  } catch {
    // Invalid/expired token on an optional-auth route just means "anonymous".
  }

  next();
});
