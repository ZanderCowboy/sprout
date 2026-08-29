# Sprout

Watch your money grow and for those who want to reach their goals quickly.

Flutter savings app (offline-first with Hive, optional Supabase sync) in [`sprout_app/`](sprout_app/).


### Build and distribute the development APK

Flavor name is `development` (not `dev` / `develop`). Flutter looks for `app-<flavor>-release.apk`, so a shortened flavor name builds the APK then fails to find it.

From the repo root:

```bash
cd sprout_app && flutter build apk --release --flavor development -t lib/main_development.dart && firebase appdistribution:distribute build/app/outputs/flutter-apk/app-development-release.apk --app 1:549104397391:android:4a8ab133ed8a2d67978e3a --groups default
```

If the APK is already built, from the repo root:

```bash
firebase appdistribution:distribute sprout_app/build/app/outputs/flutter-apk/app-development-release.apk --app 1:549104397391:android:4a8ab133ed8a2d67978e3a --groups default
```

Or run the Cursor/VS Code task **Sprout · Firebase · distribute dev APK**.

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | **3.38.10** (stable) |
| Dart | **3.10.9** |
| DevTools | 2.51.1 |
| Dart SDK constraint | `^3.8.0` ([`sprout_app/pubspec.yaml`](sprout_app/pubspec.yaml)) |
| Java (Android builds / CI) | 17 |

Also need a device, emulator, or desktop target (`flutter devices`).

CI uses the same Flutter version via [`.github/actions/flutter-setup`](.github/actions/flutter-setup/action.yml).

No code generation, melos, or `build_runner` — Hive adapters are checked in.

## Getting started

```bash
cd sprout_app
flutter pub get
flutter run --flavor development -t lib/main_development.dart
```

Or use the VS Code / Cursor launch configs in [`.vscode/launch.json`](.vscode/launch.json):

| Launch | Flavor | Entry point | Config asset | Android applicationId |
|--------|--------|-------------|--------------|------------------------|
| **Sprout · dev · …** | `development` | `lib/main_development.dart` | `assets/config/development.json` | `app.stackmint.sprout.dev` |
| **Sprout · prod · …** | `production` | `lib/main_production.dart` | `assets/config/production.json` | `app.stackmint.sprout` |

Both flavors can be installed on the same device. Production uses launcher name **Sprout**; development uses **[DEV] Sprout**.

`lib/main.dart` also loads the development config (default for plain `flutter run`), but Android builds still require an explicit `--flavor`.

### Config assets (required to start)

Both JSON files are gitignored but must exist locally (they are listed in `pubspec.yaml` assets):

- `sprout_app/assets/config/development.json`
- `sprout_app/assets/config/production.json`

```json
{
  "supabaseUrl": "",
  "supabaseAnonKey": "",
  "androidApplicationId": "app.stackmint.sprout.dev",
  "revenueCatAndroidApiKey": "",
  "firebase": {
    "apiKey": "",
    "appId": "",
    "messagingSenderId": "",
    "projectId": "",
    "storageBucket": ""
  }
}
```

Use `app.stackmint.sprout` for production. `androidApplicationId` documents the Play package for that flavor; RevenueCat still uses `revenueCatAndroidApiKey` (`test_…` / `goog_…`), not the package name.

Copy `apiKey` / `appId` / etc. from the flavor’s `google-services.json` into the gitignored `firebase` object (do **not** commit those values in Dart sources).

To move these files to another machine (they are gitignored), export to **OneDrive Personal**, then import after cloning. Dest is `<OneDrive>/Projects/sprout-local-config`.

**Windows.** `make` works if Git for Windows is installed (usual path `C:\Program Files\Git`). Or use PowerShell — Make is not required:

```powershell
# one-off: point at this PC's OneDrive root (the folder that contains Projects\)
powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 import -OneDrive "$env:OneDrive"

# or paste the path from File Explorer
powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 set-onedrive -OneDrive "C:\Users\you\OneDrive"
powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 import
```

`set-onedrive` writes gitignored `.sprout-onedrive` so later you only need `import`. Full dest: `-Dest "C:\Users\you\OneDrive\Projects\sprout-local-config"`.

**macOS** (Make is optional):

