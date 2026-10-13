import test from "node:test";
import assert from "node:assert/strict";
import worker from "../src/worker.js";

function dbStub({ first = () => null, all = () => ({ results: [] }), onRun = () => ({ success: true }) } = {}) {
  return {
    prepare(sql) {
      let values = [];
      const query = {
        bind(...args) { values = args; return query; },
        first() { return first(sql, values); },
        all() { return all(sql, values); },
        run() { return Promise.resolve(onRun(sql, values)); }
      };
      return query;
    },
    batch() { return Promise.resolve([]); }
  };
}
function env(database = dbStub()) {
  return {
    DB: database,
    ASSETS: { fetch: async () => new Response("spa") },
    APP_ORIGIN: "https://urbexity.example",
    PUBLIC_MAP_TILE_URL: "https://tiles.example/{z}/{x}/{y}.png"
  };
}

test("health endpoint reports service bindings without exposing configuration", async () => {
  const response = await worker.fetch(new Request("https://urbexity.example/api/health"), env());
  assert.equal(response.status, 200);
  const payload = await response.json();
  assert.equal(payload.ok, true);
  assert.equal(payload.database, true);
  assert.equal(payload.media, true);
  assert.equal(JSON.stringify(payload).includes("tiles.example"), false);
});

test("public places endpoint returns an empty, paginated live result", async () => {
  const database = dbStub({
    first: (sql) => sql.includes("COUNT(*) total") ? { total: 0 } : null
  });
  const response = await worker.fetch(new Request("https://urbexity.example/api/v1/places?limit=12"), env(database));
  assert.equal(response.status, 200);
  const payload = await response.json();
  assert.deepEqual(payload.data, []);
  assert.equal(payload.pagination.limit, 12);
  assert.equal(payload.pagination.total, 0);
});

test("market filters are parameterized and price sorting uses an allowlist", async () => {
  let querySql = "", queryValues = [];
  const database = dbStub({ all: (sql, values) => { querySql = sql; queryValues = values; return { results: [] }; } });
  const response = await worker.fetch(new Request("https://urbexity.example/api/v1/market?q=map&category=digital_map&sort=price_low"), env(database));
  assert.equal(response.status, 200);
  assert.match(querySql, /l\.title LIKE \?/);
  assert.match(querySql, /ORDER BY l\.price_cents ASC/);
  assert.deepEqual(queryValues, ["%map%", "%map%", "digital_map"]);
  assert.equal((await response.json()).checkoutEnabled, false);
});

test("private locations are indistinguishable from missing locations to anonymous users", async () => {
  const database = dbStub({
    first: (sql) => sql.includes("FROM places p JOIN users") && sql.includes("WHERE p.id")
      ? { id: "p1", owner_id: "u1", visibility: "private", status: "approved" }
      : null
  });
  const response = await worker.fetch(new Request("https://urbexity.example/api/v1/places/p1"), env(database));
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, "place_not_found");
});

test("place creation requires a real session", async () => {
  const response = await worker.fetch(new Request("https://urbexity.example/api/v1/places", {
    method: "POST",
    headers: { origin: "https://urbexity.example", "content-type": "application/json" },
    body: JSON.stringify({ title: "A real place", latitude: 40, longitude: -80, category: "other" })
  }), env());
  assert.equal(response.status, 401);
  assert.equal((await response.json()).error.code, "authentication_required");
});

test("an unverified bootstrap administrator email receives no admin privileges", async () => {
  let insertedAdminFlag;
  const database = dbStub({
    first: () => ({ count: 1 }),
    onRun: (sql, values) => {
      if (sql.includes("INSERT INTO users")) insertedAdminFlag = values[5];
      return { success: true };
    }
  });
  const response = await worker.fetch(new Request("https://urbexity.example/api/v1/auth/register", {
    method: "POST",
    headers: { origin: "https://urbexity.example", "content-type": "application/json" },
    body: JSON.stringify({ username: "site-admin", email: "admin@example.com", password: "long-test-password" })
  }), { ...env(database), ADMIN_EMAILS: "admin@example.com" });
  assert.equal(response.status, 201);
  assert.equal(insertedAdminFlag, 0);
});

test("private D1 image blobs are not delivered to anonymous users", async () => {
  const database = dbStub({
    first: (sql) => sql.includes("place_photos p JOIN places")
      ? { owner_id: "u1", visibility: "private", status: "approved", moderation_status: "approved" }
      : null
  });
  const response = await worker.fetch(new Request("https://urbexity.example/media/places/p1/photo.jpg"), env(database));
  assert.equal(response.status, 404);
});

test("approved image bytes are returned from the D1 media table", async () => {
  const bytes = new Uint8Array([137, 80, 78, 71]);
  const database = dbStub({ first: (sql) => {
    if (sql.includes("place_photos p JOIN places")) return { owner_id: "u1", visibility: "public", status: "approved", moderation_status: "approved" };
    if (sql.includes("FROM media_objects")) return { content_type: "image/png", body: bytes };
    return null;
  }});
  const response = await worker.fetch(new Request("https://urbexity.example/media/places/p1/photo.png"), env(database));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("content-type"), "image/png");
  assert.deepEqual(new Uint8Array(await response.arrayBuffer()), bytes);
});

test("API keys cannot use endpoints outside their scopes", async () => {
  const database = dbStub({
    first: (sql) => sql.includes("FROM api_keys")
      ? { id: "key1", name: "KITE", scopes_json: JSON.stringify(["users:read"]), created_by: "admin1" }
      : null
  });
  const response = await worker.fetch(new Request("https://urbexity.example/api/v1/places", {
    headers: { authorization: "Bearer urbx_test_key" }
  }), env(database));
  assert.equal(response.status, 403);
  assert.equal((await response.json()).error.code, "insufficient_scope");
});

test("scoped integration keys cannot cross administrator permission boundaries", async () => {
  const key = "urbx_example_integration_key";
  const hash = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(key))), b => b.toString(16).padStart(2, "0")).join("");
  const database = dbStub({
    first: sql => sql.includes("FROM api_keys") ? { id: "key1", scopes_json: '["webhooks:write"]', created_by: "admin1" } : { count: 1 }
  });
  const response = await worker.fetch(new Request("https://urbexity.example/api/v1/admin/api-keys", {
    headers: { authorization: `Bearer ${key}` }
  }), env(database));
  assert.equal(hash.length, 64);
  assert.equal(response.status, 403);
  assert.equal((await response.json()).error.code, "admin_required");
});

test("non-API routes fall through to the static application", async () => {
  const response = await worker.fetch(new Request("https://urbexity.example/discover"), env());
  assert.equal(response.status, 200);
  assert.equal(await response.text(), "spa");
});
