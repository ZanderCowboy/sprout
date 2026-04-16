---
name: master-budget-planner
overview: Add an offline-first Master Budget Planner feature (Hive + Supabase via PendingSync) with Clean Architecture layers, a BudgetBloc that computes per-group totals plus overall disposable income, and a premium tabbed UI reachable from Settings.
todos:
  - id: budget-domain
    content: "Add Budget domain: `BudgetCategory`, `BudgetItem`, `BudgetGroup`, and `BudgetRepository` interface under `sprout_app/lib/features/budget/domain/`."
    status: completed
  - id: budget-data-hive
    content: Add Hive local model + mapper + Hive adapter registration and new `HiveBoxes.budgetGroups`; open box in startup and register in DI.
    status: completed
  - id: budget-data-supabase
    content: Add Supabase row DTO + mapper; extend `SupabaseTables` with `budget_groups`.
    status: completed
  - id: budget-sync
    content: Extend PendingSync ops/payloads + update `SyncService` to upsert/delete `budget_groups` rows.
    status: completed
  - id: budget-repo-service
    content: Implement `BudgetRepositoryImpl` + `BudgetService` with validation and stream-based watch.
    status: completed
  - id: budget-bloc-calcs
    content: Implement `BudgetBloc/Event/State` including per-group totals and disposable income calculation; wire CRUD events to service.
    status: completed
  - id: budget-ui
    content: Implement `BudgetPlannerScreen` with header + TabBar/TabBarView + `GroupCard` expansion list; add Settings navigation entry.
    status: completed
  - id: budget-add-group-sheet
    content: Implement `AddGroupSheet` bottom sheet with name/description/category/color/icon pickers; hook into bloc.
    status: completed
isProject: false
---

## Goal
Implement a new feature, **Master Budget**, that stores a static monthly template (independent of Accounts/Goals/Transactions) with CRUD for `BudgetGroup`s containing nested `BudgetItem`s, synced offline-first to Supabase.

## Key architectural decisions (locked)
- **Offline-first sync**: write-through to Hive; enqueue PendingSync ops; `SyncService` flushes to Supabase.
- **Icon storage**: store both `codePoint` (int) and `fontFamily` (string) so icons can expand beyond Material later.
- **Isolation**: separate Hive box(es) + separate Supabase table(s); no coupling to existing Transactions/Goals domains.
- **Nested items persistence**: store `BudgetGroup.items` as JSON (in Hive and Supabase) to keep sync ops minimal (only upsert/delete group), while still exposing nested item CRUD via repository/service.

## Data model + storage shape
- **Domain** (new folder):
  - `BudgetCategory { income, essentials, lifestyle }`
  - `BudgetItem { id, name, amount }`
  - `BudgetGroup { id, name, description?, colorHex, iconCodePoint, iconFontFamily, category, items }`
- **Hive**:
  - Add `HiveBoxes.budgetGroups`.
  - Create `BudgetGroupHiveModel` with:
    - `id`, `userId`, `name`, `description?`, `colorHex`, `iconCodePoint`, `iconFontFamily`, `categoryIndex`, `itemsJson`, `createdAtMillis`, `updatedAtMillis`.
  - Add a `TypeAdapter<BudgetGroupHiveModel>` in `[sprout_app/lib/core/storage/hive_adapters.dart](sprout_app/lib/core/storage/hive_adapters.dart)` with a new `typeId` (next available after 3).

- **Supabase**:
  - Extend `SupabaseTables` in `[sprout_app/lib/features/transactions/data/supabase_tables.dart](sprout_app/lib/features/transactions/data/supabase_tables.dart)` with `static const budgetGroups = 'budget_groups';`.
  - Create a DTO row model similar to `GoalRow`:
    - `[sprout_app/lib/features/budget/data/remote/models/budget_group_row.dart](sprout_app/lib/features/budget/data/remote/models/budget_group_row.dart)` with `fromMap/toMap`.
  - Store nested items in a `items_json` text/json column.

## Clean Architecture layering (new feature)
Create `[sprout_app/lib/features/budget/](sprout_app/lib/features/budget/)` mirroring Goals structure:
- **domain**
  - models + `BudgetRepository` interface.
- **data**
  - local hive model + mapper, remote row + mapper, repository impl.
- **application**
  - `BudgetService` for validation + orchestration.
- **presentation**
  - `BudgetBloc`, `BudgetEvent`, `BudgetState`.
  - `BudgetPlannerScreen`, `GroupCard`, `AddGroupSheet` (and later `AddItemSheet`).

## Sync integration
- Add new PendingSync operation types in `[sprout_app/lib/features/sync/domain/pending_sync_operation.dart](sprout_app/lib/features/sync/domain/pending_sync_operation.dart)`:
  - `upsertBudgetGroup`, `deleteBudgetGroup`.
