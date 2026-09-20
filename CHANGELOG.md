# Changelog

Changes heading to `main`. Newest entries at the top.

## 2026-09-20 — MVP Firebase Analytics event set

- Added Firebase Analytics tracking for development flavor with minimal event set
- Events: `app_open` (automatic), `sign_in_success` with method param, `wizard_completed`, `first_deposit_logged`
- No PII in parameters
- Development flavor sends to Firebase DebugView; production flavor uses same API (PROD Firebase project setup remains #52)
- Added `docs/FIREBASE_ANALYTICS.md` with event documentation and DebugView instructions

## 2026-09-20 — Resend code after create account

- Resend on the verify-email screen no longer treats a pending (unverified) signup as an existing account
- Create account / sign-in email checks only count verified Supabase users, so an unfinished signup can request another code

## 2026-09-20 — Remove sign-out local-data caption

- Settings no longer says signing out keeps local data on the device

## 2026-09-20 — Sign-in unknown-email prompt

- Sign in checks whether the email exists in Supabase before sending an OTP
- Unknown emails get a "No account yet" dialog with a Create account action instead of the verify-code page

## 2026-09-20 — Existing-email create-account prompt

- Create account checks whether the email already exists in Supabase before sending an OTP
- Existing accounts get an "Account already exists" dialog with a Sign in action instead of the verify-code page
- Verify email no longer repeats "Check your email for a 6-digit code" under the form

## 2026-09-20 — Split register and sign-in paths

- Create account requires display name; sign-in is email-only (no name field or overwrite risk)
- Dedicated verify OTP page shared by both paths (back to edit email, resend code)
- Intro gate: first launch shows Create Account primary + "I already have an account" link; later unsigned launches show Sign In
- Register OTP cannot create new users on sign-in path (shouldCreateUser split)
- Sign-out keeps local Hive data (verified in code)

## 2026-09-20 — Fix Google Sign-In false cancellation error

- Google Sign-In now shows accurate error messages when authentication fails
- Configuration errors (SHA-1 mismatch, OAuth client issues) display the underlying error instead of "Sign-In was cancelled."
- True user cancellations still show the cancellation message
- Fixes issue where selecting an account would incorrectly report cancellation

## 2026-09-20 — Local-config sync includes root .pem files

- Export now copies root-level `*.pem` files to the sync destination
- Import restores root-level `*.pem` files from the sync destination
- Status displays LOCAL/DEST presence for root-level `*.pem` files
- Manifest lists all tracked `.pem` paths
- Scope limited to repo root only (not subdirectories)

## 2026-09-20 — Auth auto-submit verify code after 6 digits

- OTP verification field now auto-submits when the 6th digit is entered
- Max length tightened from 8 to 6 digits to match email copy ("6-digit code")
- Paste of 6-digit code also auto-submits
- After failed verification, user can edit and retry without spam-submit (only fires when length becomes 6)
- Manual Verify button kept as fallback

## 2026-09-20 — Guided first-run fallback for empty states

- Overview empty state now disables deposit until both goal AND account exist (updated caption)
- Accounts page shows tappable "Add an account" tile when empty
- Goals page shows tappable "Add a goal" tile when empty
- All empty-state tiles use existing UI patterns and open the same forms as toolbar actions

## 2026-09-20 — Debug bubble toggle applies immediately

- Settings → Debug tools → Show debug bubble hides or shows the floating overlay as soon as the switch changes
- Opening Debug Lens is no longer required for the preference to take effect

## 2026-09-20 — Debug Lens bubble can be hidden

- Show/hide toggle for floating debug bubble in Settings → Debug tools
- Preference persists across app relaunches using SharedPreferences
- Debug Lens remains accessible through Settings when bubble is hidden

## 2026-09-20 — Play Store feature graphic redesign with screenshots

- Feature graphic now shows "Sprout" text + app icon on left, phone screenshots on right with rounded corners (device mockup style)
- Script falls back gracefully to text + icon only if screenshots haven't been captured yet
- Added "Known Gaps" section documenting development banner in screenshots, links to issue #70 for production auth flows
- Updated README with regeneration workflow (capture screenshots first, then regenerate feature graphic)

## 2026-09-20 — Play Store screenshots complete the first-run wizard

- Screenshot capture fills a goal, account, and deposit on the wizard instead of skipping and seeding from Overview
- Shared `complete-wizard` helper is reused by the wizard happy-path journey
- Text fields keep their own semantics node so Maestro can tap the account name without hitting color swatches

## 2026-09-20 — Maestro skips first-run wizard after debug sign-in

- Shared `skip-wizard` helper taps Skip on the first-run wizard before waiting for Overview
- Debug sign-in, intro, and sign-in journeys skip the wizard on a clean install so page flows still land on empty Overview

## 2026-09-20 — Play Store listing assets and Maestro screenshot automation

- Added `store/play/` with icon-512.png and feature-graphic-1024x500.png generated from existing branding
- Added Maestro flow `.maestro/play-store-screenshots.yaml` to capture Overview, Goals, and Accounts screens with seeded data
- Added `tool/capture_play_screenshots.sh` script to run Maestro flow and organize screenshots by device class
- Added `tool/generate_play_assets.py` to regenerate icon and feature graphic from source branding assets
- Screenshots are organized by device class: phone, sevenInch, tenInch

## 2026-09-20 — GitHub Actions Node 24 and Ubuntu pin

- Checkout, Java setup, and Play upload actions now run on Node 24 instead of deprecated Node 20
- Workflows pin `ubuntu-24.04` so `ubuntu-latest` will not silently move to Ubuntu 26 in October

## 2026-09-20 — Release label gate and AGP bump

- Merge-to-main release fails when the PR lacks a valid `major`/`minor`/`patch` label instead of shipping a build-only bump
- Android Gradle Plugin raised to `8.12.1` for `connectivity_plus` 7.x

## 2026-09-20 — GitHub secrets inventory doc

- Added `docs/GITHUB_SECRETS.md`: every Actions secret, source file, encode/`gh` update commands, Play SA permissions, and restore checklist

## 2026-09-20 — Merge-to-main release CI

- Labeled merges to `main` compute the next semver, ship a development APK to Firebase and a production AAB to Play internal, then commit the version only after both uploads succeed
- PRs into `main` require exactly one of `major`, `minor`, `patch`, or `no-build`
- Standalone bump / Firebase / Play workflows are folded into **Release Main** (manual dispatch for retries)

## 2026-09-19 — Debug Lens covers previous screens

- In-panel pages use an opaque Sprout surface again so dashboard tiles do not show through Network and other tools
- Every tool still shares that same surface so the canvas color does not jump on push or pop

## 2026-09-19 — Auto-bump build number on main

- Every merge (or push) to `main` increments the `+N` build in `sprout_app/pubspec.yaml` and commits it
- Play `versionCode` stays unique without a manual bump before each upload
- Uses the same Version Bot GitHub App as Multichoice (`VERSION_BOT_APP_ID` + `VERSION_BOT_APP_PRIVATE_KEY`)

## 2026-09-19 — Debug Lens in-panel navigation flash

- Opening a tool (Network, Logs, …) and returning to the dashboard no longer flashes a different background
- In-panel routes stay transparent over Sprout's canvas instead of each painting their own seed color

## 2026-09-19 — Debug Lens matches app colors

- Debug Lens panel uses Sprout's dark teal canvas instead of the package's navy/indigo background
- Opening and closing the panel no longer flashes a different blue theme

## 2026-09-19 — Debug Lens navigation during build

- Opening the app no longer throws `setState() or markNeedsBuild() called during build` from Debug Lens
- Navigation recording waits until after the current frame so Provider is not notified while GoRouter restores the navigator

## 2026-09-19 — Debug Lens API call sites

- Remote Config values now feed Debug Lens through `DebugLens.instance.setRemoteConfigData`
- Settings opens the panel with `DebugLens.show(context)`
- Root navigator registers `DebugLens.navigatorObserver` so the panel can push

## 2026-09-19 — Debug Lens MVP

- Debug Lens on-device debugging panel available in Settings (gated by flavor + Remote Config)
- Development flavor: always enabled (no Remote Config required)
- Production flavor: Remote Config flag `debug_lens_enabled` (default false) enables break-glass debugging
- Shows network calls, logs, navigation, Remote Config values, and device info
- Entry point: Settings → Debug tools → Debug Lens (only visible when enabled)

## 2026-09-12 — Auth journey: required sign-in (no guest bypass)

- Sign-in is now required after intro carousel — no anonymous or guest bypass
- Offline sign-in messaging: sign-in page shows "You're offline — connect to sign in" banner and disables all auth controls when connectivity unavailable
- Shell offline banner: signed-in users see offline indicator at top of shell when offline
- App confirmed to have no anonymous sign-in calls — `AuthViewGuest` represents the unsigned form state, not a Supabase anonymous user
- Journey: carousel → sign-in (required) → wizard → Overview
- Maestro flow added: `first-open-online.yaml` tests complete first-open auth journey
- Docs updated: `SUPABASE_AUTH_TODOS.md` reflects required sign-in and anonymous disabled

## 2026-09-12 — Wizard first-run edges

- Users who already have a goal or account skip the wizard instead of creating duplicates
- Finish/save failures show a snackbar on the wizard
- Overview empty and populated quick actions match the numbered steps: goal, account, deposit

## 2026-09-12 — Wizard setup polish

- Goal, account, and deposit steps use the same icons and full color palette as the rest of the app
- Target and deposit errors clear when the field is emptied; deposits validate min R10 and the goal target
- Account and goal names must be readable (letters, numbers, spaces) instead of symbol soup
- Step 3 explains the optional first deposit; Allocate later is a checkbox under the amount
- Name errors wrap onto extra lines; the deposit hint sits in its own info banner
- Welcome toast uses dark contrast so the lime accent stays readable

## 2026-09-12 — Wizard redirect loop

- First-run users stay on the setup wizard instead of bouncing `/wizard` → Overview → `/wizard`

## 2026-09-12 — Flutter 3.41.4

- Project and CI pin Flutter **3.41.4** (Dart 3.11.1, DevTools 2.54.1)
- README shows version badges plus the prerequisites table

## 2026-09-12 — First-win setup wizard

- Fresh signup / first successful sign-in routes into 3-step wizard before Overview
- Step 1: Goal (name + target), Step 2: Account (name + color), Step 3: Deposit (amount to both)
- Skip exits immediately and persists — wizard never reappears
- Finish saves goal + account + deposit (amount > 0) and shows one-time "You're growing" toast
- Empty Overview CTAs reordered to goal → account → deposit

## 2026-09-02 — Manage opens Customer Center

- Settings Premium Manage opens RevenueCat Customer Center instead of the paywall
- The tile refreshes after restore, or if Premium is no longer active

## 2026-09-02 — Profile label

- Settings and the account screen say Profile instead of Edit Profile

## 2026-09-02 — Delete account on Edit Profile

- Delete account is a danger tile on Edit Profile, not a Settings footer link

## 2026-09-02 — Add button sits lower

- The center Add disc sits slightly lower on the bottom bar

## 2026-09-02 — Settings hub restyle

- Settings is a profile hub: avatar, name, email, and an Edit Profile button
- Premium shows an ACTIVE / Upgrade card; Finance lists Transactions, Recurring, and Master Budget as separate rows
- Sign out, version, Privacy, Terms, and Delete account live on Settings
- Edit Profile opens a slimmer Account page with display name editing and a coming-soon change-email row

## 2026-09-02 — Shell bottom bar

- Signed-in tabs live in a shared bottom bar widget instead of layout inside the shell
- Page canvas and the bar use distinct Lush Growth fills
- Cards, quick-action tiles, and progress panels use the same olive muted fill
- Selected tab is a terracotta disc with a dark icon; Add sits on top of the bar without a strip above it

## 2026-09-02 — Goal icons

- Create and edit goal include a curated icon picker
- Chosen icon is stored locally, synced to Supabase, and shown on each goal card
- Existing goals without an icon keep the savings default

## 2026-09-02 — Goals page restyle

- Goals header matches the Lush Growth shell, with a short subtitle under the title
- Goal cards show name, saved/target, leading icon, progress ring, and chevron
- Account and goal cards share the same tinted tile treatment
- Unallocated funds card uses a glow icon, title plus amount, and an inset dashed border

## 2026-09-02 — Create goal form

- Name and target show a Required helper
- Amount fields show an `R` prefix while focused or filled
- The sheet scrolls so the icon picker stays reachable above the keyboard

## 2026-09-02 — Goal progress ring at 100%

- The percent label no longer touches the inner ring
- The ring fills the 56px badge instead of Flutter’s 36px default

## 2026-09-02 — Changelog

- Added this file to track features and fixes going into `main`
- Agents prepend a dated title plus bullets when work is ready to merge
