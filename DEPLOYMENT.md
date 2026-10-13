# Cloudflare deployment

The Cloudflare Worker serves both the browser application and API. GitHub Pages is not used for runtime because it cannot execute D1/R2 business logic.

## Provision

1. Create a Cloudflare D1 database named urbexity-db.
2. Create an R2 bucket named urbexity-media.
3. Replace REPLACE_WITH_D1_DATABASE_ID in wrangler.jsonc with the real database ID.
4. Set APP_ORIGIN to the exact production origin.
5. Choose a tile provider and set PUBLIC_MAP_TILE_URL. Retain attribution and follow its terms; for production volume use a tile service intended for production traffic.

## Migrations and local development

    npm install
    npm run db:local
    npm run build
    npm run db:remote

Review migrations before applying to any existing database. Migration 0001 is for a new Urbexity database.

Create an ignored .dev.vars for local values, then run npm run dev. Local sessions use Secure cookie attributes; modern browsers treat localhost as secure. Use test-only accounts and local D1/R2.

## Worker configuration

Set non-secret variables in Wrangler or Cloudflare:

- APP_ORIGIN
- PUBLIC_MAP_TILE_URL
- ADMIN_EMAILS: bootstrap admin email list. An account receives administrator access only after verifying a matching email address.
- EMAIL_FROM: verified sender address.
- Optional ASSET_BASE_URL if serving media through a custom R2 domain.

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

Keep the R2 bucket private behind the Worker /media route. Resend must authorize EMAIL_FROM. Verify email flows in staging before relying on account recovery.

## Discord delivery

DISCORD_WEBHOOK_URL is stored as a Cloudflare secret; it is never returned to the browser. Delivery status and attempts are stored in webhook_deliveries. Cron runs every five minutes with at most eight attempts. Check those rows before reporting delivery.

Service webhook subscriptions use POST /api/v1/admin/webhooks and HMAC signatures. Save the returned signingSecret in the receiver and verify the exact-body signature.

## Separate GitHub repository

Create a separate repository named urbexity, then add it as this checkout's origin and push the reviewed branch. This checkout can be initialized independently; GitHub permissions are required to create and push. Never point the remote to multistreams.tv.
