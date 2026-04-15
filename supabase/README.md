# Supabase setup for Sprout

1. Create a Supabase project and run the SQL in [`migrations/20260412120000_init.sql`](migrations/20260412120000_init.sql) (SQL editor or CLI migrations).
2. **Authentication:** enable **Anonymous** sign-in if you want the app to call `signInAnonymously()` on launch (`Auth` → `Providers` → `Anonymous`). Otherwise the app falls back to a local Hive user id and stays offline-first only.
3. **Flutter:** add `sprout_app/assets/config/development.json` and `sprout_app/assets/config/production.json`. Each must be a JSON object (the app will not start if the file for your entry point is missing from the asset bundle):

   ```json
   {
     "supabaseUrl": "https://YOUR_PROJECT.supabase.co",
     "supabaseAnonKey": "YOUR_PUBLISHABLE_OR_ANON_KEY"
   }
   ```

   - **supabaseUrl:** Project **Settings → API → Project URL**. Must be `https`, typically `https://<ref>.supabase.co` (no trailing slash required).
   - **supabaseAnonKey:** **Settings → API → anon public** (legacy JWT) or **publishable** key (`sb_publishable_…`). Either works with `supabase_flutter`.
   - Leave both strings empty in `production.json` for a local-only build, or set real values for sync.

   You can keep real values out of git via `.gitignore` (see repo root); you still need both files locally to run **Sprout · prod · …** / `main_production.dart`.

   **Entry points:** [`main_development.dart`](../sprout_app/lib/main_development.dart) loads `assets/config/development.json`; [`main_production.dart`](../sprout_app/lib/main_production.dart) loads `assets/config/production.json`. [`main.dart`](../sprout_app/lib/main.dart) matches development. VS Code: **Sprout · dev · …** / **Sprout · prod · …** in [`.vscode/launch.json`](../.vscode/launch.json) pick the matching `program`. CLI: `flutter run -t lib/main_production.dart`.

   Optional: `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...` still override the JSON when non-empty (e.g. CI).

If URL or key is empty, Sprout runs in **local-only** mode (Hive only, no sync).
