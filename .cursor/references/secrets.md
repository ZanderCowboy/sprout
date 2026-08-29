# Secrets and local config

Never commit real keys, JSON configs, or generated Firebase options.

## Gitignored (must exist locally to run)

- `sprout_app/assets/config/development.json`
- `sprout_app/assets/config/production.json`
- `sprout_app/android/app/src/development/google-services.json`
- `sprout_app/android/app/src/production/google-services.json`

Do not add `firebase_options*.dart`. Copy Firebase fields into the flavor JSON `firebase` object instead.

## Copy to another machine

Gitignored files are not in the clone. Copy them to `<OneDrive>/Projects/sprout-local-config` and restore on the other PC. Never print file contents. Do not copy `android/local.properties` (SDK path is machine-specific).

- Windows: `make config-import` (needs Git for Windows) or `scripts/sync-local-config.ps1 import -OneDrive "$env:OneDrive"`. `set-onedrive` writes gitignored `.sprout-onedrive`. Use `powershell -ExecutionPolicy Bypass -File ...` if scripts are blocked.
- macOS: `scripts/sync-local-config.sh` or `make config-import`. Optional `ONEDRIVE=` / `DEST=`.

## Flavor JSON (shape)

See `README.md`. Empty `supabaseUrl`/`supabaseAnonKey` → local-only. Empty `revenueCatAndroidApiKey` → skip Purchases. Empty `googleWebClientId` → hide Google sign-in.

`--dart-define=SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `REVENUECAT_ANDROID_API_KEY` override JSON when non-empty (CI).

## Human-only

Dashboard logins, 2FA, App Store / Play Console, pasting keys into JSON or GitHub secrets. State that single action; do not dump secret values into chat, commits, or rules.

CI encoding: `docs` + `supabase/README.md` (`APP_CONFIG_DEV_BASE64` / `APP_CONFIG_PROD_BASE64`).