- Add payload encode/decode in `[sprout_app/lib/features/transactions/data/pending_sync_payload.dart](sprout_app/lib/features/transactions/data/pending_sync_payload.dart)`:
  - `encodeBudgetGroupPayload`, `decodeBudgetGroupPayload`.
- Update `[sprout_app/lib/features/sync/application/sync_service.dart](sprout_app/lib/features/sync/application/sync_service.dart)` switch to handle the new ops:
  - upsert → `client.from(SupabaseTables.budgetGroups).upsert(...)`
  - delete → `...delete().eq('id', id)`

## DI + startup wiring
- Update `[sprout_app/lib/core/constants/hive_boxes.dart](sprout_app/lib/core/constants/hive_boxes.dart)` to add `budgetGroups`.
- Open the new Hive box in `[sprout_app/lib/core/startup/startup_initializer.dart](sprout_app/lib/core/startup/startup_initializer.dart)`.
- Register the new box + repo + service in `[sprout_app/lib/core/di/service_locator.dart](sprout_app/lib/core/di/service_locator.dart)`.

## State management (BudgetBloc)
- `BudgetBloc` subscribes to `BudgetService.watchBudgetGroups()`.
- State computes:
  - per-group totals: `group.items.fold(0.0, (s, i) => s + i.amount)`
  - top summary: `totalIncome - totalEssentials - totalLifestyle`.
- Events include:
  - `BudgetSubscriptionRequested`
  - `BudgetGroupUpsertRequested`, `BudgetGroupDeleted`
  - `BudgetItemUpsertRequested`, `BudgetItemDeleted` (implemented by editing the group’s `items` list then saving group).

## UI/UX implementation
- **Settings entry**: add a `ListTile` in `[sprout_app/lib/features/settings/presentation/settings_page.dart](sprout_app/lib/features/settings/presentation/settings_page.dart)` that navigates to `BudgetPlannerScreen` with title **Master Budget**.
- **BudgetPlannerScreen**:
  - Header card with disposable income (uses existing typography + `Card` styling similar to goals header).
  - `DefaultTabController` with `Income`, `Essentials`, `Lifestyle`.
  - List of `GroupCard`s filtered by category.
  - Central add action: use existing `[sprout_app/lib/ui/widgets/enticing_add_button.dart](sprout_app/lib/ui/widgets/enticing_add_button.dart)` or a FAB depending on screen scaffold.
- **GroupCard**:
  - Premium card with leading colored icon disc, title/description, trailing total amount.
  - Tap expands to show item rows with amounts (e.g. `ExpansionTile` styled to match cards).
- **AddGroupSheet**:
  - Bottom sheet with fields: Name, Description, Category selector, Color picker (reuse `AppColors.cardPalette` pattern from `NameColorFormSheet`), Icon picker.

## Supabase schema notes (for you to apply)
Create `budget_groups` with at least:
- `id text primary key`
- `user_id text not null`
- `name text not null`
- `description text null`
- `category text not null` (wire name)
- `color_hex text not null`
- `icon_code_point int null`
- `icon_font_family text null`
- `items_json jsonb not null default '[]'`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

## Files most likely added/changed
- Add: `sprout_app/lib/features/budget/**` (domain/data/application/presentation)
- Update: `[sprout_app/lib/core/storage/hive_adapters.dart](sprout_app/lib/core/storage/hive_adapters.dart)`
- Update: `[sprout_app/lib/core/constants/hive_boxes.dart](sprout_app/lib/core/constants/hive_boxes.dart)`
- Update: `[sprout_app/lib/core/startup/startup_initializer.dart](sprout_app/lib/core/startup/startup_initializer.dart)`
- Update: `[sprout_app/lib/core/di/service_locator.dart](sprout_app/lib/core/di/service_locator.dart)`
- Update: `[sprout_app/lib/features/transactions/data/supabase_tables.dart](sprout_app/lib/features/transactions/data/supabase_tables.dart)`
- Update: `[sprout_app/lib/features/sync/domain/pending_sync_operation.dart](sprout_app/lib/features/sync/domain/pending_sync_operation.dart)`
- Update: `[sprout_app/lib/features/transactions/data/pending_sync_payload.dart](sprout_app/lib/features/transactions/data/pending_sync_payload.dart)`
- Update: `[sprout_app/lib/features/sync/application/sync_service.dart](sprout_app/lib/features/sync/application/sync_service.dart)`
- Update: `[sprout_app/lib/features/settings/presentation/settings_page.dart](sprout_app/lib/features/settings/presentation/settings_page.dart)`

## Implementation todos
