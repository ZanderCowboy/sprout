---
name: Dart-define config files
overview: Move Supabase config from Flutter asset JSON to gitignored files under `sprout_app/config/`, loaded at compile time via `--dart-define-from-file` (no pubspec assets). Update AppConfig, entrypoints, launch configs, CI workflows, and docs accordingly.
todos:
  - id: app-config
    content: Rewrite AppConfig to fromEnvironment only; drop configAssetPath through bootstrap/startup UI
    status: pending
  - id: files-pubspec
    content: Move JSON to sprout_app/config/ with SUPABASE_* keys; remove pubspec assets; update gitignore
    status: pending
  - id: launch
    content: Add --dart-define-from-file to .vscode/launch.json configs
    status: pending
  - id: ci
    content: Update Firebase/Play workflows + ensure-config action; drop ensure step from ci-dev-checks
    status: pending
  - id: docs
    content: Update README, supabase README, Firebase/Play docs (paths, keys, flag, secret re-encode)
    status: pending
isProject: false
---

# Dart-define config from file

## Approach

Use Flutter’s `--dart-define-from-file=<path>` so JSON under [`sprout_app/config/`](sprout_app/config/) is **not** a Flutter asset and is **not** listed in [`sprout_app/pubspec.yaml`](sprout_app/pubspec.yaml). Keys become compile-time `String.fromEnvironment` values.

New file layout (gitignored; already covered by root `config/` in [`.gitignore`](.gitignore)):

- `sprout_app/config/development.json`
- `sprout_app/config/production.json`

**JSON key rename** (required for `--dart-define-from-file`): keys must match define names used in code:

```json
{
  "SUPABASE_URL": "https://….supabase.co",
  "SUPABASE_ANON_KEY": "…"
}
```

(replacing current `supabaseUrl` / `supabaseAnonKey`). **Re-encode and update** GitHub secrets `APP_CONFIG_DEV_BASE64` / `APP_CONFIG_PROD_BASE64` after this change, or CI will inject defines under the wrong names and Supabase will appear unconfigured.

```mermaid
flowchart LR
  launch["launch / flutter build\n--dart-define-from-file"]
  json["sprout_app/config/*.json"]
  defines["SUPABASE_URL\nSUPABASE_ANON_KEY"]
  appConfig["AppConfig.load"]
  launch --> json
  json --> defines
  defines --> appConfig
```

## App code

**[`sprout_app/lib/core/config/app_config.dart`](sprout_app/lib/core/config/app_config.dart)**  
- Stop using `rootBundle` / `dart:convert` / asset paths.  
- Load only from `String.fromEnvironment('SUPABASE_URL')` and `String.fromEnvironment('SUPABASE_ANON_KEY')`.  
- Make `load` / `tryLoad` take only `environment` (sync is fine; keep `Future` only if callers still expect async).  
- Empty URL/key → local-only (unchanged). Keep `assertValidSupabaseIfConfigured()`.

**Remove `configAssetPath` through the chain:**

- [`bootstrap.dart`](sprout_app/lib/bootstrap.dart)
- [`main.dart`](sprout_app/lib/main.dart) / [`main_development.dart`](sprout_app/lib/main_development.dart) / [`main_production.dart`](sprout_app/lib/main_production.dart) — only pass `environment`
- [`startup_initializer.dart`](sprout_app/lib/core/startup/startup_initializer.dart)
- [`startup_flow.dart`](sprout_app/lib/features/startup/startup_flow.dart), [`startup_page.dart`](sprout_app/lib/features/startup/startup_page.dart), [`startup_error_page.dart`](sprout_app/lib/features/startup/startup_error_page.dart) — show environment name instead of asset path

**[`sprout_app/pubspec.yaml`](sprout_app/pubspec.yaml)** — delete the `assets:` config entries (and the `assets:` section if nothing else remains).

**Local files** — move/rename existing JSON from `assets/config/` → `config/` with the new key names; remove old asset files and drop obsolete gitignore lines for `sprout_app/assets/config/*.json` if unused.

## Launch / local run

Update [`.vscode/launch.json`](.vscode/launch.json) so every config passes the matching file, e.g.:

```json
"args": [
  "--flavor", "development",
  "--dart-define-from-file=config/development.json"
]
```

(prod → `config/production.json`). Document CLI:

```bash
flutter run --flavor development -t lib/main_development.dart \
  --dart-define-from-file=config/development.json
```

Missing file + flag present → Flutter fails at startup of the tool (expected). Empty JSON values → app runs local-only.

## GitHub workflows / actions

**[`firebase-distribute-dev-android.yml`](.github/workflows/firebase-distribute-dev-android.yml)**  
- Write secret to `config/development.json` (not `assets/config/…`).  
- Build with `--dart-define-from-file=config/development.json`.  
- Keep `--flavor development -t lib/main_development.dart`.

**[`play-publish-prod-android.yml`](.github/workflows/play-publish-prod-android.yml)**  
- Same for `config/production.json` + prod flavor/entrypoint.

**[`ensure-config-assets`](.github/actions/ensure-config-assets/action.yml)**  
- Point defaults at `config/development.json` / `config/production.json` and emit the new key schema.  
- Optionally rename the action to `ensure-config-files` and update call sites.  
- **[`ci-dev-checks.yml`](.github/workflows/ci-dev-checks.yml):** remove the ensure step — analyze/test no longer need config files on disk.

Keep secret names `APP_CONFIG_*_BASE64` (same blobs, new JSON shape/path).

## Docs

Update config paths, key names, and `--dart-define-from-file` in:

- [`README.md`](README.md)
- [`supabase/README.md`](supabase/README.md)
- [`docs/FIREBASE_DEV_DISTRIBUTION.md`](docs/FIREBASE_DEV_DISTRIBUTION.md)
- [`docs/PLAY_PUBLISH_PROD_ANDROID.md`](docs/PLAY_PUBLISH_PROD_ANDROID.md)

Call out: re-base64 local config after key rename and refresh the two GitHub secrets.

## Out of scope

- Android product flavors / `google-services` / signing (unchanged).  
- Entrypoint-based `AppEnvironment` + env banner (unchanged).  
- Splitting secrets into separate `SUPABASE_URL_*` repo secrets (keep single JSON base64).
