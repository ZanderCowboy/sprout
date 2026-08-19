---
name: Sign-in display name and Terms
overview: Optional display name on email OTP, Google profile name, in-app Terms from Firebase Remote Config with bundled fallback.
todos:
  - id: display-name
    content: Optional display name on email OTP; AuthUser.displayName from user_metadata; Google uses profile name
    status: completed
  - id: terms-rc
    content: Bundled terms.md + Firebase RC string terms_of_service; extend RemoteConfigService string getter; TermsPage with flutter_markdown
    status: completed
  - id: sign-in-terms-link
    content: Terms hyperlink on SignInPage
    status: completed
  - id: tests-docs
    content: Tests + docs; note human action to paste terms into dev Firebase RC
    status: completed
isProject: false
---

# Sign-in display name and Terms

Split from [auth_intro_gate_9422c9f5.plan.md](auth_intro_gate_9422c9f5.plan.md). **Depends on:** [Auth gate and intro](auth_gate_intro.plan.md) (`SignInPage` exists).

Related: [Account details and delete](auth_account_details_delete.plan.md) will reuse `AuthUser.displayName` and `TermsPage`.

## Product rules (locked)

- First launch: custom introduction, then sign-in. Later unsigned launches: sign-in only.
- No guest mode. No creating accounts/goals/transactions until verified.
- After sign-in: pull cloud (empty overview for a new account). **Discard leftover guest Hive** — do not migrate it onto the new uid.
- Same-account re-login: keep local cache, flush pending, pull.
- Different verified account: clear Hive + pending, pull that account.
- Sign-out: session only; return to sign-in. Shell is not reachable while signed out.
- Startup failure: **Retry only** — remove “Continue local-only”.
- Email OTP: optional **display name**. Google: use Google profile name; do not ask again.
- Sign-in requires agreeing to Terms (checkbox or “By continuing you agree…” with a tappable Terms link).
- In-app **delete account** (Play requirement). Wipes this user’s cloud rows (FK cascade), local Hive, then sign-in. *(plan 3)*

## Out of scope

Auth gate, delete account, Settings tile rebuild (except `AuthUser.displayName`, which plan 3 will use). Do not add a Terms row on Account yet unless it is a one-line reuse of `TermsPage`.

## Display name

On [`sign_in_page.dart`](../../sprout_app/lib/features/auth/presentation/sign_in_page.dart): optional display-name field on the email OTP path only.

- After OTP verify: `auth.updateUser` with `user_metadata.display_name` when the field is non-empty.
- Extend [`AuthUser`](../../sprout_app/lib/features/auth/domain/auth_user.dart) with `displayName` from Supabase `user_metadata` (`display_name` / `full_name` / `name`).
- Google: use the Google profile name already in metadata; do not show the name field on that path.
- Add `updateUser` (or equivalent) on [`AuthRepository`](../../sprout_app/lib/features/auth/domain/auth_repository.dart) / impl; keep logic in [`AuthCubit`](../../sprout_app/lib/features/auth/presentation/bloc/auth_cubit.dart) / [`AuthService`](../../sprout_app/lib/features/auth/application/auth_service.dart). Pages stay UI-only.

## Terms of service (Firebase Remote Config)

Not RevenueCat. Remote Config already drives flags.

- Bundled fallback markdown: [`sprout_app/assets/legal/terms.md`](../../sprout_app/assets/legal/terms.md) so first launch / offline still works. Register the asset in [`pubspec.yaml`](../../sprout_app/pubspec.yaml).
- RC string parameter `terms_of_service` (markdown). When Firebase is ready and fetch succeeds, use the remote string; otherwise the asset.
- Extend [`RemoteConfigService`](../../sprout_app/lib/core/flags/remote_config_service.dart) with a **string getter** (today it only has bool flags, and setup is **development-only**). Fetch the terms string whenever Firebase is configured; prod keeps the bundled file until prod Firebase RC is on.
- New `TermsPage`: scrollable markdown via `flutter_markdown` (add the package). Opening Terms **pushes the page**, not an external website.

## Sign-in Terms link

Footer on `SignInPage`: checkbox or “By continuing you agree…” with a tappable Terms hyperlink that pushes `TermsPage`.

## Human action required

1. In the **dev** Firebase Remote Config console, add string parameter `terms_of_service` and paste the Terms markdown. The app ships a bundled placeholder until this is done.

## Files to touch

- [`sign_in_page.dart`](../../sprout_app/lib/features/auth/presentation/sign_in_page.dart) — optional name + Terms link
- [`auth_user.dart`](../../sprout_app/lib/features/auth/domain/auth_user.dart) + repository/impl/mapping
- [`auth_cubit.dart`](../../sprout_app/lib/features/auth/presentation/bloc/auth_cubit.dart) / [`auth_service.dart`](../../sprout_app/lib/features/auth/application/auth_service.dart)
- [`remote_config_service.dart`](../../sprout_app/lib/core/flags/remote_config_service.dart)
- [`sprout_app/assets/legal/terms.md`](../../sprout_app/assets/legal/terms.md) — new
- `terms_page.dart` under auth presentation — new
- [`pubspec.yaml`](../../sprout_app/pubspec.yaml) — `flutter_markdown` + legal asset
- Auth tests + [`docs/SUPABASE_AUTH_TODOS.md`](../../docs/SUPABASE_AUTH_TODOS.md)

## Tests / docs

- Cubit: optional name on OTP verify; skip name when empty; Google does not require a name field.
- `AuthUser.displayName` mapping from metadata keys.
- Terms: bundled fallback when RC missing; remote string when fetch succeeds; SignInPage navigates to TermsPage.
- Docs: locked rules for display name + in-app Terms; note the human RC paste above.
