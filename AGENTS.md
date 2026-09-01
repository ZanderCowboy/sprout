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
- gcloud must use the personal Google account and `sprout-app-development`, not work. Before any `gcloud` command: `export CLOUDSDK_CONFIG=$HOME/.config/gcloud-personal`.
- After Dart changes: `cd sprout_app && flutter analyze && flutter test`. If tests fail or hang, finish the work and report — do not loop on them until the human asks.
- RevenueCat: plugin MCP + `docs/REVENUECAT.md`. Supabase: MCP + `supabase/README.md`.

## Cursor Cloud specific instructions

In Cloud Agents the dev loop is `flutter analyze` + `flutter test` only. Verifying the running app on a device/emulator is human-owned and cannot be done in the Cloud Agent VM — do not burn tokens trying.

- **Do not launch an Android emulator.** Nested virtualization does not work here: the guest vCPU stays halted (~0% CPU, `adb` stuck `offline`) even though `/dev/kvm` exists and `emulator -accel-check` says KVM is usable. Don't install the emulator/system images or retry boots.
- **Do not build for Android/web/desktop to "run" the app.** Android builds need the gitignored `google-services.json` (Firebase secret) the agent doesn't have; web fails to compile (`firebase_core_web` vs this Dart SDK) and `purchases_ui_flutter` is mobile-only; there are no committed `web/`/`linux/` targets.
- To exercise real UI logic headlessly, rely on the widget tests in `flutter test` (e.g. `widget_test.dart`, `auth/sign_in_page_test.dart`, `auth/auth_gate_test.dart`).
- The environment already provides Flutter 3.38.10 / Dart 3.10.9 and the Android SDK; `scripts/cloud-agent-install.sh` writes local-only flavor config placeholders (empty Supabase/Firebase/RevenueCat → offline Hive) and runs `flutter pub get`. Real credentials stay human-owned.
