# Agent instructions (Sprout)

## AI-only development

The human does not touch code. All code written or changed must be done by an AI agent.

- **Agent**: implement, edit, test, commit/PR (when asked), fix CI.
- **Human**: decide product intent, approve plans, verify on device, provide secrets/logins the agent cannot access.

Never instruct the human to edit source files or apply patches. If something requires a human (e.g. App Store login, paste an API key into a dashboard), state that single action clearly and keep doing all agent-capable work.

## Project notes

- Flutter app lives under `sprout_app/` (package `sprout`).
- Agent knowledge: [`.cursor/references/`](.cursor/references/README.md) (architecture, tooling, testing, sync, secrets).
- Feature architecture: `.cursor/rules/clean-architecture.mdc`.
- Prefer existing `sprout_app/test/mocks/mocks.dart` (hand-written fakes, not mockito).
- No Melos/`build_runner` today — Hive adapters are checked in at `hive_adapters.dart`. If codegen is added later, run it via Melos.
- GitHub CLI must use personal account `ZanderCowboy`, not work `Zander-K`. Before any `gh` command: `export GH_CONFIG_DIR=$HOME/.config/gh-zandercowboy`.
- Firebase CLI must use the personal Google account, not work. Before any `firebase` command: `export XDG_CONFIG_HOME=$HOME/.config/firebase-personal`.
- After Dart changes: `cd sprout_app && flutter analyze && flutter test`. If tests fail or hang, finish the work and report — do not loop on them until the human asks.
- RevenueCat: plugin MCP + `docs/REVENUECAT.md`. Supabase: MCP + `supabase/README.md`. Maestro: project MCP (`maestro mcp`) + `.maestro/` flows.
