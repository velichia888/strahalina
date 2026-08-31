import { Request, Response } from "express";
import { z } from "zod";
import { prisma } from "../db/prisma";
import { HttpError } from "../utils/HttpError";
import { asyncHandler } from "../utils/asyncHandler";

function serializeConversation(conversation: {
  id: string;
  kind: string;
  listingId: string | null;
  buyerId: string;
  createdAt: Date;
  updatedAt: Date;
  listing?: { id: string; title: string } | null;
  buyer?: { id: string; displayName: string; email: string };
  messages?: { id: string; body: string; senderId: string; createdAt: Date; readAt: Date | null }[];
}) {
  const lastMessage = conversation.messages?.[conversation.messages.length - 1];
  return {
    id: conversation.id,
    kind: conversation.kind,
    listingId: conversation.listingId,
    listing: conversation.listing,
    buyer: conversation.buyer,
    createdAt: conversation.createdAt,
    updatedAt: conversation.updatedAt,
    lastMessage: lastMessage
      ? {
          id: lastMessage.id,
          body: lastMessage.body,
          senderId: lastMessage.senderId,
          createdAt: lastMessage.createdAt,
          readAt: lastMessage.readAt,
        }
      : null,
  };
}

function serializeMessage(message: {
  id: string;
  conversationId: string;
  senderId: string;
  body: string;
  createdAt: Date;
  readAt: Date | null;
}) {
  return {
    id: message.id,
    conversationId: message.conversationId,
    senderId: message.senderId,
    body: message.body,
    createdAt: message.createdAt,
    readAt: message.readAt,
  };
}

// Buyer can only touch their own conversation; any admin can touch any
// conversation, since listings are jointly managed, not individually
// owned. Returns the conversation row (never null — throws first).
async function requireAdminOrConversationBuyer(conversationId: string, userId: string) {
  const conversation = await prisma.conversation.findUnique({ where: { id: conversationId } });
  if (!conversation) {
    throw new HttpError(404, "Conversation not found");
  }
  if (conversation.buyerId === userId) {
    return conversation;
  }
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user?.isAdmin) {
    throw new HttpError(403, "You do not have access to this conversation");
  }
  return conversation;
}

const startConversationSchema = z.object({
  message: z.string().min(1).max(2000),
});

// Mounted at POST /listings/:id/conversations — find-or-create the
// buyer's conversation for this listing, then post the first message.
// Buyer-only: an admin starting a "conversation with themselves" isn't
// a real use case here, since admins already see every conversation.
export const startConversation = asyncHandler(async (req: Request, res: Response) => {
  const body = startConversationSchema.parse(req.body);

  const listing = await prisma.listing.findUnique({ where: { id: req.params.id } });
  if (!listing) {
    throw new HttpError(404, "Listing not found");
  }

  const requester = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (requester?.isAdmin) {
    throw new HttpError(400, "Admins respond to existing conversations rather than starting new ones");
  }

  const conversation = await prisma.conversation.upsert({
    where: { listingId_buyerId: { listingId: listing.id, buyerId: req.userId! } },
    create: { kind: "listing", listingId: listing.id, buyerId: req.userId! },
    update: {},
  });

  const message = await prisma.message.create({
    data: { conversationId: conversation.id, senderId: req.userId!, body: body.message },
  });

  await prisma.conversation.update({ where: { id: conversation.id }, data: { updatedAt: new Date() } });

  res.status(201).json({ conversation: serializeConversation(conversation), message: serializeMessage(message) });
});

const consultationSchema = z.object({
  fullName: z.string().min(1).max(120),
  email: z.string().email(),
  phone: z.string().min(1).max(40),
  message: z.string().min(1).max(2000),
});

// Mounted at POST /conversations/consultation — the mockup's "Book a
// Consultation" form. Not a separate data model: composes the
// structured fields into the first message of a real, general
// (listingId = null) conversation, reusing the same Conversation/
// Message system as everything else. Always creates a fresh
// conversation (unlike the per-listing upsert) since each consultation
// request is its own episodic ask, not an ongoing thread to merge into.
export const startConsultation = asyncHandler(async (req: Request, res: Response) => {
  const body = consultationSchema.parse(req.body);

  const requester = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (requester?.isAdmin) {
    throw new HttpError(400, "Admins respond to existing conversations rather than starting new ones");
  }

  const conversation = await prisma.conversation.create({
    data: { kind: "consultation", buyerId: req.userId! },
  });

  const composedBody = [
    "Consultation Request",
    "",
    `Name: ${body.fullName}`,
    `Email: ${body.email}`,
    `Phone: ${body.phone}`,
    "",
    body.message,
  ].join("\n");

  const message = await prisma.message.create({
    data: { conversationId: conversation.id, senderId: req.userId!, body: composedBody },
  });

  res.status(201).json({ conversation: serializeConversation(conversation), message: serializeMessage(message) });
});

