# Play soft prompts (#104 / #105)

Android-only soft prompts. iOS is out of scope.

## Update prompt (#104)

- **Trigger:** cold start and app resume (`AppLifecycleState.resumed`) via `PlayPromptsHost`.
- **Gate:** `InAppUpdate.checkForUpdate()` reports `updateAvailable`, and the sheet has not been shown yet **today** (local calendar day in prefs).
- **Update:** opens the Play Store listing for `AppConfig.androidApplicationId`:
  - `market://details?id=<applicationId>`
  - fallback `https://play.google.com/store/apps/details?id=<applicationId>`
  - Does **not** start flexible or immediate in-app update flows.
- **Later / dismiss:** closes the sheet; non-blocking.

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
