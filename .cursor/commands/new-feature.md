# New feature (AI-only)

Scaffold or extend a Sprout Flutter feature. The human does not edit code.

Feature / context after `/new-feature`:

$ARGUMENTS

## Do this

1. Follow the `add-flutter-feature` skill and `.cursor/references/architecture.md`.
2. Clarify only product/UX if something material is ambiguous — otherwise implement.
3. Wire domain → service → Hive/repository → bloc → UI → `export.dart` → `service_locator.dart`.
4. Add or extend tests via `sprout_app/test/mocks/mocks.dart`.
5. Run `flutter analyze` and `flutter test` in `sprout_app`.
6. Reply with what changed, device QA steps, and any single human-only blocker. No "please edit this file".
