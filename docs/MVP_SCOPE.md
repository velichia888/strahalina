# Phase 1 MVP Scope

## Architecture call: real backend, not local-only

Unlike Tend (a single-user local habit tracker with no second party), Strahalina is a
producer/consumer app: the couple curates listings and updates; buyers/investors — people
who did not create that content — browse it and reach out. That split requires a real
backend so content persists for and is visible to someone other than its author. Backend
mirrors the proven myemptycloset/Car Hopping stack: Node.js + TypeScript + Express +
Prisma + PostgreSQL, JWT access+refresh auth (refresh rotates both tokens), bcrypt, zod
validation, StorageProvider abstraction for listing photos.

**Auth split**: the couple (or an admin role) authenticates to create/manage listings and
updates. Public browsing (listings, updates, listing detail) requires no account — a real
estate showcase loses its purpose if buyers must sign up before they can look. Messaging a
listing *does* require a lightweight account (email/password), so the couple has a real,
addressable identity to reply to rather than an anonymous drive-by form.

**Messaging model**: unlike myemptycloset/Car Hopping (peer-to-peer marketplaces where
every listing has one specific seller), Strahalina's listings are jointly managed by the
couple via the `isAdmin` flag, not owned by an individual user. So a `Conversation` has a
specific buyer but no specific "seller" — any admin can see and reply to any conversation,
since the couple jointly handles all listings. A buyer can only see/post to their own
threads.

## "Social media" scoped down to a real Updates feed

The user's brief mentioned "social media." A full social network (likes, followers, feeds
of other users) has no real backing here — there's one content-producing account (the
couple), not a network of peers. Scoped down to a real **Updates** feed: the couple posts
dated text+photo updates (new listing, a closed deal, market commentary), visible to
anyone browsing. No fabricated engagement counters (likes/views) anywhere.

## In scope

- Email/password auth (signup, login, refresh, logout) with JWT access + refresh tokens.
- `isAdmin` flag on User — real, backend-enforced, gates listing/update creation and
  admin-wide conversation access. Bootstrapped via seed script, same pattern as the other
  apps.
- Property/investment listings: title, description, listing type (property vs. investment
  vehicle), price, address/location text, up to 10 photos, status (active/pending/sold),
  and free-form key facts the couple enters themselves (e.g. sqft, ROI %, cap rate) — never
  computed or invented by the app, always attributed as "figures provided by the listing
  owner," not verified financial guidance.
- Public browsing/searching listings (status, type, price range), listing detail with
  photo carousel.
- Updates feed: dated posts by the couple, optionally linked to a listing.
- Real two-way messaging: a signed-in buyer starts a conversation on a listing; the
  couple/admin sees every conversation across every listing and can reply; the buyer sees
  the reply in the same thread. One conversation per (listing, buyer) pair. Any admin can
  reply to any conversation — listings aren't individually owned, so there's no
  per-listing "seller" to route messages to.
- Backend deployed to Render; iOS built via Codemagic (simulator, then device-unsigned for
  Sideloadly).

## Explicitly out of scope (deferred to Phase 2+)

- Any payment code, escrow, or deposit handling.
- Real followers/likes/comments, or any social feature without a real per-user identity
  behind it.
- Investment-return calculators, valuation estimates, or any number the app computes
  itself and presents as financial advice — only numbers the couple explicitly entered.
- Verification badges, "as seen in" press mentions, or testimonials without a real
  submission path.
- Push notifications.
- Any fabricated company details (address, registration numbers, logos, past deal
  specifics) for The One real estate management and investment capital company or the
  Muradyan group beyond what the user has actually supplied.

## Phase 1 exit criterion

A real listing created by the admin account is visible to a signed-out browsing session, a
signed-in buyer account starts a real conversation on it, the admin sees and replies to it
in their conversation list, and the buyer sees the reply — provable end-to-end via curl
before any iOS work is trusted, then again on a real device build.
