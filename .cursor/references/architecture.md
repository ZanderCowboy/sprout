# Feature architecture

App code lives in `sprout_app/lib`. Features use clean architecture.

## Layout

```
sprout_app/lib/features/<feature>/
  export.dart                 # barrel: domain + application + presentation only
  domain/                     # entities, repository interfaces, pure helper classes
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
    enums/                    # UI-only enums
    utils/                    # sorting, labels, chart helpers (presentation-only)
```

Shared, non-feature code:

- `lib/core/` — config, DI (`sl`), errors, Hive adapters, theme, user id, shared utils (`UniqueName`)
- `lib/ui/` — dumb reusable widgets (inputs + callbacks only; no `sl<>`)

## Frontend vs on-device logic

There is no separate backend app. Supabase is the remote backend. Inside Flutter:

| Layer | Role |
|-------|------|
| **Presentation** (`presentation/`, `lib/ui/`) | Layout, navigation, forms, loading/error. Blocs map service results to UI state. |
| **Application** (`application/`) | Use-cases: `recordDeposit`, `createGoalWithOpeningBalance`, `watchFundsSnapshot`. Orchestrates; does not contain math. |
| **Domain** (`domain/`) | Entities + **pure helper classes** (`FundsCalculator`, `TransactionRules`, `RecurringSchedule`, `BudgetTotals`). No Flutter, no Hive/Supabase. |
| **Data** (`data/`) | Hive/Supabase I/O and mapping only. May call domain helpers for policy before persist. |

**Hard rules:**

- Pages/sheets/widgets do not compute money, split scheduled/history, or orchestrate multi-entity writes.
- Blocs do not contain financial policy — subscribe to services and map to UI state.
- Pure logic (inputs → outputs, no I/O) lives in **domain helper classes**, not buried in repositories, services, or widgets.
- Money stays **integer cents** through domain and application. Format only at the widget edge (`formatZarFromCents`).

## Barrel exports

- Feature barrel files must be named `export.dart`.
- **`export.dart` re-exports domain, application, and presentation only** — not Hive models, mappers, or Supabase DTOs.
- `core/di/service_locator.dart`, `core/startup/startup_initializer.dart`, and `core/storage/hive_adapters.dart` import `data/` paths directly.
- Cross-feature imports use `package:sprout/features/<other>/export.dart`.

## Canonical examples

- Layers + barrel: `sprout_app/lib/features/goals/`
- Domain helpers: `sprout_app/lib/features/transactions/domain/funds_calculator.dart`
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
