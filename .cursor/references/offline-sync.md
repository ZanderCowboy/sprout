# Offline-first sync

Hive is the source of truth on device. Supabase is optional.

## Modes

- Empty `supabaseUrl` / `supabaseAnonKey` → local-only (no enqueue, no pull).
- Configured Supabase + **guest** (no verified session) → local Hive only; `AuthService.canSync` is false.
- Configured Supabase + **verified** email OTP or Google user → enqueue + flush + pull.

Sync is never allowed for anonymous sessions. Guest data uses a local Hive user id until `bindAfterVerifiedSignIn`.

## Write path

1. Repository writes Hive, notifies watchers.
2. If `_shouldEnqueue` (`isSupabaseConfigured` && queue != null && `canSync()`), enqueue a `PendingSyncOperation`.
3. `PendingSyncQueue.onEnqueued` triggers `SyncService.flushPending()`.

## Read path

`pullRemote()` on each repository runs after verified sign-in (`AuthService.bindAfterVerifiedSignIn`).

## When changing persisted shape

1. Domain entity
2. Hive model + **hand-written** adapter in `hive_adapters.dart` (stable `typeId`, append-only fields with backward-compatible reads)
3. Hive mapper
4. Supabase row + mapper + SQL migration (apply to **both** dev and prod projects)
5. Pending-sync payload encode/decode if the op carries that entity

Do not regenerate Hive adapters.
