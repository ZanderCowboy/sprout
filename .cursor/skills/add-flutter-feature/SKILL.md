---
name: add-flutter-feature
description: >-
  Scaffolds or extends a Sprout Flutter feature using clean architecture,
  export.dart barrels, GetIt registration, Hive adapters, and tests. Use when
  adding a new feature under sprout_app/lib/features, a new repository/service/bloc,
  or wiring a new persisted entity.
---

# Add a Flutter feature

Read `.cursor/references/architecture.md` first. Follow existing features (`goals`, `budget`) instead of inventing a new layout.

## Checklist

1. **Product intent** — only ask if UX/scope is unclear. Then implement fully.
2. **Create** `sprout_app/lib/features/<name>/` with `domain/`, `application/`, `data/`, `presentation/`, and `export.dart`.
3. **Domain** — entity + repository interface. Money in cents. No Flutter imports. Pure rules go in **domain helper classes** (e.g. `FundsCalculator`), not repository/service methods.
4. **Application** — `abstract class *Service` (docstrings) + `*ServiceImpl`. Validation via `ValidationAppException` + `AppStrings`. Use-cases orchestrate; call domain helpers for math.
5. **Data** — Hive model, mapper, `RepositoryImpl` (write Hive first; enqueue sync if `canSync`). See `.cursor/references/offline-sync.md`.
6. **Hive** — new `TypeAdapter` in `hive_adapters.dart` (next `typeId`), box name in `HiveBoxes`, open the box in startup/DI.
7. **Presentation** — UI-only page (one public widget per file); logic in bloc/cubit with `*_event.dart` / `*_state.dart` part files; extra widgets in `presentation/widgets/`. Helpers in `presentation/utils/`. All user-visible copy (including Semantics `label`, tooltips, dialogs, snackbars, enum display labels) goes in `AppStrings` — add/reuse constants first; do not hard-code English in widgets.
8. **DI** — register abstract services and repository interfaces in `configureDependencies` (`service_locator.dart`). Import `*_service_impl.dart` in DI only, not via barrels.
9. **Barrel** — `export.dart` = domain + application + presentation only. No Hive/Supabase re-exports.
10. **Shared UI** — reuse `lib/ui` if the widget pattern exists in 2+ features.
11. **Tests** — fake in `test/mocks/mocks.dart` if needed; add service/domain tests (no `testWidgets` unless asked). Then follow the `sprout-verify` skill.

Do not import `data/**/models` from presentation. Do not ask the human to create files.
