# Agent instructions (Sprout)

## AI-only development

The human does not touch code. All code written or changed must be done by an AI agent.

- **Agent**: implement, edit, test, commit/PR (when asked), fix CI.
- **Human**: decide product intent, approve plans, verify on device, provide secrets/logins the agent cannot access.

Never instruct the human to edit source files or apply patches. If something requires a human (e.g. App Store login, paste an API key into a dashboard), state that single action clearly and keep doing all agent-capable work.

## Project notes

- Flutter app lives under `sprout_app/`.
- Use Melos for `build_runner` and monorepo scripts.
- Feature architecture: see `.cursor/rules/clean-architecture.md`.
- Prefer existing `mocks.dart` when writing tests that need mocks.
