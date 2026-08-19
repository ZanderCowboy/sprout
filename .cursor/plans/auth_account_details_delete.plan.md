---
name: Account details and delete
overview: Settings Account tile shows signed-in identity. Account page becomes details (avatar, name, email, sign out, Terms, delete). In-app account deletion via Supabase RPC.
todos:
  - id: settings-tile
    content: Settings Account tile shows avatar/name/email not Sign in text
    status: completed
  - id: account-page
    content: Rebuild AccountPage as details UI (avatar, editable display name, email, sign out, Terms, delete)
    status: completed
  - id: account-delete
    content: Confirm flow; private SQL delete_own_account; clear Hive + RevenueCat logOut; return to sign-in
    status: completed
  - id: tests-docs
    content: Tests + docs; note human action to apply migration on dev Supabase
    status: completed
isProject: false
---

# Account details and delete

Split from [auth_intro_gate_9422c9f5.plan.md](auth_intro_gate_9422c9f5.plan.md). **Depends on:** [Auth gate and intro](auth_gate_intro.plan.md) (signed-in Shell + sign-out returns to gate).

[Sign-in display name and Terms](auth_signin_name_terms.plan.md) is **nice-to-have**: tile/details can fall back to email if `displayName` is missing; Terms row on Account can wait if `TermsPage` is not landed yet.

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
- In-app **delete account** (Play requirement). Wipes this user’s cloud rows (FK cascade), local Hive, then sign-in.

## Out of scope

Auth gate, intro, SignInPage OTP/Google extract, bind/migrate, Continue local-only.

## Settings tile

Today the Settings Account row always says “Sign in with email or Google” even when signed in ([`settings_page.dart`](../../sprout_app/lib/features/settings/presentation/settings_page.dart) ~93–105).

Listen to [`AuthService`](../../sprout_app/lib/features/auth/application/auth_service.dart):

- Leading: circle avatar with initial from display name or email
- Title: display name, else email, else “Account”
- Subtitle: email when a name is shown, otherwise “Signed in with Google” / “Signed in with email”
- Still opens Account details

## Account details

Replace the current signed-in [`AccountPage`](../../sprout_app/lib/features/auth/presentation/account_page.dart) list:

- Large avatar + display name + email
- Optional edit display name (saves `user_metadata`)
- Sign out
- Terms of service (push `TermsPage` if plan 2 landed)
- Delete account (destructive, at the bottom)

Keep the page UI-only; logic stays in `AuthCubit` / `AuthService`.

## Delete account

Confirm sheet: short warning that savings data is removed permanently; primary action **Delete account**.

Cannot call Auth Admin from the anon key. Add a migration under [`supabase/migrations/`](../../supabase/migrations/):

- `private.delete_own_account()` `SECURITY DEFINER` deletes `auth.users` where `id = auth.uid()`
- Thin `public.delete_own_account()` **invoker** wrapper for `supabase.rpc`
- Existing tables already `references auth.users (id) on delete cascade` ([`20260412120000_init.sql`](../../supabase/migrations/20260412120000_init.sql), [`20260415120000_budget_groups.sql`](../../supabase/migrations/20260415120000_budget_groups.sql))

App flow: RPC → clear Hive entity boxes + pending (keep `intro_completed`) → `Purchases.logOut()` if configured → sign out → auth gate shows sign-in.

Subscriptions: deletion does **not** refund or cancel Play billing. Copy should say they can manage/cancel Premium separately if subscribed.

## Human action required

1. Apply the delete-account migration on the **dev** Supabase project (`supabase db push` or SQL editor) if the agent cannot.

## Files to touch

- [`settings_page.dart`](../../sprout_app/lib/features/settings/presentation/settings_page.dart)
- [`account_page.dart`](../../sprout_app/lib/features/auth/presentation/account_page.dart)
- [`auth_cubit.dart`](../../sprout_app/lib/features/auth/presentation/bloc/auth_cubit.dart) / [`auth_service.dart`](../../sprout_app/lib/features/auth/application/auth_service.dart) / repository
- New migration in [`supabase/migrations/`](../../supabase/migrations/)
- [`auth_service_test.dart`](../../sprout_app/test/auth/auth_service_test.dart) / cubit tests
- [`docs/SUPABASE_AUTH_TODOS.md`](../../docs/SUPABASE_AUTH_TODOS.md) — delete-account RPC + human apply-on-dev note

## Tests / docs

- Settings tile: signed-in identity, not “Sign in…”.
- Account: sign out still returns to gate (plan 1); edit name when plan 2 metadata exists.
- Delete-account: confirm → RPC → local Hive cleared → session gone; sign-out-without-delete still keeps rows.
- Docs: locked delete-account rule + migration/human step; Premium/Play billing is separate.

## Device check

1. Settings Account tile shows name/email, not “Sign in…”.
2. Account page: avatar, name, email, sign out, Terms (if plan 2), delete.
3. Sign out → sign-in, not empty overview.
4. Delete account → confirm → back on sign-in; that Google/email has no old cloud data.
5. If subscribed: copy mentions managing Premium / Play billing separately.
