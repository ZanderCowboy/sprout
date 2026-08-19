# Supabase auth setup

Flutter auth is **already built**. This file is only the human console work + device checks.

**Do one environment at a time.** Right now: **dev only**. Ignore prod until Google sign-in works on a development build.

---

## Status checklist

Tick here as you go. Each open item jumps to the step below.

### Done (dev)

- [x] Flutter auth (OTP UI, Google, sync gate, sign-out, **required sign-in after intro**)
- [x] Dev Supabase URL + anon key in `development.json`
- [x] Migrations applied (dev)
- [x] Google provider enabled in Supabase (dev) with Web Client ID + secret
- [x] `googleWebClientId` set in `development.json`
- [x] Anonymous sign-ins **disabled**
- [x] [Email OTP](#4-email-otp-dev--done): custom SMTP + Magic link template + sign-in with code ([Resend walkthrough](RESEND_SMTP_SUPABASE.md))
- [x] Package ids decided: `app.stackmint.sprout` + `app.stackmint.sprout.dev` ([product decision](#a-product-decision-you))
- [x] Play Console never created under the old package ([product decision](#a-product-decision-you))



### Dev — still to do (this order)

- [x] [Set Site URL](#1-set-site-url-2-minutes) on the **dev** Supabase project
- [x] [Confirm Android OAuth client](#2-confirm-android-oauth-client-google-cloud) for the **pre-rename** package `co.za.zanderkotze.sprout.dev` + debug SHA-1 (recreate for `app.stackmint.sprout.dev` in [D](#d-you--google-cloud-oauth))
- [x] [Google sign-in works on device](#3-device-test-google-main-goal-for-tonight) (dev flavor)
- [ ] [Sign-out keeps local data](#3-device-test-google-main-goal-for-tonight)
- [x] [Re-login with Google works](#3-device-test-google-main-goal-for-tonight)
- [x] [Optional cleanup](#5-optional-cleanup-dev-only): delete old anonymous users / orphaned rows
- [ ] [Paste Terms and Privacy into Firebase Remote Config](#7-terms-and-privacy-firebase-remote-config-dev)
- [ ] [Apply delete-account migration](#8-delete-account-rpc-dev) on the **dev** Supabase project



### After Google works on current package

- [ ] [Rename Android application id](#package-rename-todo) to `app.stackmint.sprout` (agent code done; your Firebase / Google Cloud / Play still open)
  - [x] [Agent: gradle, MainActivity, JSON, CI, tests, docs](#b-agent--code--repo)
  - [ ] [You: Firebase Android apps +](#c-you--firebase) `google-services.json`
  - [ ] [You: new Android OAuth clients](#d-you--google-cloud-oauth)
  - [ ] [You: Play / RevenueCat / re-test Google](#f-you--play--revenuecat--devices)
  - [ ] [CI secrets after rename](#g-ci-secrets-after-rename)



### Later (not tonight)

- [ ] [Prod auth console + Google on production flavor](#6-prod--do-not-start-until-step-3-passes)
- [ ] Prod Custom SMTP + Magic link template ([Resend — prod later](RESEND_SMTP_SUPABASE.md#prod-later))
- [ ] [Deferred](#deferred-not-now): magic-link deep links, Apple / iOS, email+password

---



## What’s left for DEV (do in this order)



### 1. Set Site URL (2 minutes)

**Where:** Supabase **dev** project → **Authentication → URL Configuration**

**What to type in Site URL:**

```text
https://stackmint.app
```

That is fine even though the domain currently redirects to MultiChoice.


| Question                  | Answer                                                                                      |
| ------------------------- | ------------------------------------------------------------------------------------------- |
| Why set it at all?        | Supabase requires a Site URL. It is used mainly for **email links** (magic link / confirm). |
| Does OTP need it?         | **Typed 6-digit OTP does not open this URL.** You still set it so Auth is configured.       |
| Does Google need it?      | **No.** Google Sign-In does not use Site URL.                                               |
| Additional Redirect URLs? | Leave **empty** for now (no deep links yet).                                                |
| Alternative if you prefer | `https://uprntgokadmkrjrklsyr.supabase.co` (your dev project URL) also works.               |


- [x] Site URL set on **dev** Supabase project → Save

---



### 2. Confirm Android OAuth client (Google Cloud)

Google Sign-In on a phone only works if Google Cloud has an **Android** client that matches the APK you install.

**Where:** [Credentials](https://console.cloud.google.com/apis/credentials?project=sprout-app-development) → look for an OAuth client of type **Android**.

It must be:


| Field        | Value (before rename — already done)                |
| ------------ | --------------------------------------------------- |
| Package name | `co.za.zanderkotze.sprout.dev`                      |
| SHA-1        | Your **debug** keystore SHA-1 (local `flutter run`) |


The repo now uses `app.stackmint.sprout.dev`. Create a **new** Android OAuth client with that package + the same debug SHA-1 ([D](#d-you--google-cloud-oauth)). The old client can stay unused.

Get SHA-1:

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android
```

Copy the `SHA1:` line into the Android OAuth client if it is missing.

- [x] Android OAuth client exists for `co.za.zanderkotze.sprout.dev` + debug SHA-1  
  (Nothing from this client goes into `development.json`.)

**Reminder — where Google values go:**


| Value             | Supabase Google provider | `development.json`        |
| ----------------- | ------------------------ | ------------------------- |
| Web Client ID     | Yes                      | Yes → `googleWebClientId` |
| Web Client secret | Yes                      | **Never**                 |
| Android client    | No (Google Cloud only)   | **Never**                 |


---



### 3. Device test Google (main goal for tonight)

Email OTP already works. Google does not use SMTP or email templates.

1. Run **development** flavor (VS Code **Sprout · dev · …**, or
  `flutter run --flavor development -t lib/main_development.dart`).
2. Fresh install: intro → **Sign in** → **Continue with Google**. Later launches skip intro and land on sign-in.
3. Pick a Google account → should end signed in (overview, not the sign-in form).
4. Create a local account/goal while signed in → data should sync to Supabase (check Table Editor).
5. Settings → **Account** tile shows name/email (not “Sign in…”). Account page: avatar, name, email, sign out, Terms, delete.
6. Settings → **Account** → Sign out → back on sign-in, not an empty overview.
7. Sign in with Google again → same user, cloud data still there.
8. Delete account → confirm (copy mentions Premium / Play billing if subscribed) → back on sign-in; that Google/email has no old cloud data. Needs [step 8](#8-delete-account-rpc-dev) applied.

- [x] Google sign-in works on device (dev)
- [ ] Sign-out keeps local data
- [x] Re-login works

If Google fails: wrong SHA-1 / wrong package on the Android OAuth client is the usual cause. Check Supabase **Logs → Auth** and the app error message.

---



### 4. Email OTP (dev) — done

Custom SMTP + Magic link template (`{{ .Token }}`) + in-app sign-in with the 6-digit code.

Walkthrough if you ever need to redo it (or set up **prod**): [RESEND_SMTP_SUPABASE.md](RESEND_SMTP_SUPABASE.md).

- [x] Custom SMTP on **dev** Supabase
- [x] Magic link template includes `{{ .Token }}`
- [x] App: intro → sign-in → send code → enter 6 digits → signed in

---



### 5. Optional cleanup (dev only)

- [ ] Authentication → Users: delete old anonymous users
- [ ] Wipe orphaned rows in `accounts` / `goals` / `transactions` / `budget_groups` if junk from earlier tests

---



### 7. Terms and Privacy (Firebase Remote Config, dev)

The app shows Terms and the Privacy Policy **in-app** (not a website). Markdown is loaded from Firebase Remote Config strings `terms_of_service` and `privacy_policy`. Until those parameters exist (or the device is offline / RC setup is skipped), it uses the current drafts bundled in [`sprout_app/assets/legal/terms.md`](../sprout_app/assets/legal/terms.md) and [`sprout_app/assets/legal/privacy.md`](../sprout_app/assets/legal/privacy.md). Paste **that same markdown** into RC so fetched clients stay in sync with the bundle.

A public Privacy Policy at `https://privacy.stackmint.app/` is intended later (you own DNS/hosting). Until then, the in-app version is current.

**Where:** [Firebase → sprout-app-development → Remote Config](https://console.firebase.google.com/project/sprout-app-development/config)

1. Add parameter **`terms_of_service`** (type **String**). Paste the markdown from `sprout_app/assets/legal/terms.md`.
2. Add parameter **`privacy_policy`** (type **String**). Paste the markdown from `sprout_app/assets/legal/privacy.md`.
3. Publish the changes.

Prod keeps the bundled files until prod Firebase Remote Config is turned on.

- [ ] Dev Remote Config: `terms_of_service` string published
- [ ] Dev Remote Config: `privacy_policy` string published

---



### 8. Delete-account RPC (dev)

Flutter already calls `supabase.rpc('delete_own_account')` from Account → **Delete account**. The SQL is in [`supabase/migrations/20260819120000_delete_own_account.sql`](../supabase/migrations/20260819120000_delete_own_account.sql).

**Human action required:** apply that migration on the **dev** Supabase project (SQL editor, or `supabase db push` if the CLI is linked). Until it is applied, in-app delete will fail at the RPC.

The function is `private.delete_own_account()` (`SECURITY DEFINER`, deletes `auth.users` where `id = auth.uid()`) plus a thin `public.delete_own_account()` invoker wrapper for the client. Existing tables already `references auth.users (id) on delete cascade`.

Apply the same file on **prod** later, when you do the prod auth pass. Deletion does **not** cancel Play billing / RevenueCat entitlements; the confirm sheet tells the user to manage Premium separately.

- [ ] Dev: run `20260819120000_delete_own_account.sql`
- [ ] Prod (later): same migration

---



### 6. Prod — do not start until step 3 passes

When you are ready (separate checklist later):

- Prod Supabase: Google provider, Anonymous off, Site URL, migrations
- Prod Web Client ID → `production.json` `googleWebClientId`
- Android OAuth client for `app.stackmint.sprout` + **release** SHA-1
- Device test on production flavor

---



## Site URL (reference)


| Use case                           | What Site URL does                                              |
| ---------------------------------- | --------------------------------------------------------------- |
| Google Sign-In                     | Unused                                                          |
| Email OTP (typed code)             | Unused for redirect; still set a valid `https://…` URL          |
| Magic link / confirm email (later) | Browser opens this (or Additional Redirect URLs) after the link |


**Dev recommendation:** `https://stackmint.app`  
**Also OK:** your Supabase project URL  
**Not needed yet:** Additional Redirect URLs, Android deep links

---



## Package rename TODO

**Ids (in the repo now):**


| Flavor      | Current                        | New                        |
| ----------- | ------------------------------ | -------------------------- |
| development | `co.za.zanderkotze.sprout.dev` | `app.stackmint.sprout.dev` |
| production  | `co.za.zanderkotze.sprout`     | `app.stackmint.sprout`     |


Repo code now uses the **new** ids. Recreate Firebase Android apps and Google Cloud Android OAuth clients before Google sign-in will work again. Uninstall the old APK first (new package = a second app on the device).

### A. Product decision (you)

- [x] Confirm final ids: `app.stackmint.sprout` + `app.stackmint.sprout.dev`
- [x] Confirm Play Console apps were **never** created under the old package (if they were, old package is stuck forever on Play — you’d create a **new** Play app under the new id)



### B. Agent — code / repo

- [x] `sprout_app/android/app/build.gradle.kts`: `applicationId` + `namespace` → `app.stackmint.sprout` (keep `.dev` suffix on development flavor)
- [x] Move `MainActivity.kt` to `…/kotlin/app/stackmint/sprout/` and update `package`
- [x] `development.json` / `production.json`: `androidApplicationId` (local gitignored files)
- [x] `.github/workflows/play-publish-prod-android.yml`: `packageName`
- [x] Tests that hardcode the old id
- [x] Docs: `README.md`, `docs/FIREBASE_DEV_DISTRIBUTION.md`, `docs/PLAY_PUBLISH_PROD_ANDROID.md`, `docs/REVENUECAT.md`, this file
- [x] Run analyze / tests



### C. You — Firebase

Firebase **project** stays the same (`sprout-app-development` for nightly, `sprout-app-production` later). You add a **second Android app** inside that project with the new package. The old `co.za.zanderkotze…` app can sit unused.

**Do now (dev only).** Skip production until Google works on `[DEV] Sprout`.

**Where:** [Firebase → sprout-app-development → Project settings → Your apps](https://console.firebase.google.com/project/sprout-app-development/settings/general)


| Flavor                | Firebase project         | Android package to register |
| --------------------- | ------------------------ | --------------------------- |
| development (tonight) | `sprout-app-development` | `app.stackmint.sprout.dev`  |
| production (later)    | `sprout-app-production`  | `app.stackmint.sprout`      |


**Add app (if not already):** **Add app** → Android → package name exactly as the table → nickname e.g. `Sprout Dev` → register. Skip `google-services.json` download in the wizard if you already replaced the file.

**File on disk (gitignored):** `sprout_app/android/app/src/development/google-services.json`

That JSON may list **two** `client` entries (old package + new). That is fine. Gradle picks the client whose `package_name` matches the APK.

**Copy into** `sprout_app/assets/config/development.json` ****`firebase` **{ }** — use the client whose `android_client_info.package_name` is `app.stackmint.sprout.dev`, not the leftover old package:


| `google-services.json`                           | `development.json` `firebase` |
| ------------------------------------------------ | ----------------------------- |
| `client_info.mobilesdk_app_id` (`1:…:android:…`) | `appId`                       |
| `api_key[].current_key`                          | `apiKey`                      |
| `project_info.project_number`                    | `messagingSenderId`           |
| `project_info.project_id`                        | `projectId`                   |
| `project_info.storage_bucket`                    | `storageBucket`               |


Leave `androidApplicationId` as `app.stackmint.sprout.dev`. Do not put OAuth client IDs here.

If `firebase.appId` still matches the **old** package’s `mobilesdk_app_id`, Remote Config / Crashlytics / App Distribution talk to the wrong Android app.

**App Distribution** `FIREBASE_APP_ID`**:** same value as the **new** `mobilesdk_app_id` (Project settings → your **new** Android app → App ID). Used by the [Firebase Distribute](FIREBASE_DEV_DISTRIBUTION.md) workflow.

**CI file secret:** after the JSON on disk is the real download (not a hand-patched `package_name`), re-encode and paste into GitHub **Settings → Secrets**:

```bash
base64 -i sprout_app/android/app/src/development/google-services.json | tr -d '\n'
```

→ `GOOGLE_SERVICES_DEV_BASE64`. Production twin later: `…/src/production/google-services.json` → `GOOGLE_SERVICES_PROD_BASE64`.

**Old Firebase Android apps:** ignore or delete `co.za.zanderkotze.sprout.dev` once the new app is proven. Deleting is optional; leftover clients in `google-services.json` are harmless.

- [x] Firebase project(s): add Android apps with **new** package names (`app.stackmint.sprout.dev` on the **development** project, `app.stackmint.sprout` on **production**)
- [x] Download new `google-services.json` → `android/app/src/development/` (and `…/production/` when you do prod)
- [x] Update `firebase` block in `development.json` from the **new** package’s `mobilesdk_app_id` (see table)
- [x] Re-encode `GOOGLE_SERVICES_DEV_BASE64` (prod secret later)
- [x] GitHub secret `FIREBASE_APP_ID` = new Android App ID
- [x] GitHub secret `GOOGLE_SERVICES_DEV_BASE64`
- [x] Remove or ignore old Firebase Android apps with the old package

---



### D. You — Google Cloud OAuth

Google Sign-In on device matches **package name + SHA-1** on an **Android** OAuth client. The **Web** client is unchanged (already in Supabase + `googleWebClientId`).

**Do now (dev / debug installs).** Create the production + **release** SHA-1 client only when you run a signed production APK/AAB.

**Where:** [Credentials — sprout-app-development](https://console.cloud.google.com/apis/credentials?project=sprout-app-development) → **Create credentials** → **OAuth client ID** → Application type **Android**.


| When                            | Package name               | SHA-1                                      |
| ------------------------------- | -------------------------- | ------------------------------------------ |
| Tonight (`flutter run` / debug) | `app.stackmint.sprout.dev` | **Debug** keystore (same as before rename) |
| Later (signed prod / Play)      | `app.stackmint.sprout`     | **Release** / Play App Signing cert        |


Debug SHA-1 (same command as [step 2](#2-confirm-android-oauth-client-google-cloud)):

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android
```

Copy the `SHA1:` fingerprint (colons allowed). Name the client e.g. `Sprout Dev Android`.

Release SHA-1 (when needed): `keytool -list -v` on the **upload** keystore from `ANDROID_SIGNING_CONFIG_BASE64`, **or** Play Console → **Setup → App signing** → SHA-1 of the **app signing** certificate (installs from Play use that, not the upload key).


| Value             | Goes into Supabase Google provider? | Goes into flavor JSON?    |
| ----------------- | ----------------------------------- | ------------------------- |
| Web Client ID     | Yes                                 | Yes → `googleWebClientId` |
| Web Client secret | Yes                                 | **Never**                 |
| Android client ID | **No** (Google Cloud only)          | **Never**                 |


You do **not** paste the Android client ID anywhere in the app. If Google still fails after this: SHA-1/package mismatch, or you installed the **old** APK beside the new one and tapped the wrong icon.

Old Android clients for `co.za.zanderkotze…`: leave them; delete only when you are sure nothing uses them.

- [x] New **Android** OAuth client: `app.stackmint.sprout.dev` + debug SHA-1
- [ ] New **Android** OAuth client: `app.stackmint.sprout` + release SHA-1 (when needed)
- [x] Web client unchanged (same ID / secret in Supabase + `googleWebClientId`)
- [ ] Delete or ignore old Android OAuth clients for `co.za.zanderkotze…`

---



### E. You — Supabase

OTP and Google **Web** settings do not store the Android package name. After the rename you usually **change nothing** on the **dev** project.

**Where:** Supabase **dev** project → **Authentication → Providers → Google**


| Field                           | After rename                                                                                                                                                     |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Client IDs (Web)                | Keep the existing Web client (same as `googleWebClientId`)                                                                                                       |
| Client secret (Web)             | Keep                                                                                                                                                             |
| Authorized Client IDs / Android | Only if the UI shows extra Android client IDs — add the **new** Android OAuth client from [D](#d-you--google-cloud-oauth). Many projects work with **Web only**. |
| Anonymous                       | Stay **off**                                                                                                                                                     |
| Site URL                        | Keep `https://stackmint.app` ([step 1](#1-set-site-url-2-minutes))                                                                                               |


Email OTP is independent of package id. If Google fails, check **Logs → Auth** after a sign-in attempt; a package/SHA mismatch shows up on the Google/Android side more often than here.

- [ ] Confirm Google provider is still Web client only (or updated Android client IDs if the UI lists them)
- [ ] Confirm Anonymous is still off
- [x] Site URL can stay `https://stackmint.app`

---



### F. You — Play / RevenueCat / devices

**Tonight: device only.** Play Console and RevenueCat Play apps are not required for debug Google sign-in or Test Store IAP.

**Uninstall the old app first.** `app.stackmint.sprout.dev` is a **different** app from `co.za.zanderkotze.sprout.dev`. Both can sit on the phone (two launcher icons). Google / Hive / Firebase will look like “sign-in is broken” if you open the old one.

1. On the device: Settings → Apps → uninstall **Sprout** / **[DEV] Sprout** that was the old package (or uninstall both, then reinstall).
2. Run development flavor: `flutter run --flavor development -t lib/main_development.dart` (or **Sprout · dev · …**).
3. Repeat [step 3](#3-device-test-google-main-goal-for-tonight): intro or sign-in → Google → signed in → sync → sign out returns to sign-in → Google again.

**Play Console (later, when you publish):** create the store listing with package `app.stackmint.sprout` **only**. Never create a Play app under `co.za.zanderkotze…`. Full publish steps: [PLAY_PUBLISH_PROD_ANDROID.md](PLAY_PUBLISH_PROD_ANDROID.md). Dev builds stay on Firebase App Distribution (`app.stackmint.sprout.dev` is not a Play app).

**RevenueCat (later, when leaving Test Store):** project **Sprout** still uses Test Store (`test_…` keys). Play package linkage is only needed when you attach a **Play Store** app and `goog_…` keys. Then register `app.stackmint.sprout` (and `.dev` only if you sell on a separate Play app). See [REVENUECAT.md](REVENUECAT.md).

- [ ] Uninstall old APK from devices (new package = separate app)
- [ ] Re-test Google sign-in after [C](#c-you--firebase) `firebase.appId` + [D](#d-you--google-cloud-oauth)
- [ ] Play Console: create apps under **new** package names only (when ready to publish)
- [ ] RevenueCat: Play package linkage when leaving Test Store

---



### G. CI secrets after rename

GitHub **Settings → Secrets and variables → Actions**. Re-encode whenever the **file on disk** changes. Workflow `packageName` for Play is already `app.stackmint.sprout` in `[.github/workflows/play-publish-prod-android.yml](../.github/workflows/play-publish-prod-android.yml)`.

**Do now if you use Firebase App Distribution.** Prod Play secrets can wait.

From the repo root:

```bash
# After development.json firebase block is correct
base64 -i sprout_app/assets/config/development.json | tr -d '\n'
# → APP_CONFIG_DEV_BASE64

# After google-services.json is the Firebase download for the new package
base64 -i sprout_app/android/app/src/development/google-services.json | tr -d '\n'
# → GOOGLE_SERVICES_DEV_BASE64
```


| Secret                            | When to update                                 | Value                                                       |
| --------------------------------- | ---------------------------------------------- | ----------------------------------------------------------- |
| `APP_CONFIG_DEV_BASE64`           | After [C](#c-you--firebase) flavor JSON change | base64 of `development.json`                                |
| `GOOGLE_SERVICES_DEV_BASE64`      | After new `google-services.json`               | base64 of `src/development/google-services.json`            |
| `FIREBASE_APP_ID`                 | After new Android app                          | New `1:…:android:…` (same as `firebase.appId`)              |
| `FIREBASE_SERVICE_ACCOUNT_JSON`   | Usually unchanged                              | Same service account if it still has App Distribution Admin |
| `ANDROID_SIGNING_CONFIG_BASE64`   | Unchanged                                      | Keystore blob; not package-specific                         |
| `APP_CONFIG_PROD_BASE64`          | Later                                          | After `production.json` is filled                           |
| `GOOGLE_SERVICES_PROD_BASE64`     | Later                                          | Prod `google-services.json`                                 |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Later                                          | Play API account for package `app.stackmint.sprout`         |


If `APP_CONFIG_DEV_BASE64` is missing, CI still builds with a **placeholder** config ([FIREBASE_DEV_DISTRIBUTION.md](FIREBASE_DEV_DISTRIBUTION.md)) — testers would not get your real Supabase/Firebase ids. Update it once `development.json` is right.

- [ ] `APP_CONFIG_DEV_BASE64` (and `APP_CONFIG_PROD_BASE64` when prod JSON changes)
- [ ] `GOOGLE_SERVICES_DEV_BASE64` (prod twin later)
- [ ] `FIREBASE_APP_ID` matches the new Android app
- [x] Workflow `packageName` is `app.stackmint.sprout` (repo already updated)

---



## Locked product rules (short)

1. **No guest mode.** First launch shows a custom intro, then sign-in. Later unsigned launches skip intro and land on sign-in. The shell is not reachable until there is a verified (non-anonymous) session.
2. After sign-in: **discard leftover guest Hive** (do not migrate it onto the new uid), then pull cloud. Same-account re-login: keep local cache, flush pending, pull. Different verified account: clear Hive + pending, then pull.
3. Sign-out: session only; return to sign-in. Local cache stays for that uid until a different account signs in.
4. Startup failure: **Retry only** — no Continue local-only.
5. Providers: email OTP + Google on Android. No Apple / iOS yet.
6. Email OTP: optional **display name** (saved to `user_metadata.display_name`). Google: use the Google profile name already in metadata; do not ask again.
7. Sign-in agrees to **in-app Terms and Privacy Policy** (tappable links on the sign-in screen; Account has the same rows). Markdown comes from Firebase Remote Config `terms_of_service` and `privacy_policy`, with bundled [`sprout_app/assets/legal/terms.md`](../sprout_app/assets/legal/terms.md) and [`sprout_app/assets/legal/privacy.md`](../sprout_app/assets/legal/privacy.md) as fallback.
8. **Delete account** (in-app, Play requirement) calls `public.delete_own_account()` which deletes `auth.users` for `auth.uid()`. Cloud rows cascade. Local Hive entity boxes and pending sync are cleared; `intro_completed` stays. RevenueCat `logOut` runs if Purchases is configured. Sign-out then returns to the sign-in gate. **Premium / Play billing is separate** — deletion does not cancel or refund a subscription.

Config shape: [supabase/README.md](../supabase/README.md).

---



## Deferred (not now)

- OS / magic-link deep links: Android intent-filters, Digital Asset Links, App Links / custom scheme, Additional Redirect URLs in Supabase. In-app paths already live on go_router (`AppRoute`); content URLs should reuse those paths. Auth magic-link callbacks must use a **distinct** path (not `/sign-in` or `/overview`) so `supabase_flutter` can handle them.
- Apple / iOS  
- Email + password + 2FA  
- Prod auth console pass (after dev Google works)

