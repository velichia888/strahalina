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
estate showcase loses its purpose if buyers must sign up before they can look. Submitting
an inquiry on a listing *does* require a lightweight account (email/password), so the
couple has a real, addressable identity to respond to rather than an anonymous drive-by
form — mirrors treating an inquiry like the first message in a real conversation.

## "Social media" scoped down to a real Updates feed

The user's brief mentioned "social media." A full social network (likes, followers, feeds
of other users) has no real backing here — there's one content-producing account (the
couple), not a network of peers. Scoped down to a real **Updates** feed: the couple posts
dated text+photo updates (new listing, a closed deal, market commentary), visible to
anyone browsing. No fabricated engagement counters (likes/views) anywhere.

## In scope

- Email/password auth (signup, login, refresh, logout) with JWT access + refresh tokens.
- `isAdmin` flag on User — real, backend-enforced, gates listing/update creation and
  inquiry-inbox access. Bootstrapped via seed script, same pattern as the other apps.
- Property/investment listings: title, description, listing type (property vs. investment
  vehicle), price, address/location text, up to 10 photos, status (active/pending/sold),
  and free-form key facts the couple enters themselves (e.g. sqft, ROI %, cap rate) — never
  computed or invented by the app, always attributed as "figures provided by the listing
  owner," not verified financial guidance.
- Public browsing/searching listings (status, type, price range), listing detail with
  photo carousel.
- Updates feed: dated posts by the couple, optionally linked to a listing.
- Inquiries: a signed-in buyer submits a real inquiry tied to a specific listing (name,
  message); the couple/admin sees a real inbox of submitted inquiries and can mark
  responded. Not a live chat — a one-shot inquiry-to-inbox model, since there's no
  evidence a full back-and-forth messaging system is needed for a first pass.
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
- Two-way in-app messaging beyond the inquiry-to-inbox model above.
- Push notifications.
- Any fabricated company details (address, registration numbers, logos, past deal
  specifics) for The One real estate management and investment capital company or the
  Muradyan group beyond what the user has actually supplied.

## Phase 1 exit criterion

A real listing created by the admin account is visible to a signed-out browsing session,
a signed-in buyer account submits a real inquiry on it, and the admin sees that inquiry in
their inbox — provable end-to-end via curl before any iOS work is trusted, then again on
a real device build.
