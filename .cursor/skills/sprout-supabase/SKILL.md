---
name: sprout-supabase
description: >-
  Applies Sprout Supabase conventions: two projects (dev/prod), SQL migrations,
  RLS, verified-only sync, and Flutter repository/mapper updates. Use when
  changing schema, auth, sync, pending queue, or flavor Supabase config.
---

# Sprout Supabase

Read `.cursor/references/offline-sync.md` and `supabase/README.md`. Use the Supabase MCP when it can inspect or apply project changes; never put the service role key in the Flutter app.

## Two projects

Same migrations on **development** and **production** Supabase projects. App flavors map 1:1 via gitignored JSON (`development.json` / `production.json`).

## App rules

- Anon/publishable key only in the client.
- `AuthService.canSync` requires a verified (non-anonymous) user. Guests stay on Hive.
- Repository writes: Hive → notify → enqueue `PendingSyncOperation` only when configured + `canSync`.
- After verified sign-in: bind user id, then `pullRemote` + `flushPending`.

## Schema change recipe

1. Add a timestamped file under `supabase/migrations/`.
2. Update remote DTO + mapper + `pullRemote` / pending payload.
3. Keep Hive backward-compatible if the local model also changes.
4. Tell the human to apply the migration on **both** dashboards if the agent cannot (one step). Do not leave prod schema drift undocumented.

Auth provider dashboard work: `docs/SUPABASE_AUTH_TODOS.md` (human-owned clicks).
