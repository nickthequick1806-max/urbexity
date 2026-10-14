# Cloudflare deployment

The Cloudflare Worker serves both the browser application and API. GitHub Pages is not used for runtime because it cannot execute the D1-backed business logic.

## Provision

1. The Urbexity D1 database is provisioned as `urbexity-db`; its ID is in `wrangler.jsonc`.
2. `APP_ORIGIN` may remain empty for the default `workers.dev` hostname; the Worker derives its request origin for same-origin checks and account links. Set it to the exact production origin only when using a custom domain or separate frontend.
4. Choose a tile provider and set PUBLIC_MAP_TILE_URL. Retain attribution and follow its terms; for production volume use a tile service intended for production traffic.

Use Cloudflare Workers Free and D1 only. Uploaded image bytes are stored as D1 BLOBs. Each image is limited to 1.8 MB to remain under D1's 2,000,000-byte BLOB/row limit. An application guard caps all image BLOBs at 350 MiB, leaving space for relational data in the 500 MB free-plan database. Cloudflare currently documents a 5 GB total D1 account storage allowance on Workers Free; other databases in the same account share it. When free-plan daily D1 limits are reached, queries fail until reset rather than becoming paid overage, so the app may become temporarily unavailable. See [D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/) and [D1 limits](https://developers.cloudflare.com/d1/platform/limits/).

## Migrations and local development

    npm install
    npm run db:local
    npm run build
    npm run db:remote

Review migrations before applying to any existing database. Migration 0001 is for a new Urbexity database.

Create an ignored .dev.vars for local values, then run npm run dev. Local sessions use Secure cookie attributes; modern browsers treat localhost as secure. Use test-only accounts and local D1.

## Worker configuration

Set non-secret variables in Wrangler or Cloudflare:

- APP_ORIGIN
- PUBLIC_MAP_TILE_URL
- ADMIN_EMAILS: bootstrap admin email list. An account receives administrator access only after verifying a matching email address.
- EMAIL_FROM: verified sender address.

Install secrets using npx wrangler secret put NAME:

- RESEND_API_KEY: enables verification and password-reset email.
- DISCORD_WEBHOOK_URL: optional direct Discord channel webhook. It is server-only and notices are queued only after public place approval.

Google OAuth and Turnstile are not implemented in this initial build; do not configure credentials for inactive flows.

## Deploy and verify

    npm run check
    npm run build
    npm run deploy

After deployment, verify /api/health, registration and email delivery, login/logout, private-place rejection, public-place moderation, photo moderation, and a webhook delivery/retry in the intended account. A local build is not proof of deployment.

## GitHub Actions

Add repository secrets CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID. The workflow tests and dry-run bundles before deployment on pushes to main. D1 IDs and Worker variables must already be configured.

Media BLOBs are served through the Worker /media route with per-object authorization. Resend must authorize EMAIL_FROM. Verify email flows in staging before relying on account recovery.

## Discord delivery

DISCORD_WEBHOOK_URL is stored as a Cloudflare secret; it is never returned to the browser. Delivery status and attempts are stored in webhook_deliveries. Cron runs every five minutes with at most eight attempts. Check those rows before reporting delivery.

Service webhook subscriptions use POST /api/v1/admin/webhooks and HMAC signatures. Save the returned signingSecret in the receiver and verify the exact-body signature.

## Separate GitHub repository

Create a separate repository named urbexity, then add it as this checkout's origin and push the reviewed branch. This checkout can be initialized independently; GitHub permissions are required to create and push. Never point the remote to multistreams.tv.
