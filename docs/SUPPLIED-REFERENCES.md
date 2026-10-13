# Supplied reference inspection

## ZIP

The supplied ZIP was extracted into the ignored work/reference-archive directory for static inspection. It contains 220 files (about 23.8 MB): eight large captured HTML pages, 63 JavaScript files, five CSS files, 137 JPEG photos/map tiles, two PNGs, one WebP logo, and four opaque binary files. HTML references Zuniz branding, analytics/ad code, local-storage auth flags, Google tile hosts, and opaque build chunks. There is no source-module tree, package manifest, database schema, test suite, or deployment config. The archive was not executed; its scripts, map tiles, and branding were not reused.

The capture shows Explore, maps, feed, blog, shop, leaderboard, profiles, and messages. User screenshots additionally informed cards, place details, auth dialogs, search, profiles, galleries, and collections. Urbexity implements these as cues within a different brand and component system.

## Logo and screenshots

The supplied Urbexity Logo.png is used as /urbexity-logo.png and /favicon.png. Screenshots were reviewed visually as references and are not copied into production pages.

## Zuniz public pages

The live https://zuniz.com/maps page was reviewed in the browser. It confirms public map discovery, public labels, place counts, authors, descriptions, and map creation. Direct automated fetch of the site root returned 403, so the browser page and user screenshots informed the feature review. No Zuniz source, text, brand, or exact layout was reused.

## Multistreams.tv

The public repository was inspected read-only. Its codebase-memory graph was already indexed. Reviewed auth registration/login, database session access, profile/follow behavior, and the initial D1 users/sessions/follows/blocks/notifications schema. Patterns adapted conceptually: server-side rate limits, password hashes, database-backed opaque sessions, normalized profile relations, and explicit public-field serialization. No Multistreams checkout files were modified.
