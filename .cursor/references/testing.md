# Testing

Tests live in `sprout_app/test/`. Prefer extending `sprout_app/test/mocks/mocks.dart` (hand-written fakes). Do **not** add mockito/`build_runner` unless the human explicitly asks.

## Patterns

- Import fakes from `../mocks/mocks.dart` (see `test/auth/auth_cubit_test.dart`).
- Add a new fake in `mocks.dart` when a domain interface needs test doubles.
- Hive: `Hive.init(tempDir)` + `registerHiveAdapters()` in `setUpAll`; unique box names per test in `setUp`.
- Use `AppConfig` constructors in tests — do not load flavor JSON assets.
- Cover services and blocs. **Avoid widget tests by default** — they are slow and often hang (native plugins such as Purchases, repeating progress indicators, `pumpAndSettle`). Write `testWidgets` only when the human asks and the tree is small and plugin-free. If unsure, skip the widget test and rely on service/cubit coverage.

## After test code changes

```bash
cd sprout_app && flutter test
```

If you touched Dart outside tests, also run `flutter analyze`.
