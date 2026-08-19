# Supabase auth setup

Flutter auth is **already built**. This file is only the human console work + device checks.

**Do one environment at a time.** Right now: **dev only**. Ignore prod until Google sign-in works on a development build.

---

## Status checklist

Tick here as you go. Each open item jumps to the step below.

### Done (dev)

- [x] Flutter auth (OTP UI, Google, sync gate, sign-out)
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
- [x] [Confirm Android OAuth client](#2-confirm-android-oauth-client-google-cloud) for `co.za.zanderkotze.sprout.dev` + debug SHA-1
- [x] [Google sign-in works on device](#3-device-test-google-main-goal-for-tonight) (dev flavor)
- [ ] [Sign-out keeps local data](#3-device-test-google-main-goal-for-tonight)
- [x] [Re-login with Google works](#3-device-test-google-main-goal-for-tonight)
- [x] [Optional cleanup](#5-optional-cleanup-dev-only): delete old anonymous users / orphaned rows



### After Google works on current package

- [ ] [Rename Android application id](#package-rename-todo) to `app.stackmint.sprout` (agent code + your Firebase / Google Cloud / Play)
  - [ ] [Agent: gradle, MainActivity, JSON, CI, tests, docs](#b-agent--code--repo)
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


| Field        | Value (current package)                             |
| ------------ | --------------------------------------------------- |
| Package name | `co.za.zanderkotze.sprout.dev`                      |
| SHA-1        | Your **debug** keystore SHA-1 (local `flutter run`) |


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
2. Settings → **Account** → **Continue with Google**.
3. Pick a Google account → should end signed in (email shown, Sign out available).
4. Create a local account/goal while signed in → data should sync to Supabase (check Table Editor).
5. Sign out → local data still there; sync off.
6. Sign in with Google again → same user, data still there.

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
- [x] App: Settings → Account → send code → enter 6 digits → signed in

---



### 5. Optional cleanup (dev only)

- [ ] Authentication → Users: delete old anonymous users
- [ ] Wipe orphaned rows in `accounts` / `goals` / `transactions` / `budget_groups` if junk from earlier tests

---



### 6. Prod — do not start until step 3 passes

When you are ready (separate checklist later):

- Prod Supabase: Google provider, Anonymous off, Site URL, migrations
- Prod Web Client ID → `production.json` `googleWebClientId`
- Android OAuth client for `co.za.zanderkotze.sprout` + **release** SHA-1
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

**Target (proposed):**


| Flavor      | Current                        | New                        |
| ----------- | ------------------------------ | -------------------------- |
| development | `co.za.zanderkotze.sprout.dev` | `app.stackmint.sprout.dev` |
| production  | `co.za.zanderkotze.sprout`     | `app.stackmint.sprout`     |


Do **not** rename mid–Google debug unless you want to recreate Android OAuth + Firebase apps in the same sitting. Prefer: finish Google on current ids → then rename → recreate console apps.

### A. Product decision (you)

- [x] Confirm final ids: `app.stackmint.sprout` + `app.stackmint.sprout.dev`
- [x] Confirm Play Console apps were **never** created under the old package (if they were, old package is stuck forever on Play — you’d create a **new** Play app under the new id)



### B. Agent — code / repo

- [ ] `sprout_app/android/app/build.gradle.kts`: `applicationId` + `namespace` → `app.stackmint.sprout` (keep `.dev` suffix on development flavor)
- [ ] Move `MainActivity.kt` to `…/kotlin/app/stackmint/sprout/` and update `package`
- [ ] `development.json` / `production.json`: `androidApplicationId`
- [ ] `.github/workflows/play-publish-prod-android.yml`: `packageName`
- [ ] Tests that hardcode the old id
- [ ] Docs: `README.md`, `docs/FIREBASE_DEV_DISTRIBUTION.md`, `docs/PLAY_PUBLISH_PROD_ANDROID.md`, `docs/REVENUECAT.md`, this file
- [ ] Run analyze / tests



### C. You — Firebase

- [ ] Firebase project(s): add Android apps with **new** package names
- [ ] Download new `google-services.json` →  
  `android/app/src/development/` and `…/production/`
- [ ] Update `firebase` block inside flavor JSON from the new files
- [ ] Re-encode CI secrets `GOOGLE_SERVICES_DEV_BASE64` / `GOOGLE_SERVICES_PROD_BASE64` if used
- [ ] Update Firebase App Distribution `FIREBASE_APP_ID` if the Android app id changes
- [ ] Remove or ignore old Firebase Android apps with the old package



### D. You — Google Cloud OAuth

- [ ] New **Android** OAuth client: `app.stackmint.sprout.dev` + debug SHA-1
- [ ] New **Android** OAuth client: `app.stackmint.sprout` + release SHA-1 (when needed)
- [ ] Web client can stay (same Client ID / secret in Supabase + `googleWebClientId`)
- [ ] Delete or ignore old Android OAuth clients for `co.za.zanderkotze…`



### E. You — Supabase

- [ ] No package-id field required for OTP
- [ ] If Google provider UI lists Android clients, update to the new ones (often Web-only is enough)
- [x] Site URL can stay `https://stackmint.app`



### F. You — Play / RevenueCat / devices

- [ ] Play Console: create apps under **new** package names only (when ready to publish)
- [ ] RevenueCat: new Play package linkage when leaving Test Store
- [ ] Uninstall old APK from devices (new package = separate app)
- [ ] Re-test Google sign-in after rename



### G. CI secrets after rename

- [ ] `APP_CONFIG_DEV_BASE64` / `APP_CONFIG_PROD_BASE64` if JSON changed
- [ ] Google services base64 secrets (above)
- [ ] Confirm workflow `packageName` matches Play

---



## Locked product rules (short)

1. Guest = local Hive only; sync only after verified (non-anonymous) session.
2. Providers: email OTP + Google on Android. No Apple / iOS yet.
3. Sign-out keeps local data. Switching to a different verified account replaces local Hive then pulls remote.

Config shape: [supabase/README.md](../supabase/README.md).

---



## Deferred (not now)

- Magic link deep links / Android intent-filters  
- Apple / iOS  
- Email + password + 2FA  
- Prod auth console pass (after dev Google works)

