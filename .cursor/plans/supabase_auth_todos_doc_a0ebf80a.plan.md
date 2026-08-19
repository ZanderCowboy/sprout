---
name: Supabase auth TODOs doc
overview: Add a checked TODO doc that locks auth product decisions (local-only until sign-in, email OTP first, Android/Google only) and lists human Supabase dashboard work plus the Flutter follow-ups that depend on it.
todos:
  - id: write-auth-todos-doc
    content: Create docs/SUPABASE_AUTH_TODOS.md with locked decisions, Supabase/Google human TODOs, app follow-ups, and deferred items
    status: completed
  - id: link-from-readmes
    content: Link the new doc from README.md and supabase/README.md
    status: completed
isProject: false
---

# Supabase auth TODOs doc

## Deliverable

Create [`docs/SUPABASE_AUTH_TODOS.md`](docs/SUPABASE_AUTH_TODOS.md) (same style as [`docs/FIREBASE_DEV_DISTRIBUTION.md`](docs/FIREBASE_DEV_DISTRIBUTION.md) / [`docs/PLAY_PUBLISH_PROD_ANDROID.md`](docs/PLAY_PUBLISH_PROD_ANDROID.md)).

Add short links from:
- [`README.md`](README.md) More docs section
- [`supabase/README.md`](supabase/README.md) (point at auth TODOs; leave current setup steps as the baseline “how to wire projects”)

No Flutter auth implementation in this pass — documentation only.

## Locked product decisions (stated at top of the doc)

1. **Local-only until sign-in** — guest/anonymous may use Hive locally; no Supabase sync until the user has a verified (non-anonymous) session.
2. **Email OTP now; magic link later** — OTP avoids deep linking for v1; magic link + Android deep links are a deferred section.
3. **Android only** — no iOS work; **skip Apple** Sign in for now. Google + email OTP on Android.

## Doc structure (concrete)

### 1. Decisions / non-goals
- In scope: email OTP, Google on Android, verified-user sync gate, stale anonymous data cleanup.
- Out of scope for now: email+password, 2FA, magic links/deep links, Apple, iOS.

### 2. Human: Supabase dashboard TODOs (dev + prod)

Checkbox list, do **per project**:

- Confirm migrations applied (existing [`supabase/migrations/`](supabase/migrations/)).
- **Email** provider on; configure OTP (template includes `{{ .Token }}`); disable or ignore password signup until later.
- Rate limits / OTP expiry sanity check.
- **Google** provider: Web client ID (+ secret as required) and Android client IDs for `co.za.zanderkotze.sprout.dev` and `co.za.zanderkotze.sprout` with debug/release SHA-1s.
- **Anonymous**: decide keep-on for future guest→link vs turn off if app will use pure local UUID until OTP/Google (doc will recommend: **keep Anonymous off for sync path**; use local Hive id until verified sign-in, matching “local-only until sign-in” — avoids orphan `auth.users` rows from every install). Clarify that today’s app still calls `signInAnonymously()` and will need a code change to stop syncing as anon.
- URL config: Site URL only for now (no magic-link redirect allowlist required until deep links).
- Optional: wipe stale anonymous users / orphaned `accounts`/`goals`/`transactions`/`budget_groups` in **dev**.
- Config JSON still: URL + anon/publishable key in flavor assets (already documented).

### 3. Human: Google Cloud TODOs
- OAuth consent / audience.
- Web + Android OAuth clients; SHA-1s for both flavors.
- Paste into Supabase Google provider.

### 4. App follow-up TODOs (for when implementation starts)
Short checklist so the doc is the single source of truth for the chosen behavior:

- Stop treating anonymous Supabase sessions as the sync identity (align with local-only until verified sign-in).
- Auth UI: email + OTP verify; Google via `google_sign_in` + `signInWithIdToken`.
- After verified session: set `UserContext` to `auth.uid()`, migrate/rewrite local Hive `userId`, enable sync/pull.
- Sign out: clear session; keep or wipe local data per product rule (doc: **keep local guest data on sign-out unless signing in as a different account**, then replace Hive + pull).
- Tests around gate + OTP/Google happy paths.
- Deferred: magic link + deep link intent-filter; Apple; iOS.

### 5. Deferred section
- Magic link + `AndroidManifest` intent-filter + redirect URLs.
- Apple / iOS.
- Email+password after 2FA.

## Approach notes (will be written into the doc, not left open)

- **Identity until sign-in:** local Hive `active_user_id` only; no `signInAnonymously()` for sync. Matches decision (1) and reduces stale `auth.users` junk.
- **OTP path:** `signInWithOtp` → user enters code → `verifyOtp` (no deep link).
- **Google:** native Android ID token → Supabase; no Apple.