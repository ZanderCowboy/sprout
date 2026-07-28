# Play Store publish (production Android AAB)

Dispatch-only workflow: **Play Publish (Prod Android AAB)** builds a signed production App Bundle and uploads it to Google Play.

Development builds use Firebase App Distribution instead — see [FIREBASE_DEV_DISTRIBUTION.md](FIREBASE_DEV_DISTRIBUTION.md).

## Package / flavor

| Item | Value |
|------|-------|
| Flavor | `production` |
| applicationId | `co.za.zanderkotze.sprout` |
| Entry point | `lib/main_production.dart` |
| Config asset | `assets/config/production.json` |
| Firebase config | `android/app/src/production/google-services.json` |
| AAB output | `sprout_app/build/app/outputs/bundle/productionRelease/app-production-release.aab` |

## Manual checklist (one-time)

### Supabase (production project)

1. Create a **production** Supabase project (separate from development).
2. Apply all SQL under [`supabase/migrations/`](../supabase/migrations/) to that project.
3. Enable **Anonymous** auth if the app should sync (`Auth` → `Providers` → `Anonymous`).
4. Put Project URL + anon/publishable key in `sprout_app/assets/config/production.json`.
5. Encode for CI: `base64 -i sprout_app/assets/config/production.json | tr -d '\n'` → `APP_CONFIG_PROD_BASE64`.

### Firebase (production)

1. Create a **production** Firebase project (or a separate Android app).
2. Register Android package `co.za.zanderkotze.sprout`.
3. Enable Analytics / Crashlytics to match the Gradle plugins.
4. Download `google-services.json` → `sprout_app/android/app/src/production/google-services.json`.
5. Encode for CI: `base64 -i …/src/production/google-services.json | tr -d '\n'` → `GOOGLE_SERVICES_PROD_BASE64`.
6. Do **not** configure App Distribution for production.

### Google Play Console

1. Create a Play Console app with package `co.za.zanderkotze.sprout`.
2. Complete listing / content basics as required by Play.
3. Enable Play App Signing; register your **upload** keystore (same key material as `ANDROID_SIGNING_CONFIG_BASE64`).
4. Upload at least one AAB manually (or finish first-draft requirements) so API uploads are allowed.
5. Create a Google Cloud service account with Play Console API access to the app; download JSON → `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

### Local production build (optional smoke test)

```bash
cd sprout_app
flutter build appbundle --release --flavor production -t lib/main_production.dart --no-tree-shake-icons
```

Requires `src/production/google-services.json`, `production.json`, and release signing (`android/key.properties`).

## GitHub secrets

| Secret | Required | Purpose |
|--------|----------|---------|
| `APP_CONFIG_PROD_BASE64` | yes | Production Supabase config JSON |
| `GOOGLE_SERVICES_PROD_BASE64` | yes | Production `google-services.json` |
| `ANDROID_SIGNING_CONFIG_BASE64` | yes | Upload keystore (same format as [FIREBASE_DEV_DISTRIBUTION.md](FIREBASE_DEV_DISTRIBUTION.md)) |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | yes | Play Console API service account (raw JSON) |

## Manual workflow inputs

Go to **Actions** → **Play Publish (Prod Android AAB)** → **Run workflow**:

- `git_ref` (optional): branch/tag/commit SHA to build (default: current ref)
- `track`: `internal` (default), `alpha`, `beta`, or `production`
- `release_status`: `completed` (default), `draft`, `halted`, or `inProgress`
- `release_notes` (optional): en-US “What’s new” text (defaults to `Production release`)

## Build command used in CI

```bash
flutter build appbundle --release --flavor production -t lib/main_production.dart --no-tree-shake-icons
```
