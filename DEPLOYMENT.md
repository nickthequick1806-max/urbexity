# Deployment

## Architecture

- The public `urbexity` GitHub repository publishes `public/` to GitHub Pages at `https://nickthequick1806-max.github.io/urbexity/`.
- `urbexity-api` is a Cloudflare Worker backend. It is bound to the separate `urbexity-db` D1 database; the Worker also serves D1-backed image BLOBs. There is no R2 binding or R2 code.
- The Pages frontend calls the Worker using the `URBEXITY_API_ORIGIN` GitHub repository variable. The Worker `APP_ORIGIN` is the exact Pages origin and cross-origin requests are credentialed and allowlisted. The frontend uses the `/urbexity/` Pages project base path and an SPA `404.html` fallback.

## Provisioned resources

The Cloudflare account already contains a dedicated D1 database named `urbexity-db`, ID `36b67714-6b53-49c1-9af7-78c0d460fc7f`. Migration `0001_initial.sql` was applied in the D1 console and recorded in `d1_migrations`; no data from Multistreams was used. The Worker is not deployed yet.

Cloudflare Workers Free and D1 are the only application storage. Each image is limited to 1.8 MB to remain under D1's 2,000,000-byte BLOB/row limit. The application caps stored images at 350 MiB, leaving room for relational records. D1 storage and daily query limits are account-wide; requests can fail when free plan limits are reached. Review current [D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/) and [D1 limits](https://developers.cloudflare.com/d1/platform/limits/).

## Remaining deployment setup

1. Enable GitHub Pages for this repository with **Build and deployment → Source: GitHub Actions**.
2. Configure the Cloudflare Worker deploy secrets in the GitHub repository: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. Limit the token to this account's Worker deployment needs; never commit it.
3. Configure the GitHub repository variable `URBEXITY_API_ORIGIN` to the deployed Worker origin, for example `https://urbexity-api.<your-workers-subdomain>.workers.dev`.
4. Run the Worker deploy workflow and Pages workflow from `main`. Verify the health endpoint and Pages frontend, then confirm API responses include credentialed CORS only for the Pages origin.
5. For reliable cross-site account cookies, a first-party custom domain shared by frontend and API is recommended. The current GitHub Pages and `workers.dev` hosts are separate sites; some browsers block third-party cookies even when the API sets `SameSite=None`.
6. Select a tile provider for expected production traffic. The default OpenStreetMap tile URL requires attribution and should not be used at unapproved volume.

Create an ignored `.dev.vars` for local values, then run `npm run dev`. Local cookies use `Secure`; modern browsers treat localhost as secure. Use test-only accounts and the local D1 database.

## Email, admin, and Discord

Set `ADMIN_EMAILS` to the intended administrator emails. An account receives administrator access only after verifying a matching address. Set `EMAIL_FROM` to a verified sender and store `RESEND_API_KEY` as a Cloudflare Worker secret to enable registration verification and password recovery. Without the email provider, those messages are not sent.

Set `DISCORD_WEBHOOK_URL` as a Cloudflare Worker secret to deliver the optional approval notices. Generic service subscriptions are configured through the admin API; store the returned HMAC signing secret at the receiver. Check `webhook_deliveries` for actual delivery status. No email or Discord delivery is claimed until verified.

Google OAuth and Turnstile are not implemented in this build. Payment checkout is disabled. KITE API endpoints and scoped keys are implemented, but the Discord bot commands still need to be installed in the bot project.

## Validate and verify

    npm ci
    npm run check
    npm run build

The GitHub Actions workflow validates and dry-run bundles the Worker before deployment. The Pages workflow deploys the static frontend. After both succeed, verify `/api/health`, registration and email delivery, login/logout, private-place rejection, moderation, approved photo reads, and webhook delivery/retry in the intended account. A local build or a successful Pages publish alone is not proof of live backend functionality.
