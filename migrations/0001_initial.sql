PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL COLLATE NOCASE UNIQUE,
  username TEXT NOT NULL COLLATE NOCASE UNIQUE,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  avatar_key TEXT,
  banner_key TEXT,
  bio TEXT NOT NULL DEFAULT '',
  location_label TEXT NOT NULL DEFAULT '',
  website_url TEXT NOT NULL DEFAULT '',
  profile_visibility TEXT NOT NULL DEFAULT 'public' CHECK(profile_visibility IN ('public','private')),
  activity_visibility TEXT NOT NULL DEFAULT 'public' CHECK(activity_visibility IN ('public','private','followers')),
  email_verified_at TEXT,
  is_admin INTEGER NOT NULL DEFAULT 0 CHECK(is_admin IN (0,1)),
  deleted_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  expires_at TEXT NOT NULL
);
CREATE INDEX sessions_user_idx ON sessions(user_id);
CREATE INDEX sessions_expiry_idx ON sessions(expires_at);
CREATE TABLE auth_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  purpose TEXT NOT NULL CHECK(purpose IN ('verify_email','password_reset')),
  expires_at TEXT NOT NULL,
  used_at TEXT,
  created_at TEXT NOT NULL
);
CREATE INDEX auth_tokens_lookup_idx ON auth_tokens(token_hash,purpose,expires_at);
CREATE TABLE follows (
  follower_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  followed_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL,
  PRIMARY KEY(follower_id,followed_id), CHECK(follower_id <> followed_id)
);
CREATE TABLE blocks (
  blocker_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL,
  PRIMARY KEY(blocker_id,blocked_id), CHECK(blocker_id <> blocked_id)
);
CREATE TABLE categories (
  slug TEXT PRIMARY KEY,
  label TEXT NOT NULL UNIQUE
);
INSERT INTO categories(slug,label) VALUES
 ('abandoned-building','Abandoned building'),('factory','Factory'),('hospital','Hospital'),('school','School'),('church','Church'),('tunnel','Tunnel'),('infrastructure','Infrastructure'),('industrial','Industrial'),('other','Other');
