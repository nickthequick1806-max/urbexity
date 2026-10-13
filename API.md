# Urbexity API v1

Base path: /api/v1. JSON errors use an error object with stable code and message fields. Public read endpoints work without a key; a scoped bearer key is recommended for integrations. Keys are never accepted in query strings.

## Authentication

Browser sessions use a random token in a Secure, HttpOnly, SameSite=Lax cookie. Only its SHA-256 digest is stored in D1. Passwords use PBKDF2-SHA-256 with 310,000 iterations and a per-account random salt.

| Method | Route | Purpose |
|---|---|---|
| POST | /auth/register | username, email, password (12–128 chars) |
| POST | /auth/login | login, password; sets cookie |
| POST | /auth/logout | Invalidates current session |
| GET | /auth/me | Current session user or null |
| POST | /auth/verify | Sends verification email |
| GET | /auth/verify?token=... | Single-use email verification |
| POST | /auth/reset/request | Generic response to avoid account enumeration |
| POST | /auth/reset | Single-use token and new password |

Email delivery uses Resend when RESEND_API_KEY is installed. Without it, verification/reset emails cannot be delivered.

## Public reads

| Method | Route | Parameters / response |
|---|---|---|
| GET | /health | Worker/D1/R2 binding status |
| GET | /config | Public tile URL and attribution |
| GET | /stats | Live public user/place/map/photo totals |
| GET | /categories | Supported place categories |
| GET | /places | page, limit (max 48), q, category, region, sort=newest/oldest/views/likes |
| GET | /places/{id-or-slug} | Approved public or unlisted detail |
| GET | /places/{id}/comments | Published community notes |
| GET | /users/{username} | Public profile and counts |
| GET | /users/{username}/places | Approved public uploads |
| GET | /users/{username}/maps | Public maps |
| GET | /users/{username}/activity | Visibility-filtered activity |
| GET | /maps | Public maps, page and limit |
| GET | /maps/{id-or-slug} | Public/unlisted map; private map requires owner |
| GET | /feed | Public posts, page and limit |
| GET | /leaderboards | period=week/month/year/all, category=places/views/photos/likes |
| GET | /search | q; public places, users, and maps |
| GET | /market | Published listings; checkoutEnabled is false |

Example place listing:

    { "data": [{ "id": "8f62f...", "title": "Community documented place", "category": "factory", "latitude": 39.8, "longitude": -84.2, "views": 12, "likes": 3, "coverUrl": null }], "pagination": { "page": 1, "limit": 24, "total": 1, "pages": 1 } }

Approximate public coordinates are rounded to one decimal place. Exact public coordinates are returned only when a contributor explicitly opted in. Private map contents, pending moderation data, and private profile details are not returned publicly.

## Session-only writes

Mutating browser requests need a session cookie and same-site Origin.

| Method | Route | Purpose |
|---|---|---|
| GET/PATCH/DELETE | /profile | Own settings, update privacy/profile, confirmed deactivation |
| GET | /profile/export | Own profile/content/social-data export |
| POST | /places | Submit place; starts pending moderation |
| PATCH/DELETE | /places/{id} | Owner/admin edits |
| POST | /places/{id}/photos | Multipart file, JPEG/PNG/WebP/AVIF, max 8 MiB |
| POST | /places/{id}/like or /bookmark | Toggle engagement |
| GET/POST | /places/{id}/comments | Read or add note |
| POST | /users/{username}/follow or /block | Toggle social relationship |
| GET/POST | /maps | List or create a collection |
| POST | /maps/{id}/places | Add a location (owner only) |
| DELETE | /maps/{id}/places/{placeId} | Remove a location (owner only) |
| GET/POST | /feed | Read or create a text post |
| GET/POST | /messages | Private conversations |
| GET | /messages/{conversationId} | Participant only |
| GET/POST | /notifications | Own notifications / mark all read |
| POST | /reports | Submit a moderation/privacy report |
| GET/POST | /market | Read listings or create a draft |

## API keys

An administrator creates a key at POST /admin/api-keys and revokes at POST /admin/api-keys/{id}/revoke. The raw key is returned once and D1 stores its SHA-256 digest. Send Authorization: Bearer urbx_... . Keys are limited to 120 requests per minute.

Scopes: users:read, places:read, stats:read, leaderboards:read, moderation:write, webhooks:write. Missing scope returns 403 insufficient_scope; invalid/revoked keys return 401 invalid_api_key.

Admin moderation routes: GET /admin/moderation, POST /admin/places/{id}/approve, POST /admin/places/{id}/reject, and GET /admin/reports. Use an administrator session or key with moderation:write.

## Webhooks

Create an outgoing subscription at POST /admin/webhooks with name, HTTPS url, and event names. The response includes a one-time signingSecret. Each delivery includes X-Urbexity-Event, X-Urbexity-Delivery, and X-Urbexity-Signature: sha256=<hex>, an HMAC-SHA-256 over the exact JSON body. Verify before acting. Retries run on a five-minute schedule with exponential backoff, up to eight attempts. Current events are place.created, place.approved, and map.published; public place notification is queued only after approval.

## Common errors

authentication_required, admin_required, invalid_json, invalid_email, invalid_username, invalid_password, account_exists, invalid_credentials, token_invalid, invalid_coordinates, invalid_category, place_not_found, map_not_found, not_owner, invalid_file_size, unsupported_image, rate_limited, invalid_api_key, insufficient_scope, origin_forbidden, route_not_found, internal_error.
