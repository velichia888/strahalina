import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { startConversation, listConversations, listMessages, postMessage, markConversationRead } from "../controllers/conversation.controller";

// Mounted at /listings/:id/conversations — buyer starts a thread.
export const listingConversationRouter = Router({ mergeParams: true });
listingConversationRouter.post("/:id/conversations", requireAuth, startConversation);

// Mounted at /conversations — buyer sees own threads, admin sees all.
export const conversationRouter = Router();
conversationRouter.get("/", requireAuth, listConversations);
conversationRouter.get("/:id/messages", requireAuth, listMessages);
conversationRouter.post("/:id/messages", requireAuth, postMessage);
conversationRouter.post("/:id/read", requireAuth, markConversationRead);
