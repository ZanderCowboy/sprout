---
name: Goals refactor clean-arch
overview: Refactor `sprout_app/lib/features/goals` to separate UI from logic, move enums out of pages, clearly split frontend(domain) vs backend(data) models, consolidate mappers, and rename barrel exports to `export.dart` (Goals only for now).
todos:
  - id: rename-barrel
    content: Rename `features/goals/goals.dart` → `features/goals/export.dart` and update imports.
    status: completed
  - id: extract-enum-and-sorting
    content: Move `GoalsSort` to `presentation/enums`, and sorting/label logic to `presentation/utils`; update `goals_page.dart` to UI-only.
    status: completed
  - id: split-mappers-and-models
    content: Move `GoalHiveModel` into `data/local/models` and split Hive vs Supabase mapping into separate files under `data/mappers`, with an optional `GoalRow` remote DTO.
    status: completed
  - id: move-chart-mapper
    content: Relocate `goal_growth_chart_mapper.dart` to `presentation/utils` and update imports.
    status: completed
  - id: add-cursor-rules
    content: Add `.cursor/rules/*` markdown rules enforcing barrels, enum placement, UI-only pages, and model/mapping separation.
    status: completed
isProject: false
---

## Current issues observed
- `presentation/goals_page.dart` contains non-UI concerns:
  - `enum GoalsSort` declared in the page.
  - Sort labels + deterministic multi-key sorting implemented in the widget state.
- Backend vs frontend concerns are currently mixed in `data/goal_mapper.dart`:
  - Hive mapping (`GoalHiveModel` ↔ `Goal`)
  - Supabase row mapping (`Map<String,dynamic>` ↔ `Goal`)

## Target folder layout (Goals only)
- `[sprout_app/lib/features/goals/export.dart](sprout_app/lib/features/goals/export.dart)`
  - Single barrel for the feature (renamed from `goals.dart`).
- `application/`
  - `goals_service.dart` (kept)
- `domain/` (Frontend models + repo contract)
  - `goal.dart`, `goal_progress.dart`, `goals_repository.dart` (kept)
- `data/`
  - `mappers/`
    - `goal_hive_mapper.dart` (Goal ↔ GoalHiveModel)
    - `goal_supabase_mapper.dart` (Goal ↔ Supabase DTO)
    - Optionally: keep a thin `goal_mapper.dart` that re-exports both for convenience, but mappers live together.
  - `local/models/`
    - `goal_hive_model.dart` (moved from `data/local/`)
  - `remote/models/`
    - `goal_row.dart` (new backend DTO replacing raw `Map` usage)
- `presentation/`
  - `pages/`
    - `goals_page.dart`, `goal_detail_page.dart` (moved/renamed path only if you want; otherwise keep names but ensure they are UI-only)
  - `bloc/`
    - `goals_bloc.dart`, `goal_detail_bloc.dart` (logic stays here; pages just dispatch and render)
  - `widgets/`
    - `unallocated_funds_card.dart`, etc.
  - `enums/`
    - `goals_sort.dart` (moves `GoalsSort` out of the page)
  - `utils/`
    - `goals_sorting.dart` (pure functions: label + comparator/sorter)
    - `goal_growth_chart.dart` (move `goal_growth_chart_mapper.dart` here; still presentation-layer because it depends on `fl_chart`)

## Concrete refactor steps
1. **Rename barrel**
   - Rename `features/goals/goals.dart` → `features/goals/export.dart`.
   - Update imports across the app that reference `package:sprout/features/goals/goals.dart` (or `features/goals/goals.dart`) to use `.../features/goals/export.dart`.
   - Keep the barrel exporting the same public surface initially (service, repo impl, models, blocs, pages) to avoid churn.

2. **Move enums out of pages**
   - Create `presentation/enums/goals_sort.dart` and move `GoalsSort` there.
   - Ensure no `enum` declarations live in `presentation/pages/*.dart`.

3. **Move sorting/label logic out of `GoalsPage`**
   - Create `presentation/utils/goals_sorting.dart`:
     - `String goalsSortLabel(GoalsSort)`
     - `List<GoalProgress> sortGoals(List<GoalProgress> input, GoalsSort sort)`
   - In `GoalsPage`, keep only UI state (`GoalsSort _sort`) and call the helper.
   - (Optional) If you want *zero* non-UI logic in pages, also move the “completed goals go to bottom” rule into the helper (recommended).

4. **Split backend models and mappers**
   - Move `data/local/goal_hive_model.dart` → `data/local/models/goal_hive_model.dart`.
   - Split `data/goal_mapper.dart` into:
     - `data/mappers/goal_hive_mapper.dart` with `goalFromHive/goalToHive`
     - `data/mappers/goal_supabase_mapper.dart` with `goalFromSupabaseRow/goalToSupabaseRow`
   - Introduce `data/remote/models/goal_row.dart` (backend DTO) and have the Supabase mapper convert `GoalRow` ↔ `Goal`, with repository translating the raw Supabase map to `GoalRow`.
   - Update `data/goals_repository_impl.dart` imports accordingly.

5. **Tidy presentation logic helpers**
   - Rename `presentation/goal_growth_chart_mapper.dart` → `presentation/utils/goal_growth_chart.dart` (or similar) since it’s non-UI logic used by bloc/page.
   - Keep it in `presentation/utils` because it depends on chart types (`FlSpot`) and is view-oriented.

6. **Guard clean-arch boundaries (lightweight)**
   - Ensure `presentation/**` does not import `data/local/**` or `data/remote/**`.
   - Ensure repository impls stay in `data/**` and pages never reach into `GoalsRepositoryImpl`.

## Cursor rules to prevent regressions
Add a small set of rules under `[.cursor/rules/](.cursor/rules/)` (Goals-focused but generally reusable):
- **Barrel naming**: “Feature barrels must be named `export.dart`.”
- **Pages are UI-only**: “Files under `presentation/pages/` must not define enums, top-level helper functions, or sorting/business logic; extract to `presentation/utils` or bloc.”
- **Enums location**: “Feature enums live under `<feature>/presentation/enums` (if UI-specific) or `<feature>/domain/enums` (if domain-wide).”
- **Backend vs frontend models**: “Frontend entities in `domain/`; backend/storage/DTO models in `data/**/models`; mappers in `data/mappers`.”
- **Dependency direction**: “`presentation` may depend on `domain` and `application`, but not on `data/local`/`data/remote` models.”

## Notes / low-risk improvements surfaced
- `GoalsBloc` and `GoalDetailBloc` currently do aggregation/sorting logic; that’s acceptable for clean-ish architecture (presentation layer). The key is keeping pages free of that kind of logic, which this plan enforces.
