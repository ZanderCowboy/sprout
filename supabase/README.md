# Supabase setup for Sprout

Use **two Supabase projects** — one for development and one for production — so app profiles never share data or keys.

## Projects

| App profile | Supabase project | Config asset |
|-------------|------------------|--------------|
| development (`--flavor development`) | Dev project | `sprout_app/assets/config/development.json` |
| production (`--flavor production`) | Prod project | `sprout_app/assets/config/production.json` |

Keep schemas in sync by applying the **same** migrations under [`migrations/`](migrations/) to both projects whenever you change them.

## Per-project setup

For **each** project:

1. Run the SQL in [`migrations/`](migrations/) in order (SQL editor or CLI migrations), starting with [`20260412120000_init.sql`](migrations/20260412120000_init.sql).
2. **Authentication:** enable **Anonymous** sign-in if you want the app to call `signInAnonymously()` on launch (`Auth` → `Providers` → `Anonymous`). Otherwise the app falls back to a local Hive user id and stays offline-first only.
3. **Settings → API:** copy **Project URL** and **anon public** (legacy JWT) or **publishable** key (`sb_publishable_…`). Either works with `supabase_flutter`.

## Flutter config

Add `sprout_app/assets/config/development.json` and `sprout_app/assets/config/production.json`. Each must be a JSON object (the app will not start if the file for your entry point is missing from the asset bundle):

```json
{
  "supabaseUrl": "https://YOUR_PROJECT.supabase.co",
  "supabaseAnonKey": "YOUR_PUBLISHABLE_OR_ANON_KEY"
}
```

- **supabaseUrl:** Project **Settings → API → Project URL**. Must be `https`, typically `https://<ref>.supabase.co` (no trailing slash required).
- **supabaseAnonKey:** **Settings → API → anon public** or **publishable** key.
- Put the **dev** project credentials in `development.json` and the **prod** project credentials in `production.json`.
- Leave both strings empty for a local-only build (Hive only, no sync).

You can keep real values out of git via `.gitignore` (see repo root); you still need both files locally to run **Sprout · prod · …** / `main_production.dart`.

**Entry points:** [`main_development.dart`](../sprout_app/lib/main_development.dart) loads `assets/config/development.json`; [`main_production.dart`](../sprout_app/lib/main_production.dart) loads `assets/config/production.json`. [`main.dart`](../sprout_app/lib/main.dart) matches development. VS Code: **Sprout · dev · …** / **Sprout · prod · …** in [`.vscode/launch.json`](../.vscode/launch.json) pick the matching `program` and `--flavor`. CLI:

```bash
flutter run --flavor development -t lib/main_development.dart
flutter run --flavor production -t lib/main_production.dart
```

Optional: `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...` still override the JSON when non-empty (e.g. CI).

If URL or key is empty, Sprout runs in **local-only** mode (Hive only, no sync).

## CI secrets

Encode each config for GitHub Actions:

```bash
base64 -i sprout_app/assets/config/development.json | tr -d '\n'  # APP_CONFIG_DEV_BASE64
base64 -i sprout_app/assets/config/production.json | tr -d '\n'   # APP_CONFIG_PROD_BASE64
```
