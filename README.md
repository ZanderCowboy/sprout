# Sprout

Watch your money grow and for those who want to reach their goals quickly.

Flutter savings app (offline-first with Hive, optional Supabase sync) in [`sprout_app/`](sprout_app/).

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
| **Sprout · dev · …** | `development` | `lib/main_development.dart` | `assets/config/development.json` | `co.za.zanderkotze.sprout.dev` |
| **Sprout · prod · …** | `production` | `lib/main_production.dart` | `assets/config/production.json` | `co.za.zanderkotze.sprout` |

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
  "androidApplicationId": "co.za.zanderkotze.sprout.dev",
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

Use `co.za.zanderkotze.sprout` for production. `androidApplicationId` documents the Play package for that flavor; RevenueCat still uses `revenueCatAndroidApiKey` (`test_…` / `goog_…`), not the package name.

Copy `apiKey` / `appId` / etc. from the flavor’s `google-services.json` into the gitignored `firebase` object (do **not** commit those values in Dart sources).

Empty URL/key → **local-only** mode (Hive, no sync). Fill them for Supabase sync — use the **development** Supabase project in `development.json` and the **production** project in `production.json`.

Empty `revenueCatAndroidApiKey` → RevenueCat is skipped at startup. On **development**, a Firebase Remote Config kill switch (`revenuecat_enabled`, default off) must also be `true` before `Purchases.configure` runs — see [RevenueCat foundation](docs/REVENUECAT.md). Production always skips configure for now.

Optional overrides: `--dart-define=SUPABASE_URL=...`, `--dart-define=SUPABASE_ANON_KEY=...`, and `--dart-define=REVENUECAT_ANDROID_API_KEY=...`.

### Firebase (`google-services.json`)

Place flavor-specific files (gitignored):

- `sprout_app/android/app/src/development/google-services.json` — package `co.za.zanderkotze.sprout.dev`
- `sprout_app/android/app/src/production/google-services.json` — package `co.za.zanderkotze.sprout`

## Supabase (optional)

See [`supabase/README.md`](supabase/README.md): create **two** projects (dev + prod), run the same migrations on each, then put URL + anon/publishable key in the matching config JSON above. Auth provider checklist (OTP, Google, local-only until sign-in): [`docs/SUPABASE_AUTH_TODOS.md`](docs/SUPABASE_AUTH_TODOS.md).

## Checks

```bash
cd sprout_app
flutter analyze
flutter test
```

## More docs

- [GitHub CLI (personal account)](docs/GITHUB_CLI_PERSONAL.md) — `gh` as `ZanderCowboy` in this workspace only
- [Firebase Dev Distribution (Android)](docs/FIREBASE_DEV_DISTRIBUTION.md) — CI APK builds and GitHub secrets
- [Play Store publish (Android)](docs/PLAY_PUBLISH_PROD_ANDROID.md) — dispatch-only production AAB upload
- [RevenueCat foundation](docs/REVENUECAT.md) — SDK configure, identity, Test Store catalog
- [Supabase setup](supabase/README.md)
- [Supabase auth TODOs](docs/SUPABASE_AUTH_TODOS.md) — OTP + Google (Android); local-only until sign-in
- [Resend SMTP for Supabase](docs/RESEND_SMTP_SUPABASE.md) — Custom SMTP + GoDaddy DNS for email OTP