CREATE TABLE places (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL REFERENCES categories(slug),
  country TEXT NOT NULL DEFAULT '',
  region TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  latitude REAL NOT NULL CHECK(latitude BETWEEN -90 AND 90),
  longitude REAL NOT NULL CHECK(longitude BETWEEN -180 AND 180),
  visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public','private','unlisted')),
  coordinate_precision TEXT NOT NULL DEFAULT 'approximate' CHECK(coordinate_precision IN ('approximate','exact')),
  access_note TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected','removed')),
  views INTEGER NOT NULL DEFAULT 0 CHECK(views >= 0),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX places_public_created_idx ON places(visibility,status,created_at DESC);
CREATE INDEX places_owner_idx ON places(owner_id,created_at DESC);
CREATE INDEX places_category_idx ON places(category,visibility,status);
CREATE INDEX places_geo_idx ON places(latitude,longitude);
CREATE TABLE place_photos (
  id TEXT PRIMARY KEY,
  place_id TEXT NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  object_key TEXT NOT NULL UNIQUE,
  alt_text TEXT NOT NULL DEFAULT '',
  moderation_status TEXT NOT NULL DEFAULT 'pending' CHECK(moderation_status IN ('pending','approved','rejected','removed')),
  created_at TEXT NOT NULL
);
CREATE INDEX place_photos_place_idx ON place_photos(place_id,moderation_status,created_at);
CREATE TABLE tags (id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE COLLATE NOCASE);
CREATE TABLE place_tags (place_id TEXT NOT NULL REFERENCES places(id) ON DELETE CASCADE,tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,PRIMARY KEY(place_id,tag_id));
CREATE TABLE place_likes (user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,place_id TEXT NOT NULL REFERENCES places(id) ON DELETE CASCADE,created_at TEXT NOT NULL,PRIMARY KEY(user_id,place_id));
CREATE TABLE bookmarks (user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,place_id TEXT NOT NULL REFERENCES places(id) ON DELETE CASCADE,created_at TEXT NOT NULL,PRIMARY KEY(user_id,place_id));
CREATE TABLE comments (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  place_id TEXT REFERENCES places(id) ON DELETE CASCADE,
  post_id TEXT REFERENCES feed_posts(id) ON DELETE CASCADE,
  parent_id TEXT REFERENCES comments(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'published' CHECK(status IN ('published','hidden','removed')),
  created_at TEXT NOT NULL
);
CREATE INDEX comments_place_idx ON comments(place_id,status,created_at);
CREATE TABLE custom_maps (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL DEFAULT '',
  visibility TEXT NOT NULL DEFAULT 'private' CHECK(visibility IN ('public','private','unlisted')),
  views INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX maps_public_idx ON custom_maps(visibility,created_at DESC);
CREATE TABLE map_places (map_id TEXT NOT NULL REFERENCES custom_maps(id) ON DELETE CASCADE,place_id TEXT NOT NULL REFERENCES places(id) ON DELETE CASCADE,added_by TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,sort_order INTEGER NOT NULL DEFAULT 0,created_at TEXT NOT NULL,PRIMARY KEY(map_id,place_id));
CREATE TABLE map_follows (map_id TEXT NOT NULL REFERENCES custom_maps(id) ON DELETE CASCADE,user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,created_at TEXT NOT NULL,PRIMARY KEY(map_id,user_id));
CREATE TABLE feed_posts (id TEXT PRIMARY KEY,author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,place_id TEXT REFERENCES places(id) ON DELETE SET NULL,caption TEXT NOT NULL DEFAULT '',visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public','followers')),created_at TEXT NOT NULL);
CREATE INDEX feed_created_idx ON feed_posts(visibility,created_at DESC);
CREATE TABLE post_photos (id TEXT PRIMARY KEY,post_id TEXT NOT NULL REFERENCES feed_posts(id) ON DELETE CASCADE,object_key TEXT NOT NULL UNIQUE,moderation_status TEXT NOT NULL DEFAULT 'pending' CHECK(moderation_status IN ('pending','approved','rejected')),created_at TEXT NOT NULL);
CREATE TABLE post_likes (post_id TEXT NOT NULL REFERENCES feed_posts(id) ON DELETE CASCADE,user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,created_at TEXT NOT NULL,PRIMARY KEY(post_id,user_id));
CREATE TABLE conversations (id TEXT PRIMARY KEY,created_at TEXT NOT NULL,UNIQUE(id));
CREATE TABLE conversation_members (conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,last_read_at TEXT,PRIMARY KEY(conversation_id,user_id));
CREATE TABLE messages (id TEXT PRIMARY KEY,conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,sender_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,body TEXT NOT NULL,created_at TEXT NOT NULL);
CREATE INDEX messages_conversation_idx ON messages(conversation_id,created_at DESC);
CREATE TABLE notifications (id TEXT PRIMARY KEY,user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,actor_id TEXT REFERENCES users(id) ON DELETE SET NULL,type TEXT NOT NULL,entity_id TEXT,read_at TEXT,created_at TEXT NOT NULL);
CREATE INDEX notifications_user_idx ON notifications(user_id,created_at DESC);
CREATE TABLE reports (id TEXT PRIMARY KEY,reporter_id TEXT REFERENCES users(id) ON DELETE SET NULL,target_type TEXT NOT NULL,target_id TEXT NOT NULL,reason TEXT NOT NULL,details TEXT NOT NULL DEFAULT '',status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','reviewing','resolved','dismissed')),created_at TEXT NOT NULL);
CREATE INDEX reports_status_idx ON reports(status,created_at);
CREATE TABLE moderation_actions (id TEXT PRIMARY KEY,admin_id TEXT NOT NULL REFERENCES users(id),target_type TEXT NOT NULL,target_id TEXT NOT NULL,action TEXT NOT NULL,notes TEXT NOT NULL DEFAULT '',created_at TEXT NOT NULL);
CREATE TABLE audit_logs (id TEXT PRIMARY KEY,actor_id TEXT REFERENCES users(id) ON DELETE SET NULL,action TEXT NOT NULL,subject_type TEXT NOT NULL,subject_id TEXT NOT NULL,metadata_json TEXT NOT NULL DEFAULT '{}',created_at TEXT NOT NULL);
CREATE TABLE api_keys (id TEXT PRIMARY KEY,name TEXT NOT NULL,key_hash TEXT NOT NULL UNIQUE,scopes_json TEXT NOT NULL,created_by TEXT NOT NULL REFERENCES users(id),last_used_at TEXT,revoked_at TEXT,created_at TEXT NOT NULL);
CREATE TABLE webhook_subscriptions (id TEXT PRIMARY KEY,name TEXT NOT NULL,target_url TEXT NOT NULL,events_json TEXT NOT NULL,secret_hash TEXT NOT NULL,active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1)),created_by TEXT NOT NULL REFERENCES users(id),created_at TEXT NOT NULL);
CREATE TABLE webhook_deliveries (id TEXT PRIMARY KEY,subscription_id TEXT REFERENCES webhook_subscriptions(id) ON DELETE CASCADE,event_type TEXT NOT NULL,payload_json TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','delivered','failed')),attempts INTEGER NOT NULL DEFAULT 0,next_attempt_at TEXT NOT NULL,last_status_code INTEGER,last_error TEXT,created_at TEXT NOT NULL,delivered_at TEXT,UNIQUE(subscription_id,event_type,id));
CREATE INDEX webhook_due_idx ON webhook_deliveries(status,next_attempt_at);
CREATE TABLE domain_events (id TEXT PRIMARY KEY,event_type TEXT NOT NULL,entity_id TEXT NOT NULL,payload_json TEXT NOT NULL,created_at TEXT NOT NULL,UNIQUE(event_type,entity_id));
CREATE TABLE listings (id TEXT PRIMARY KEY,seller_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,title TEXT NOT NULL,description TEXT NOT NULL,category TEXT NOT NULL,price_cents INTEGER NOT NULL CHECK(price_cents>=0),currency TEXT NOT NULL DEFAULT 'USD',status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published','archived')),created_at TEXT NOT NULL,updated_at TEXT NOT NULL);
CREATE TABLE transactions (id TEXT PRIMARY KEY,listing_id TEXT NOT NULL REFERENCES listings(id),buyer_id TEXT NOT NULL REFERENCES users(id),provider TEXT NOT NULL,status TEXT NOT NULL,provider_reference TEXT,created_at TEXT NOT NULL);
CREATE TABLE rate_limits (key TEXT PRIMARY KEY,count INTEGER NOT NULL,window_started_at INTEGER NOT NULL,expires_at INTEGER NOT NULL);
