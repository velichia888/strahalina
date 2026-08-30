# Architecture

## Stack

- **Backend**: Node.js + TypeScript + Express + Prisma + PostgreSQL, deployed to Render.
- **iOS**: SwiftUI, XcodeGen-generated project (no hand-maintained .xcodeproj), deployment
  target iOS 16.0.
- **CI**: Codemagic — `ios-simulator` for compiler feedback, `ios-device-unsigned` for
  Sideloadly installs. No App Store Connect workflow yet.

## Data model

- `User` — email, passwordHash, displayName, `isAdmin` (real, backend-enforced).
- `Listing` — title, description, `type` (PROPERTY | INVESTMENT), price, location text,
  status (ACTIVE | PENDING | SOLD), `keyFacts` (couple-entered free-form label/value
  pairs, e.g. "Cap rate" → "6.2%" — never computed by the server).
- `ListingPhoto` — ordered photos per listing, via the StorageProvider abstraction.
- `Update` — dated post by the couple, optional link to a `Listing`, optional photo.
- `Inquiry` — buyer (User), listing, message, `respondedAt` (nullable, set by admin).

## Auth

JWT access (short TTL) + refresh (long TTL, rotates on use) tokens, bcrypt password
hashing, zod request validation — identical pattern to myemptycloset/Car Hopping.
`requireAdmin` middleware gates listing/update writes and the inquiry inbox.
`requireAuth` (any signed-in user) gates inquiry submission. Browsing endpoints are
public — no auth required.

## Storage

Same `StorageProvider` abstraction as the other apps: local disk in development,
S3-compatible in production, HMAC-signed local URLs for dev.

## iOS structure

Mirrors myemptycloset/Car Hopping: `App/`, `Auth/` (Keychain-backed session store),
`Configuration/`, `Models/`, `Networking/` (actor-based `APIClient`, coalesced
refresh-and-retry-once-on-401), `Shared/Components/`, `Features/{Auth, Browse,
ListingDetail, CreateListing, Updates, Inquiries, Profile, Root}`.

Known iOS16 pitfalls avoided throughout (burned into every app this session):
`navigationDestination(item:)` is iOS17+ only (isActive-driven `NavigationLink` instead);
`ForEach` over non-`Identifiable` enums needs explicit `id: \.self`; `.onChange(of:)` uses
the single-parameter iOS16 closure form only; `GENERATE_INFOPLIST_FILE: NO` with a
hand-written `Info.plist` requiring manual `CFBundleExecutable`/`CFBundleIdentifier`/
`CFBundleName`.

## Deferred (Phase 2+)

Stripe Connect or any payment rail, real messaging beyond inquiry-to-inbox, push
notifications, admin dashboard (optional, non-blocking — same call made for the other
apps).
