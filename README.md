# Urbexity

Urbexity is a responsive urban-exploration documentation and discovery platform. It uses an original charcoal-and-red identity with the supplied Urbexity logo. A Cloudflare Worker serves the static interface and versioned API; D1 stores both structured records and image BLOBs; the deployment has no R2 dependency.

## Included

- Explore map with clustered, approximate public markers, place details, category/search filters, and synchronized map/list.
- Discover directory, public profiles, follows/blocks, user collections, community feed, field journal, rankings, notifications, messaging, and a searchable marketplace with seller drafts/publishing/archiving.
- Worker-backed registration, sign-in/out, PBKDF2-SHA-256 password hashes with random salts, secure HTTP-only sessions, email verification/reset links, profile privacy, export, and account deactivation.
- D1 schema for places, moderation, photos, social actions, maps, comments, conversations, reports, API keys, webhook events/deliveries, listings, and audit records.
- D1-backed photo storage with file-signature validation, a 1.8 MB per-image ceiling, private pending moderation, authorization checks, and a 350 MiB application media budget.
- Scoped/revocable bearer API keys and the KITE integration contract.
- Discord outbox with idempotent event IDs, HMAC signatures for generic subscriptions, scheduled retry, and delivery records.

There is no local-storage or mock authentication. No sample place/user statistics are bundled as production data. The directory starts empty until places are submitted and approved.

## Local development

Requirements: Node.js 20+, npm, and a Cloudflare account for production.

1. Install dependencies with npm install.
2. Provision D1 on Cloudflare Workers Free and update the database ID in wrangler.jsonc. No object-storage bucket is required.
3. Apply the local schema with npm run db:local.
4. Start with npm run dev.
5. Validate with npm run check.

Use an ignored .dev.vars file for local secrets. Do not put credentials in wrangler.jsonc, .env.example, or browser files.

## Main routes

Explore / · directory /discover · place /places/:slug · profile /u/:username · collections /maps and /maps/:slug · feed /feed · journal /journal · rankings /leaderboard · market /market · messages /messages · notifications /notifications · settings /settings.

## Documentation

- API.md: routes, scopes, errors, JSON formats
- KITE-INTEGRATION.md: Discord command and embed examples
- DEPLOYMENT.md: Cloudflare provisioning and GitHub Actions
- docs/SUPPLIED-REFERENCES.md: archive, logo, screenshots, Zuniz, and Multistreams inspection

## Safety and privacy

Only approved public places appear in public lists. Private places and collections are checked on every Worker request. Public coordinates are rounded unless the contributor explicitly selected exact public coordinates. Pending photos remain private. A listing is not permission to enter; respect owners, posted rules, and local law.

## External setup status

This workspace has no Cloudflare, email, Discord, OAuth, or GitHub deployment credentials. Deployment is not claimed. Follow DEPLOYMENT.md after provisioning.
