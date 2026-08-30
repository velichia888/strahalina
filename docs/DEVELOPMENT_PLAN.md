# Development Plan

1. Foundation — scaffold, docs, no code. (this step)
2. Backend skeleton — `User`, auth endpoints, provable via curl.
3. Listings — CRUD (admin-only writes, public reads), photo upload.
4. Updates feed — CRUD (admin-only writes, public reads).
5. Inquiries — signed-in submission, admin inbox + mark-responded.
6. Seed script — one admin account, a handful of real-shaped demo listings/updates.
7. iOS app — scaffold → Auth → Browse/Listing Detail → Updates → Inquiries → Create
   Listing/Update (admin) → Profile/Settings.
8. Deployment/CI — Render blueprint, Codemagic `ios-simulator` then
   `ios-device-unsigned`. Not done in this pass — left for the user to greenlight, same
   as every other app this session.

## Phase 1 milestone

Admin creates a listing with photos → it's visible in a signed-out browse session → a
buyer signs up, views the listing, submits an inquiry → admin sees it in their inbox and
marks it responded. No payment code path reachable anywhere.
