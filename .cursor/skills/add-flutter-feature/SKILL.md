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
3. **Domain** — entity + repository interface. Money in cents. No Flutter imports.
4. **Application** — `*Service` with validation via `ValidationAppException` + `AppStrings`.
5. **Data** — Hive model, mapper, `RepositoryImpl` (write Hive first; enqueue sync if `canSync`). See `.cursor/references/offline-sync.md`.
6. **Hive** — new `TypeAdapter` in `hive_adapters.dart` (next `typeId`), box name in `HiveBoxes`, open the box in startup/DI.
7. **Presentation** — UI-only page; logic in bloc/cubit; helpers in `presentation/utils/`.
8. **DI** — register in `configureDependencies` (`service_locator.dart`). Provide blocs where `SproutApp` / the feature route already does.
9. **Shared UI** — reuse `lib/ui` if the widget pattern exists in 2+ features.
10. **Tests** — fake in `test/mocks/mocks.dart` if needed; add service/bloc tests. Then follow the `sprout-verify` skill.

Do not import `data/**/models` from presentation. Do not ask the human to create files.
