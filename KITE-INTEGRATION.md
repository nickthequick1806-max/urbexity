# KITE Discord integration

Urbexity exposes public versioned lookups for KITE. Store the service key in the bot's server-side secret store, never in browser JavaScript. Have an Urbexity administrator issue a key with users:read, places:read, stats:read, and leaderboards:read.

    GET https://urbexity.example/api/v1/users/username
    Authorization: Bearer urbx_REDACTED
    Accept: application/json

Public reads work without a key, but a scoped key provides integration rate limiting and an audit trail. Limit: 120 requests/minute. Handle 401, 403, 404, and 429 with concise messages and bounded retry. Never send keys in URLs.

| Suggested command | Request | Scope | Embed fields |
|---|---|---|---|
| /urbex-user username | GET /users/{username} | users:read | Explorer, bio, joined date, places, followers, photos |
| Recent user uploads | GET /users/{username}/places | users:read | Title, category, broad area, link |
| User collections | GET /users/{username}/maps | users:read | Map title, count, URL |
| /urbex-leaderboard period category | GET /leaderboards?period=month&category=places | leaderboards:read | Rank, username, score, scoring method |
| /urbex-stats | GET /stats | stats:read | Public users, approved places, maps, photos |
| /urbex-place place_id | GET /places/{id} | places:read | Title, category, broad area, uploader, approved photos |
| /urbex-latest | GET /places?sort=newest&limit=5 | places:read | Recent approved public places |
| /urbex-user-activity username | GET /users/{username}/activity | users:read | Public place/map activity |

Example user response:

    { "data": { "id": "2dc2d...", "username": "fieldnotes", "bio": "Documenting historic infrastructure with permission.", "avatarUrl": null, "location": "Midwest", "joinedAt": "2026-10-13T15:00:00.000Z", "stats": { "places": 7, "followers": 18, "following": 11, "photos": 21, "comments": 9 } } }

Embed safety: escape user content; use only API-returned URLs; do not infer a more precise location; exclude private, pending, removed, or blocked content. Add: “A listing is not permission to enter. Follow posted rules and local law.” Keep output concise and link to Urbexity.

These docs describe the API contract. No KITE command has been installed or tested at kite.onl.
