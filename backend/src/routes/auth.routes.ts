import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { signup, login, refresh, me, changePassword, logout } from "../controllers/auth.controller";

export const authRouter = Router();

authRouter.post("/signup", signup);
authRouter.post("/login", login);
authRouter.post("/refresh", refresh);
authRouter.get("/me", requireAuth, me);
authRouter.post("/change-password", requireAuth, changePassword);
authRouter.post("/logout", requireAuth, logout);
