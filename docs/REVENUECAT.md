# RevenueCat (foundation + paywall UI)

Sprout uses [RevenueCat](https://www.revenuecat.com/) for subscriptions.

This pass wires:
- **SDK configure + identity** (after `revenuecat_enabled` kill switch)
- **Paywall UI** via `purchases_ui_flutter` launched from **Settings → Sprout Premium** when the user is not subscribed
- **Customer Center** via `RevenueCatUI.presentCustomerCenter` when the tile shows **Manage** (active `premium`)

No premium feature gating is added yet (premium is opt-in via the paywall tile only).

## Project

| Item | Value |
|------|--------|
| RevenueCat project | **Sprout** (`proj8bd5ebcf`) |
| Store | **Play Store** (production) + **Test Store** (development) |
| Play app | `appcb952e263d` (package `app.stackmint.sprout`) |
| Entitlement | `premium` |
| Offering | `default` (current) |
| Packages | `$rc_monthly` → `premium_monthly`, `$rc_annual` → `premium_annual` |
| Test Store prices | Monthly **ZAR R79.99**, Annual **ZAR R799.99** (for development) |
| Play Store prices | Monthly **R49.99** (7-day trial), Annual **R399** (7-day trial) |

**Production** uses a Play `goog_…` SDK key (safe to embed in the client): put it in gitignored `production.json` as `revenueCatAndroidApiKey`, or override with `--dart-define=REVENUECAT_ANDROID_API_KEY=…`.

**Development** continues using the Test Store public key (`test_…`) for local testing.


## Play Store production setup (#53)

This section documents the one-time Play Console / RevenueCat / GCP setup completed for production subscriptions. Operational runbook for reference if changes are needed.

### RevenueCat project `proj8bd5ebcf` (Sprout)

**Apps:**
- **Play Store app**: Sprout Android (Play) `appcb952e263d`, package `app.stackmint.sprout`
- **Test Store app**: `app643c11c740` (remains for DEV / `test_…` keys only)

**Play Store configuration:**
- Products (Play store identifiers): `premium_monthly:monthly`, `premium_annual:yearly`
- Entitlement: `premium`
- Default offering: `$rc_monthly` + `$rc_annual` only
  - Note: `$rc_weekly` removed from default offering (weekly may still exist in Test Store catalog)
- Locked prices: **R49.99/mo**, **R399/yr** ZAR
- Trial offers: 7-day free trial on both plans (configured as offers in Play Console)

**SDK keys (never commit):**
- Production Play key: `goog_…` → lives in gitignored `production.json` + GitHub secret `APP_CONFIG_PROD_BASE64`
- Development Test Store key: `test_…` → local `development.json` only

### Play Console (app Sprout / `app.stackmint.sprout`)

**Subscriptions Active:**
- Product IDs: `premium_monthly`, `premium_annual`
- Base plans: `monthly`, `yearly`
- Tax category: Digital app sales
- Compliance: Service
- Age rating: Everyone (or all-ages equivalent)
- 7-day trial: configured as an **offer** on each base plan (eligibility: new customer / never had this subscription)

**License testing for sandbox purchases:**
- Account-level: **Settings → License testing**
- Add tester Gmail (same account on device Play Store)
- Also add email as **Internal track tester** to install from Internal Testing

**Real billing smoke test requirements:**
- Install from **Internal testing** (not sideloaded debug APK)
- Build must include `goog_…` config (see Config section)
- This Remote Config wiring (PR #96) merged and in the Internal AAB
- License tester account on device

### GCP `sprout-app-production` — dedicated SA

**Service Account (RevenueCat-only, least privilege):**
- Email: `revenuecat-play@sprout-app-production.iam.gserviceaccount.com`
- Display name: RevenueCat PROD (or similar)
- Why separate: Upload SA has release rights; RC-only SA is least privilege (view financial + manage orders/subscriptions only)

**Play Console → Users and permissions (on Sprout app):**
- View financial data ✓
- Manage orders and subscriptions ✓
- App access ✓
- Note: Catalog checks can pass before purchase-validation; purchase-validation may stay red until propagation / Internal build / first sandbox purchase — not a blocker for SDK key

**GCP IAM roles (on project `sprout-app-production`):**
- **Pub/Sub Admin** (required; Editor alone failed topic create)
- **Monitoring Viewer**

**APIs enabled (GCP Console → APIs & Services):**
- Google Play Android Developer API ✓
- Cloud Pub/Sub ✓

**Real-time developer notifications (RTDN):**
- Topic created: `projects/sprout-app-production/topics/Play-Store-Notifications`
- Wired in Play Console → Monetize → Monetization setup → Real-time developer notifications
- "Send test notification" confirmed green in RevenueCat dashboard

### App config / secrets (ops, not committed)

**Local (gitignored):**
- `sprout_app/assets/config/production.json`:
  ```json
  {
    "revenueCatAndroidApiKey": "goog_..."
  }
  ```
- Keep `config/APP_CONFIG_PROD_BASE64.md` gitignored mirror if that pattern exists

**GitHub Secrets:**
- `APP_CONFIG_PROD_BASE64`: base64 of `production.json` (refreshed after updating `goog_…` key)

**Flavor isolation:**
- **DEV**: Test Store `test_…` + `sprout-app-development` Remote Config
- **PROD**: Play `goog_…` + `sprout-app-production` Remote Config

### Firebase Remote Config (ops)

**Development (`sprout-app-development`):**
- Parameter: `revenuecat_enabled` (Boolean, default `false`)
- Set to `true` for local Test Store testing

**Production (`sprout-app-production`):**
- Parameter: `revenuecat_enabled` (Boolean, default `false`)
- Set to `true` **only after** this PR is in a Play Internal build for smoke testing
- Keep `false` until ready for real billing smoke / beta testers

### Smoke order (production Play billing)

1. This PR (#96) merged to `main`
2. Release Main workflow creates Internal AAB with updated `APP_CONFIG_PROD_BASE64`
3. License tester + Internal tester: same Gmail account
4. Install production flavor from Play Internal Testing link (not sideloaded)
5. Flip `revenuecat_enabled` to `true` in `sprout-app-production` Remote Config; publish
6. Cold-start the production app (full process kill)
7. Navigate to **Settings → Sprout Premium**
8. Verify offerings show R49.99/mo + R399/yr with 7-day trial
9. Complete sandbox purchase
10. Confirm Premium tile shows **ACTIVE** and **Manage** button works

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

### Debug vs release (not flavor)

Flavor (`development` / `production`) and build mode (`debug` / `release`) are independent. `flutter build apk --flavor development` is still a **release** binary.

## Kill switch (Firebase Remote Config)

Code:

- [`RemoteFeatureFlag`](../sprout_app/lib/core/flags/remote_feature_flag.dart) — enum of flag keys + defaults
- [`RemoteConfigService`](../sprout_app/lib/core/flags/remote_config_service.dart) — `setup` (Firebase + defaults) vs `fetchFlags` / `isEnabled`

`Purchases.configure` is **fail-closed**:
| Flavor | Behaviour |
|--------|-----------|
| development | `RemoteConfigService.setup` + `fetchFlags`, then `isEnabled(RemoteFeatureFlag.revenueCatEnabled)`. Configure only if `true`. Missing Firebase config, offline, or any error → **skip** (detail: `remote flag off`). |
| production | `RemoteConfigService.setup` + `fetchFlags`, then `isEnabled(RemoteFeatureFlag.revenueCatEnabled)`. Configure only if `true`. Missing Firebase config, offline, or any error → **skip** (detail: `remote flag off`). |

### Enable for testing

**Development:** Open [Firebase Console](https://console.firebase.google.com/) → project **sprout-app-development**.

**Production:** Open [Firebase Console](https://console.firebase.google.com/) → project **sprout-app-production**.

For either flavor:

1. **Remote Config** → add parameter:
   - Key: `revenuecat_enabled` (must match `RemoteFeatureFlag.revenueCatEnabled.key`)
   - Type: Boolean
   - Default value: `false`
2. Publish. Set to `true` when you want to test RevenueCat; set back to `false` to disable without a new build.
3. **Cold-start** the app (full process kill). Hot restart may leave a previously configured native Purchases singleton alone.

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

## Customer Center verify (Settings → Manage)

1. After a sandbox purchase, the tile should show **ACTIVE** and **Manage**.
2. Tap **Manage**. The RevenueCat Customer Center should open and list the Test Store subscription (restore + cancel survey).
3. Dismiss the sheet. The tile should still show **ACTIVE** if the entitlement is unchanged.
4. Tap **Restore purchases** inside Customer Center, dismiss, and confirm the app shows `Premium unlocked.`
5. If the entitlement is gone after dismiss (cancelled / expired), the tile should switch back to **Upgrade** and show `Premium is no longer active.`

On Test Store (development), store-native cancel/manage will not open Google Play. On production with a Play `goog_…` key installed from Play Internal Testing, native manage buttons will open the Play subscription management page.

Dashboard: [RevenueCat](https://app.revenuecat.com/) → **Sprout** → **Customer Center**. Defaults are enough; optional later: support email, Sprout teal accent.

## Later (not done yet)

- Entitlement gating for premium features (unlocking specific app behavior).
- iOS (`appl_…` key) when the `ios/` platform is added.
