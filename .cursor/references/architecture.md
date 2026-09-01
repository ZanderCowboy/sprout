# Feature architecture

App code lives in `sprout_app/lib`. Features use clean architecture.

## Layout

```
sprout_app/lib/features/<feature>/
  export.dart                 # barrel; name must be export.dart
  domain/                     # entities, repository interfaces, domain enums
  application/                # abstract *Service + *ServiceImpl
    <feature>_service.dart      # abstract class with API docstrings
    <feature>_service_impl.dart
  data/
    <feature>_repository_impl.dart
    local/models/             # Hive DTOs
    remote/models/            # Supabase row DTOs
    mappers/                  # hive + supabase mappers (no mapping in UI)
  presentation/
    *_page.dart / *_screen.dart   # UI only — one public widget per file
    *_bloc.dart / bloc/           # bloc/cubit class only
    *_event.dart / *_state.dart   # part files for bloc/cubit (part of parent)
    widgets/                      # extra widgets extracted from pages
```

Shared, non-feature code:

- `lib/core/` — config, DI (`sl`), errors, Hive adapters, theme, user id
- `lib/ui/` — dumb reusable widgets (inputs + callbacks only; no `sl<>`)

## Canonical examples

- Layers + barrel: `sprout_app/lib/features/goals/`
- Split hive/supabase mappers: `sprout_app/lib/features/budget/data/mappers/`
- DI registration: `sprout_app/lib/core/di/service_locator.dart`
- Shared widget: `sprout_app/lib/ui/widgets/colored_entity_card.dart`

## Dependency direction

```
presentation → application + domain
application → domain
data → domain
presentation must not import data/local, data/remote, or DTO models
lib/ui must not import features
```

Cross-feature imports go through `package:sprout/features/<other>/export.dart`. Same-feature files may use relative imports.

## Conventions

- Money is **integer cents**, not `double` currency.
- User-facing copy lives in `AppStrings`.
- Validation throws `ValidationAppException` (see `lib/core/error/app_exception.dart`).
- Register new repositories/services in `configureDependencies`.
- **Services:** `abstract class FooService` in `foo_service.dart` (class + public method docstrings); `FooServiceImpl` in `foo_service_impl.dart`. DI registers `FooService` → `FooServiceImpl`. Barrels export the abstract only.
- **Blocs/cubits:** events and states in sibling `*_event.dart` / `*_state.dart` files using `part of` the parent `*_bloc.dart` or `*_cubit.dart`.
- **Presentation:** one public widget class per `*_page.dart` / `*_screen.dart`; extract additional widgets to `presentation/widgets/` as public classes.
- Pages must not contain enums, sort helpers, or business rules.
