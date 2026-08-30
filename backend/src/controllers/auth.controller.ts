import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { HttpError } from "../utils/HttpError";
import { hashPassword, comparePassword } from "../utils/password";
import { signAccessToken, signRefreshToken, verifyRefreshToken } from "../utils/jwt";
import { asyncHandler } from "../utils/asyncHandler";

function toPublicUser(user: {
  id: string;
  email: string;
  displayName: string;
  isAdmin: boolean;
  createdAt: Date;
}) {
  return {
    id: user.id,
    email: user.email,
    displayName: user.displayName,
    isAdmin: user.isAdmin,
    createdAt: user.createdAt,
  };
}

function issueTokens(userId: string, tokenVersion: number) {
  return {
    accessToken: signAccessToken(userId, tokenVersion),
    refreshToken: signRefreshToken(userId, tokenVersion),
  };
}

const signupSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(200),
  displayName: z.string().min(1).max(60),
});

export const signup = asyncHandler(async (req: Request, res: Response) => {
  const body = signupSchema.parse(req.body);

  const existing = await prisma.user.findUnique({ where: { email: body.email } });
  if (existing) {
    throw new HttpError(409, "Email is already in use");
  }

  const passwordHash = await hashPassword(body.password);
  const user = await prisma.user.create({
    data: { email: body.email, passwordHash, displayName: body.displayName },
  });

  const tokens = issueTokens(user.id, user.tokenVersion);
  res.status(201).json({ user: toPublicUser(user), ...tokens });
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  const body = loginSchema.parse(req.body);

  const user = await prisma.user.findUnique({ where: { email: body.email } });
  if (!user || !(await comparePassword(body.password, user.passwordHash))) {
    throw new HttpError(401, "Invalid email or password");
  }
  if (user.status !== "active") {
    throw new HttpError(403, "This account is not active");
  }

  const tokens = issueTokens(user.id, user.tokenVersion);
  res.json({ user: toPublicUser(user), ...tokens });
});

const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const refresh = asyncHandler(async (req: Request, res: Response) => {
  const body = refreshSchema.parse(req.body);

  let payload;
  try {
    payload = verifyRefreshToken(body.refreshToken);
  } catch {
    throw new HttpError(401, "Invalid or expired refresh token");
  }

  const user = await prisma.user.findUnique({ where: { id: payload.sub } });
  if (!user || user.status !== "active" || user.tokenVersion !== payload.tokenVersion) {
    throw new HttpError(401, "Refresh token is no longer valid");
  }

  const tokens = issueTokens(user.id, user.tokenVersion);
  res.json(tokens);
});

export const me = asyncHandler(async (req: Request, res: Response) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user) {
    throw new HttpError(404, "User not found");
  }
  res.json({ user: toPublicUser(user) });
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8).max(200),
});

export const changePassword = asyncHandler(async (req: Request, res: Response) => {
  const body = changePasswordSchema.parse(req.body);

  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user || !(await comparePassword(body.currentPassword, user.passwordHash))) {
    throw new HttpError(401, "Current password is incorrect");
  }

  const passwordHash = await hashPassword(body.newPassword);
  const updated = await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash, tokenVersion: { increment: 1 } },
  });

  const tokens = issueTokens(updated.id, updated.tokenVersion);
  res.json(tokens);
});

export const logout = asyncHandler(async (req: Request, res: Response) => {
  await prisma.user.update({
    where: { id: req.userId },
    data: { tokenVersion: { increment: 1 } },
  });
  res.status(204).send();
});
