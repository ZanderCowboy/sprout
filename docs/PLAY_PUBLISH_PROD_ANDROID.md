# Play Store publish (production Android AAB)

Production AAB upload is a job inside **Release Main** (`.github/workflows/release-main.yml`), not a separate workflow.

On every labeled merge to `main` (except `no-build`), CI builds a signed production App Bundle and uploads it to the Play **internal** track with the same `versionCode` as the Firebase development APK.

When Firebase testers are happy, **promote that internal release in Play Console** to production (same AAB, no rebuild). Prefer Console promote over dispatching `play_track: production`.

Development builds use Firebase App Distribution — see [FIREBASE_DEV_DISTRIBUTION.md](FIREBASE_DEV_DISTRIBUTION.md). Version labels and Version Bot: [BUILD_NUMBER.md](BUILD_NUMBER.md).

## Package / flavor

| Item | Value |
|------|-------|
| Flavor | `production` |
| applicationId | `app.stackmint.sprout` |
| Entry point | `lib/main_production.dart` |
| Config asset | `assets/config/production.json` |
| Firebase config | `android/app/src/production/google-services.json` |
| AAB output | `sprout_app/build/app/outputs/bundle/productionRelease/app-production-release.aab` |

## Manual checklist (one-time)

### Supabase (production project)

1. Create a **production** Supabase project (separate from development).
2. Apply all SQL under [`supabase/migrations/`](../supabase/migrations/) to that project.
3. **Keep Anonymous auth disabled** (required sign-in only, `Auth` → `Providers` → `Anonymous` off).
4. Put Project URL + anon/publishable key in `sprout_app/assets/config/production.json`.
5. Encode for CI: `base64 -i sprout_app/assets/config/production.json | tr -d '\n'` → `APP_CONFIG_PROD_BASE64`.

### Firebase (production)

1. Create a **production** Firebase project (or a separate Android app).
2. Register Android package `app.stackmint.sprout`.
3. Enable Analytics / Crashlytics to match the Gradle plugins.
4. Download `google-services.json` → `sprout_app/android/app/src/production/google-services.json`.
5. Encode for CI: `base64 -i …/src/production/google-services.json | tr -d '\n'` → `GOOGLE_SERVICES_PROD_BASE64`.
6. Do **not** configure App Distribution for production.

### Google Play Console

1. Create a Play Console app with package `app.stackmint.sprout`.
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

Full inventory (all secrets, encode/`gh` restore): [GITHUB_SECRETS.md](GITHUB_SECRETS.md).

| Secret | Required | Purpose |
|--------|----------|---------|
| `APP_CONFIG_PROD_BASE64` | yes | Production Supabase config JSON |
| `GOOGLE_SERVICES_PROD_BASE64` | yes | Production `google-services.json` |
| `ANDROID_SIGNING_CONFIG_BASE64` | yes | Upload keystore (same format as [FIREBASE_DEV_DISTRIBUTION.md](FIREBASE_DEV_DISTRIBUTION.md)) |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | yes | Play Console API service account (raw JSON) |
| `VERSION_BOT_APP_ID` / `VERSION_BOT_APP_PRIVATE_KEY` | yes | Version commit after successful ship |

## How to ship

### Automatic (preferred)

Merge a PR into `main` with a `major` / `minor` / `patch` label. **Release Main** uploads to Play **internal** with `status: completed`.

### Manual (retry / other tracks)

**Actions** → **Release Main** → **Run workflow**:

- `git_ref` — branch/tag/SHA
- `bump_type` / `commit_version` — see [BUILD_NUMBER.md](BUILD_NUMBER.md)
- `play_track` — `internal` (default), `alpha`, `beta`, or `production`
- `skip_firebase` — set true to only ship Play
- `release_notes` — en-US “What’s new” (defaults to PR title on merge)

## Build command used in CI

CI also passes `--build-name` / `--build-number` from the computed version:

```bash
flutter build appbundle --release --flavor production -t lib/main_production.dart --no-tree-shake-icons
```
