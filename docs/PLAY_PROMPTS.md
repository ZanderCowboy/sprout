# Play soft prompts (#104 / #105)

Android-only soft prompts. iOS is out of scope.

## Update prompt (#104 / fix #113)

- **Trigger:** cold start and app resume (`AppLifecycleState.resumed`) via `PlayPromptsHost`.
- **Ready gate:** the host waits until the navigator is mounted and the route is **not** `/loading` (auth gate). It retries a few times (~750ms) so a cold-start check is not lost while go_router is still redirecting. Showing over `/loading` used to race with redirect and suppress the day without a visible sheet (#113).
- **Availability gate:** `InAppUpdate.checkForUpdate()` reports `updateAvailable`. Play can lag briefly after a new Internal/track publish; resume/cold start re-checks. Exceptions from the Play API are treated as “not available” (no sheet).
- **Once-per-calendar-day suppress (intentional, testable):** SharedPreferences key `play_update_prompt_last_day` stores the local `yyyy-MM-dd` when the sheet was **actually presented and closed** (Update, Later, or dismiss). Same calendar day → no sheet. Next local day → eligible again if Play still reports an update. Accidental mark-before-show was removed in #113.
- **Update:** opens the Play Store listing for `AppConfig.androidApplicationId`:
  - `market://details?id=<applicationId>`
  - fallback `https://play.google.com/store/apps/details?id=<applicationId>`
  - Does **not** start flexible or immediate in-app update flows.
- **Later / dismiss:** closes the sheet; non-blocking; sets the once-per-day key after close.

### Manual repro (QA / Internal)

1. Install an older Internal build (e.g. 1.5.0 / versionCode 25) from Play Internal.
2. Publish a newer Internal build (e.g. 1.6.0 / 26) and wait until Play shows it as available for the tester account (Play Store → app → Update, or allow propagation time).
3. Cold-start the older install (or background → resume). After auth leaves `/loading`, the update sheet should appear when Play reports `updateAvailable` and today’s cooldown key is unset.
4. Tap **Later** (or dismiss). Confirm prefs: `play_update_prompt_last_day` equals today’s local date; further cold starts/resumes **same day** do not show the sheet.
5. Change the device date forward one day (or clear the pref) and resume: sheet can show again if Play still reports an update.
6. Clear app data / uninstall clears the day key (fresh install is eligible again).

## Review prompt (#105)

- **Trigger:** after a successful deposit sheet submit (`DepositSubmitSuccess`), when `UserContext.firstDepositLogged` is true for the active user.
- **Choice:** first deposit success is the success moment (existing `first_deposit_logged` analytics/prefs). Users who already had a first deposit before this feature see the prompt on their next successful deposit until they respond.
- **Rate on Play:** `in_app_review` `requestReview()` when Play can show it; otherwise the same listing URLs as Update. Debug preview always opens the listing (skips the silent in-app API).
- **Not now / dismiss:** permanent local decline; no star picker and no forever nag.

## Packages

- `in_app_update` — availability check only
- `url_launcher` — open listing
- `in_app_review` — native review API
- `shared_preferences` — cooldown / decline / completed flags
