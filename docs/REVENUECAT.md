# RevenueCat (foundation + paywall UI)

Sprout uses [RevenueCat](https://www.revenuecat.com/) for subscriptions.

This pass wires:
- **SDK configure + identity** (after `revenuecat_enabled` kill switch)
- **Paywall UI** via `purchases_ui_flutter` launched from **Settings → Sprout Premium**

No premium feature gating is added yet (premium is opt-in via the paywall tile only).

## Project

| Item | Value |
|------|--------|
| RevenueCat project | **Sprout** (`proj8bd5ebcf`) |
| Store (current) | **Test Store** (`app643c11c740`) |
| Entitlement | `premium` |
| Offering | `default` (current) |
| Packages | `$rc_monthly` → `premium_monthly`, `$rc_annual` → `premium_annual` |
| Test Store prices | Monthly **ZAR R79.99**, Annual **ZAR R799.99** (required for offerings to resolve) |

Public SDK key for Test Store (safe to embed in the client): put it in config as `revenueCatAndroidApiKey`, or override with `--dart-define=REVENUECAT_ANDROID_API_KEY=…`.

## Config

In `sprout_app/assets/config/development.json` and `production.json` (gitignored):

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

| Flavor | `androidApplicationId` |
|--------|------------------------|
| development | `app.stackmint.sprout.dev` |
| production | `app.stackmint.sprout` |

Fill `firebase` from the matching `google-services.json` (`mobilesdk_app_id` → `appId`, `current_key` → `apiKey`, etc.). Those files and the JSON assets are gitignored — do not hardcode them in committed Dart (e.g. no `firebase_options_*.dart` in git).

Empty `revenueCatAndroidApiKey` → purchases step is **skipped**. Non-empty is not enough by itself: see the kill switch below.

## Kill switch (Firebase Remote Config)

Code:

- [`RemoteFeatureFlag`](../sprout_app/lib/core/flags/remote_feature_flag.dart) — enum of flag keys + defaults
- [`RemoteConfigService`](../sprout_app/lib/core/flags/remote_config_service.dart) — `setup` (Firebase + defaults) vs `fetchFlags` / `isEnabled`

`Purchases.configure` is **fail-closed**:

| Flavor | Behaviour |
|--------|-----------|
| development | `RemoteConfigService.setup` + `fetchFlags`, then `isEnabled(RemoteFeatureFlag.revenueCatEnabled)`. Configure only if `true`. Missing Firebase config, offline, or any error → **skip** (detail: `remote flag off`). |
| production | Remote Config not wired yet → setup no-ops → **always skip** configure. |

### Enable for testing (`[DEV] Sprout`)

1. Open [Firebase Console](https://console.firebase.google.com/) → project **sprout-app-development**.
2. **Remote Config** → add parameter:
   - Key: `revenuecat_enabled` (must match `RemoteFeatureFlag.revenueCatEnabled.key`)
   - Type: Boolean
   - Default value: `false`
3. Publish. Set to `true` when you want to test RevenueCat; set back to `false` to disable without a new build.
4. **Cold-start** the development app (full process kill). Hot restart may leave a previously configured native Purchases singleton alone.

In-app defaults also set `revenuecat_enabled: false` before fetch, so an unpublished parameter stays off.

## Verify

1. Run the development flavor with the flag **false** (or unset):

   ```bash
   cd sprout_app
   flutter run --flavor development -t lib/main_development.dart
   ```

   Startup should skip purchases (`remote flag off`); no `Purchases is configured` banner.

2. Set `revenuecat_enabled` to **true**, publish, cold-start again. Expect configure logs and a customer in the [RevenueCat dashboard](https://app.revenuecat.com/) → **Sprout** → **Customers** (App user ID matching the app uid, not `$RCAnonymousID:…`).

3. A wrong API key usually surfaces as an auth error on the first network call (e.g. fetching offerings).

4. If you see `Could not find ProductDetails` / empty offerings with a Test Store key, confirm each Test Store product has a price in the dashboard (or via `create-product-prices`). Products without prices do not resolve in the SDK.

## Paywall UI verify (Settings → Sprout Premium)

1. With `revenuecat_enabled=true`, cold-start the development app so Purchases configure runs.
2. Open **Settings** and look for the tile **Sprout Premium** (it should be absent when the Purchases step is skipped).
3. Tap **Sprout Premium** and verify the RevenueCat paywall appears with the expected Monthly/Annual packages.
   - If you don't see your dashboard template, RevenueCatUI may fall back to
     a default layout when no published paywall is attached to the
     `default` offering.
4. Complete a sandbox purchase:
   - The paywall should dismiss.
   - The app should show `Premium active` on the tile after returning to Settings.
5. Close/dismiss the paywall without purchasing and confirm the app remains usable.

## Later (not done yet)

- Production Remote Config + Play `goog_…` keys (replace Test Store for release builds).
- Create **Play Store** apps in RevenueCat for `app.stackmint.sprout` and `app.stackmint.sprout.dev`, attach Play Console products + service-account credentials.
- Entitlement gating for premium features (unlocking specific app behavior).
- iOS (`appl_…` key) when the `ios/` platform is added.
