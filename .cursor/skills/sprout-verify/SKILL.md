---
name: sprout-verify
description: >-
  Runs Sprout Flutter verification (analyze and test from sprout_app) after
  code changes. Use when finishing a feature or fix, before a PR, or when the
  user asks to check, analyze, or test the app.
---

# Verify Sprout

From the workspace root, run checks **yourself** (never ask the human to run them):

```bash
cd sprout_app
flutter analyze
flutter test
```

Equivalent: `make check` from the repo root.

## Rules

- Fix analyzer issues and failing tests you introduced before handing back.
- Hive adapters are not generated; a typeId/read-order mistake will fail at runtime — re-read `.cursor/references/offline-sync.md` if you changed persistence.
- Report what you ran and what still needs **device** QA (`/human-qa` style: tap steps only).
- **Maestro:** if you changed Dart/UI/semantics and will run `.maestro/` flows, rebuild and reinstall the development flavor first — see `.cursor/rules/maestro.mdc` (Rebuild before run).
- Flavor JSON is gitignored; missing local config is a human file-create, not a test failure. Tests construct `AppConfig` in memory.
