import jwt from "jsonwebtoken";
import { env } from "../config/env";

export interface AccessTokenPayload {
  sub: string;
  tokenVersion: number;
  type: "access";
}

export interface RefreshTokenPayload {
  sub: string;
  tokenVersion: number;
  type: "refresh";
}

export function signAccessToken(userId: string, tokenVersion: number): string {
  const payload: AccessTokenPayload = { sub: userId, tokenVersion, type: "access" };
  const options: jwt.SignOptions = { expiresIn: env.JWT_ACCESS_TTL as jwt.SignOptions["expiresIn"] };
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, options);
}

export function signRefreshToken(userId: string, tokenVersion: number): string {
  const payload: RefreshTokenPayload = { sub: userId, tokenVersion, type: "refresh" };
  const options: jwt.SignOptions = { expiresIn: env.JWT_REFRESH_TTL as jwt.SignOptions["expiresIn"] };
  return jwt.sign(payload, env.JWT_REFRESH_SECRET, options);
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as AccessTokenPayload;
  if (decoded.type !== "access") {
    throw new Error("Not an access token");
  }
  return decoded;
}

export function verifyRefreshToken(token: string): RefreshTokenPayload {
  const decoded = jwt.verify(token, env.JWT_REFRESH_SECRET) as RefreshTokenPayload;
  if (decoded.type !== "refresh") {
    throw new Error("Not a refresh token");
  }
  return decoded;
}