```bash
make config-export
make config-import
# or
scripts/sync-local-config.sh export|import|status|set-onedrive
```

This copies flavor JSON, `google-services.json`, release signing, `.secrets`, and `config/` — not `local.properties` or build artifacts.

Empty URL/key → **local-only** mode (Hive, no sync). Fill them for Supabase sync — use the **development** Supabase project in `development.json` and the **production** project in `production.json`.

Empty `revenueCatAndroidApiKey` → RevenueCat is skipped at startup. On **development**, a Firebase Remote Config kill switch (`revenuecat_enabled`, default off) must also be `true` before `Purchases.configure` runs — see [RevenueCat foundation](docs/REVENUECAT.md). Production always skips configure for now. A `test_…` key is also skipped in **release/profile** (the SDK rejects Test Store outside debug).

Optional overrides: `--dart-define=SUPABASE_URL=...`, `--dart-define=SUPABASE_ANON_KEY=...`, and `--dart-define=REVENUECAT_ANDROID_API_KEY=...`.

### Firebase (`google-services.json`)

Place flavor-specific files (gitignored):

- `sprout_app/android/app/src/development/google-services.json` — package `app.stackmint.sprout.dev`
- `sprout_app/android/app/src/production/google-services.json` — package `app.stackmint.sprout`

## Supabase (optional)

See [`supabase/README.md`](supabase/README.md): create **two** projects (dev + prod), run the same migrations on each, then put URL + anon/publishable key in the matching config JSON above. Auth provider checklist (OTP, Google, local-only until sign-in): [`docs/SUPABASE_AUTH_TODOS.md`](docs/SUPABASE_AUTH_TODOS.md).

## Checks

```bash
cd sprout_app
flutter analyze
flutter test
```

## Maestro UI Tests (development flavor only)

Maestro flows are in `.maestro/` and test the core savings loop (account → goal → deposit) against the **development** flavor.

### Prerequisites

1. Install Maestro CLI (https://docs.maestro.dev/maestro-cli/how-to-install-maestro-cli). On this Windows machine it lives at `C:\Programming\maestro\bin`. The project MCP in `.cursor/mcp.json` launches `maestro mcp` so the agent can inspect devices and run flows.
2. Build or run the **development** flavor (no dart-define needed):

```bash
cd sprout_app
flutter run --flavor development -t lib/main_development.dart
```

### Running tests

With the app installed or running:

```bash
# Run all flows
maestro test .maestro/

# Run a specific flow
maestro test .maestro/core-loop.yaml
```

### Auth bypass

Development builds show a **Debug sign in** button on intro and Sign in (`Maestro Test · maestro@test.local`). It binds a local-only test user (`maestro-test-user`) and opens Overview. Sync stays off.

**Production flavor never shows the button.**

### Available flows

- `core-loop.yaml` — Create account, goal, deposit, verify progress
- `deposit-no-accounts.yaml` — Deposit with 0 accounts shows "create account first" CTA
- `goal-no-accounts.yaml` — Creating goal with 0 accounts shows guidance
- `full-app-tour.yaml` — Walk every major surface with screenshots (UX review)

## More docs

- [GitHub CLI (personal account)](docs/GITHUB_CLI_PERSONAL.md) — `gh` as `ZanderCowboy` in this workspace only
- [Firebase CLI (personal account)](docs/FIREBASE_CLI_PERSONAL.md) — `firebase` login isolated via `XDG_CONFIG_HOME`
- [Firebase Dev Distribution (Android)](docs/FIREBASE_DEV_DISTRIBUTION.md) — CI APK builds and GitHub secrets
- [Play Store publish (Android)](docs/PLAY_PUBLISH_PROD_ANDROID.md) — dispatch-only production AAB upload
- [RevenueCat foundation](docs/REVENUECAT.md) — SDK configure, identity, Test Store catalog
- [Supabase setup](supabase/README.md)
- [Supabase auth TODOs](docs/SUPABASE_AUTH_TODOS.md) — OTP + Google (Android); local-only until sign-in
- [Resend SMTP for Supabase](docs/RESEND_SMTP_SUPABASE.md) — Custom SMTP + GoDaddy DNS for email OTP
