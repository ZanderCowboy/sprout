---
name: go_router navigation
overview: Adopt go_router now as the app router (no codegen). It fits the existing shell/auth gate and is the right foundation for later magic-link and in-app deep links. Do not add OS intent-filters or App Links in this pass.
todos:
  - id: add-go-router
    content: Add go_router; AppRoute enum + app_router.dart with StatefulShellRoute.indexedStack, auth redirect + refreshListenable
    status: completed
  - id: wire-material-app-router
    content: Switch SproutApp to MaterialApp.router; keep bootstrap MaterialApp; signed-in blocs above the router
    status: completed
  - id: replace-navigator-push
    content: Replace Navigator.push / setTabIndex with AppRoute go/push/goBranch; keep modal sheets
    status: completed
  - id: tests-docs
    content: Redirect tests; update AuthGate tests; note deferred OS/magic-link deep links in SUPABASE_AUTH_TODOS.md
    status: completed
isProject: false
---

# Adopt go_router (deep links later)

## Recommendation

**Use [go_router](https://pub.dev/packages/go_router)** (`go_router: ^17.5.0`). It is the Flutter team’s declarative router, needs **no codegen** (fits this repo: no Melos/`build_runner`), and is built for URL-based navigation + deep linking.

Do **not** use:

- **auto_route** — requires `build_runner`; this project explicitly avoids codegen today.
- **beamer / qlevar_router** — extra surface, not official, weaker deep-link story.
- **app_links / uni_links alone** — they only deliver the OS URI; you still have to map it onto `Navigator.push`. Fine as a *platform* helper later; not a router.
- **Stay on Navigator 1.0** — works until the first real deep link. Auth gate + `IndexedStack` tabs + stacked details (`/accounts/:id`) become a manual URI parser. That cost hits when magic links land.

Keep **bottom sheets** (`AccountFormSheet`, `CreateGoalScreen`, `DepositBottomSheet`) as `showModalBottomSheet`. They are not destinations.

Startup stays as it is: [`SproutBootstrapApp`](sprout_app/lib/features/startup/startup_flow.dart) keeps its own `MaterialApp` until init finishes, then hands off to [`SproutApp`](sprout_app/lib/app.dart). Only the post-startup app becomes `MaterialApp.router`.

## Why this matches Sprout

Today:

- [`MaterialApp(home: AuthGate(signedIn: ShellPage()))`](sprout_app/lib/app.dart) — widget swap, not routes.
- [`ShellPage`](sprout_app/lib/features/shell/presentation/shell_page.dart) — `IndexedStack` + custom 4-tab bar + center `+`.
- Stack screens via `Navigator.push` (account/goal detail, Settings children, transactions).
- No Android intent-filters beyond `MAIN`/`LAUNCHER`. Magic-link deep links are [deferred](docs/SUPABASE_AUTH_TODOS.md).

go_router maps 1:1:

| Today | go_router |
| --- | --- |
| `AuthGate` widget swap | `redirect` + `refreshListenable` on `AuthCubit.stream` |
| `IndexedStack` tabs | `StatefulShellRoute.indexedStack` (same tab state) |
| Custom bottom bar + `+` | Keep the existing bar; drive it with `StatefulNavigationShell` (`goBranch`) |
| `Navigator.push` details | `context.go` / `context.push` to path routes |
| Later OS URLs | Same paths; add platform config then |

```mermaid
flowchart TD
  Boot[SproutBootstrapApp MaterialApp] --> Ready{Init ready?}
  Ready -->|no| Startup[Startup / Retry]
  Ready -->|yes| Router[SproutApp MaterialApp.router]
  Router --> Redirect{go_router redirect}
  Redirect -->|loading| Loading[/loading]
  Redirect -->|guest no intro| Intro[/intro]
  Redirect -->|guest intro done| SignIn[/sign-in]
  Redirect -->|verified| Shell[StatefulShell indexedStack]
  Shell --> Overview[/overview]
  Shell --> Accounts[/accounts]
  Shell --> Goals[/goals]
  Shell --> Settings[/settings]
  Settings --> Account[/settings/account]
  Settings --> Tx[/settings/transactions]
  Accounts --> AccDetail["/accounts/:id full screen"]
```

## Route map (this migration)

Put the router in [`sprout_app/lib/core/router/app_router.dart`](sprout_app/lib/core/router/app_router.dart) (app-wide, not a feature). Paths live in a hand-written **`AppRoute` enum** in [`sprout_app/lib/core/router/app_route.dart`](sprout_app/lib/core/router/app_route.dart) — no `go_router_builder` (that needs codegen).

Pages never hard-code path strings. They call `context.go(AppRoute.overview.path)` / `context.push(AppRoute.accountDetail.location(id))`. Redirect compares `state.matchedLocation` against `AppRoute.*.path`. `GoRoute(path: AppRoute.accounts.path, …)` is the single source of truth.

```dart
enum AppRoute {
  loading('/loading'),
  intro('/intro'),
  signIn('/sign-in'),
  overview('/overview'),
  accounts('/accounts'),
  accountDetail('/accounts/:id'),
  goals('/goals'),
  goalDetail('/goals/:id'),
  settings('/settings'),
  account('/settings/account'),
  transactions('/settings/transactions'),
  transactionDetail('/settings/transactions/:id'),
  recurring('/settings/recurring'),
  budget('/settings/budget');

  const AppRoute(this.path);
  final String path;

  /// Concrete URL for param routes (`:id` → value).
  String location({String? id}) {
    if (path.contains(':id')) {
      if (id == null || id.isEmpty) {
        throw ArgumentError('id required for $name');
      }
      return path.replaceFirst(':id', id);
    }
    return path;
  }
}
```

**Unsigned** — `loading`, `intro`, `signIn`

**Signed-in shell** (`StatefulShellRoute.indexedStack`) — `overview`, `accounts`, `goals`, `settings`

**Full-screen** (sibling of shell, bottom bar hides — same as current `MaterialPageRoute`) — `accountDetail`, `goalDetail`, `account`, `transactions`, `transactionDetail`, `recurring`, `budget`

Redirect rules (same product rules as AuthGate):

- Guest + intro not completed → `AppRoute.intro`
- Guest + intro done → `AppRoute.signIn`
- Verified hitting intro or sign-in → `AppRoute.overview`
- Guest hitting any shell/detail path → `AppRoute.signIn` (this is what makes later deep links safe)

`refreshListenable`: a small `GoRouterRefreshStream(authCubit.stream)` (AuthCubit is not a `ChangeNotifier`). Recreate `GoRouter` only when needed; do **not** rebuild it on every `BlocBuilder` tick the way `MaterialApp` is keyed today (`ValueKey(signed-in/out)`).

Keep signed-in `HomeBloc` / `GoalsBloc` providers above the router (only when verified), as in [`app.dart`](sprout_app/lib/app.dart) today.

Replace `ShellPage.maybeOf(context)?.setTabIndex(2)` in overview with `navigationShell.goBranch(2)` (or `context.go(AppRoute.goals.path)`).

Goals AppBar currently **pushes** another `SettingsPage` on the stack; that becomes `context.go(AppRoute.settings.path)` (switch tab) so there are not two Settings routes.

## Deep linking — design now, implement later

Two different link types. Do **not** add either in this pass.

**1. In-app / https content links** (accounts, goals, transactions)

- Paths above *are* the deep-link URLs.
- Later: Android `intent-filter` (`https` App Links and/or custom scheme), Digital Asset Links for **both** flavor ids (`app.stackmint.sprout.dev` and `app.stackmint.sprout`), iOS associated domains when iOS exists.
- go_router consumes these via Flutter’s default deep-link pipeline — **no extra Dart package required** for routing.
- Unsigned users who open `sprout://accounts/xyz` hit redirect → `/sign-in`, then after OTP/Google go to the original `redirect` location (`GoRouterState.uri`). That is why the router should land **before** magic links.

**2. Auth magic link / OAuth callback** (deferred in [SUPABASE_AUTH_TODOS.md](docs/SUPABASE_AUTH_TODOS.md))

- `supabase_flutter` already listens for auth callback URIs (via `app_links` internally).
- Use a **distinct** callback path (e.g. `/auth/callback` or Supabase’s default scheme) that go_router **does not** treat as an app screen.
- Do not reuse `/sign-in` or `/overview` as the Supabase redirect URL.
- Later work: Additional Redirect URLs in Supabase, Android intent-filter for that callback only, then magic link. OTP stays as-is (no link).

Out of scope now: intent-filters, `assetlinks.json`, custom URL scheme, magic link, `app_links` as a direct dependency.

## Tests / docs

- Router redirect: unsigned cannot open `/overview`; signed-in skips intro; intro flag still respected.
- Keep existing IntroPage widget tests (they wrap `MaterialApp` + `IntroPage` directly).
- AuthGate either becomes a thin wrapper around redirect or is deleted once redirect covers it; update [`auth_gate_test.dart`](sprout_app/test/auth/auth_gate_test.dart) accordingly.
- Note in [docs/SUPABASE_AUTH_TODOS.md](docs/SUPABASE_AUTH_TODOS.md) that in-app paths are go_router-ready; OS/magic-link config still deferred.
- After Dart changes: `cd sprout_app && flutter analyze && flutter test` (do not loop on failures).

## Device check

1. Intro → sign-in → overview; tabs still preserve state.
2. Account/goal detail still covers the bottom bar (back returns to the tab).
3. Settings children still push/pop as today.
4. Sign-out returns to sign-in, not an empty shell.
5. No change to OTP/Google; no new OS “Open with Sprout” prompts (no intent-filters yet).
