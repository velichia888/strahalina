import { Router } from "express";
import { authRouter } from "./auth.routes";
import { listingRouter } from "./listing.routes";
import { listingConversationRouter, conversationRouter } from "./conversation.routes";
import { updateRouter } from "./update.routes";

export const apiRouter = Router();

apiRouter.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

apiRouter.use("/auth", authRouter);
apiRouter.use("/listings", listingRouter);
apiRouter.use("/listings", listingConversationRouter);
apiRouter.use("/conversations", conversationRouter);
apiRouter.use("/updates", updateRouter);