const investorInquirySchema = z.object({
  fullName: z.string().min(1).max(120),
  email: z.string().email(),
  phone: z.string().min(1).max(40),
  investmentRange: z.string().min(1).max(60),
  preferredStrategy: z.string().min(1).max(60),
  additionalInfo: z.string().max(2000).optional(),
});

// Mounted at POST /conversations/investor-inquiry — same real
// Conversation/Message system, different structured fields composed
// into the opening message.
export const startInvestorInquiry = asyncHandler(async (req: Request, res: Response) => {
  const body = investorInquirySchema.parse(req.body);

  const requester = await prisma.user.findUnique({ where: { id: req.userId! } });
  if (requester?.isAdmin) {
    throw new HttpError(400, "Admins respond to existing conversations rather than starting new ones");
  }

  const conversation = await prisma.conversation.create({
    data: { kind: "investor_inquiry", buyerId: req.userId! },
  });

  const composedBody = [
    "Investor Inquiry",
    "",
    `Name: ${body.fullName}`,
    `Email: ${body.email}`,
    `Phone: ${body.phone}`,
    `Investment Range: ${body.investmentRange}`,
    `Preferred Strategy: ${body.preferredStrategy}`,
    ...(body.additionalInfo ? ["", body.additionalInfo] : []),
  ].join("\n");

  const message = await prisma.message.create({
    data: { conversationId: conversation.id, senderId: req.userId!, body: composedBody },
  });

  res.status(201).json({ conversation: serializeConversation(conversation), message: serializeMessage(message) });
});

// Mounted at GET /conversations — buyers see only their own threads;
// admins see every conversation across every listing.
export const listConversations = asyncHandler(async (req: Request, res: Response) => {
  const requester = await prisma.user.findUnique({ where: { id: req.userId! } });

  const conversations = await prisma.conversation.findMany({
    where: requester?.isAdmin ? {} : { buyerId: req.userId! },
    include: {
      listing: { select: { id: true, title: true } },
      buyer: { select: { id: true, displayName: true, email: true } },
      messages: { orderBy: { createdAt: "desc" }, take: 1 },
    },
    orderBy: { updatedAt: "desc" },
  });

  res.json({ conversations: conversations.map(serializeConversation) });
});

// Mounted at GET /conversations/:id/messages
export const listMessages = asyncHandler(async (req: Request, res: Response) => {
  await requireAdminOrConversationBuyer(req.params.id, req.userId!);

  const messages = await prisma.message.findMany({
    where: { conversationId: req.params.id },
    orderBy: { createdAt: "asc" },
  });

  res.json({ messages: messages.map(serializeMessage) });
});

const postMessageSchema = z.object({
  body: z.string().min(1).max(2000),
});

// Mounted at POST /conversations/:id/messages
export const postMessage = asyncHandler(async (req: Request, res: Response) => {
  await requireAdminOrConversationBuyer(req.params.id, req.userId!);
  const parsed = postMessageSchema.parse(req.body);

  const message = await prisma.message.create({
    data: { conversationId: req.params.id, senderId: req.userId!, body: parsed.body },
  });

  await prisma.conversation.update({ where: { id: req.params.id }, data: { updatedAt: new Date() } });

  res.status(201).json({ message: serializeMessage(message) });
});

// Mounted at POST /conversations/:id/read — marks every message NOT
// sent by the caller as read (i.e. "I've read the other side's
// messages"), mirroring a normal chat read-receipt.
export const markConversationRead = asyncHandler(async (req: Request, res: Response) => {
  await requireAdminOrConversationBuyer(req.params.id, req.userId!);

  await prisma.message.updateMany({
    where: { conversationId: req.params.id, senderId: { not: req.userId! }, readAt: null },
    data: { readAt: new Date() },
  });

  res.json({ ok: true });
});
