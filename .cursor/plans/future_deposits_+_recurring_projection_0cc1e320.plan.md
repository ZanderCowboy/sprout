---
name: Future deposits + recurring projection
overview: Fix future-dated deposits/allocations so they are scheduled (not applied early), keep disabled recurring payments visible, and project enabled recurring payments into the goal growth graph until target is reached.
todos:
  - id: scheduled-ui
    content: Group future-dated transactions into a Scheduled section in TransactionsPage and GoalDetailPage, using pending styling.
    status: completed
  - id: scheduled-allocations
    content: Ensure allocations created from a future-dated deposit are scheduled for the same date; exclude future-dated txs from available-unallocated calculations.
    status: completed
  - id: recurring-enabled-flag
    content: Add a persistent recurringEnabled flag (Hive + mapping) so disabling doesn’t remove recurring items.
    status: completed
  - id: recurring-page
    content: Update RecurringPayments filtering + edit sheet to show disabled items and toggle enabled state.
    status: completed
  - id: goal-projection-steps
    content: Update goal growth prediction to step through enabled recurring deposits until the target is reached.
    status: completed
isProject: false
---

## Findings (current behavior)
- **Future-dated transactions are persisted immediately** via `TransactionsRepositoryImpl.addTransaction()` using the selected `occurredAt` date. They are treated as “pending by date” in some places (e.g. portfolio summary and goal progress exclude future-dated amounts), but **they still appear in the global transactions list**.
  - See `sprout_app/lib/features/transactions/data/transactions_repository_impl.dart` (saves immediately) and `sprout_app/lib/features/transactions/presentation/transactions_page.dart` (renders all items with no pending styling/filtering).
- **Allocations in the “deposit to account then allocate” flow ignore the selected date**, because allocations are recorded without passing `occurredAt`, so they default to “now”.
  - See `sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart` where `recordAccountDeposit(... occurredAt: _selectedDate)` is followed by `recordAllocation(...)` with no `occurredAt`.
- **Recurring payments disappear when disabled** because the recurring page filters `t.isRecurring && t.frequency != none`, and disabling sets both to “off”.
  - See `sprout_app/lib/features/transactions/presentation/bloc/recurring_payments_bloc.dart` filter and `TransactionsRepositoryImpl.updateTransactionRecurringConfig()` which sets `isRecurring=false` and `frequencyIndex=0`.
- **Goal graph prediction** (`predictGoalReach`) currently draws a straight dashed line from last actual point to target; it doesn’t “step” by recurring occurrences. Also it assumes recurring config is represented directly on transactions.
  - See `sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart`.

## Approach
### 1) Scheduled (future-dated) deposits/allocations UX
- Keep persisting future-dated transactions as we do now (so they can “activate” automatically when the date arrives), but:
  - Show them **only in a dedicated Scheduled section** in transaction lists.
  - Style them as **Pending** using existing `TransactionDisplay.isPendingByDate` and `mapTransactionToListStyle`.

**Targets**
- `[sprout_app/lib/features/transactions/presentation/transactions_page.dart](sprout_app/lib/features/transactions/presentation/transactions_page.dart)` and/or `[sprout_app/lib/features/transactions/presentation/bloc/transactions_bloc.dart](sprout_app/lib/features/transactions/presentation/bloc/transactions_bloc.dart)`
  - Split items into `scheduled = occurredAt > now` and `history = occurredAt <= now`.
  - Render `Scheduled` first (or last) with a header and Pending styling.
- `[sprout_app/lib/features/goals/presentation/goal_detail_page.dart](sprout_app/lib/features/goals/presentation/goal_detail_page.dart)`
  - The goal detail page already shows Pending styling but currently mixes scheduled with history. Split similarly so scheduled deposits/allocations are grouped.

### 2) Fix future-date allocations (deposit → allocate)
- When `_selectedDate` is in the future and the user allocates in the same flow, record allocations using the **same `occurredAt`**.

**Targets**
- `[sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart](sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart)`
  - In `depositToAccountThenAllocate` branch, pass `occurredAt: _selectedDate` into every `recordAllocation(...)` created in that group.
  - In `allocateExistingUnallocated` mode’s balance calculation, ignore pending-by-date deposits/allocations so future money can’t be used early.

### 3) Keep recurring payments visible when disabled
- Extend the transaction model to track:
  - `isRecurringTemplate` (or reuse `isRecurring`): “this deposit has recurring config and should appear in the recurring list”.
  - `recurringEnabled`: “scheduler/projection should treat it as active”.
- Update disabling behavior to set `recurringEnabled=false` while preserving the template and the last chosen frequency.

**Targets**
- Domain/data mapping:
  - `[sprout_app/lib/features/transactions/domain/transaction.dart](sprout_app/lib/features/transactions/domain/transaction.dart)` add `recurringEnabled` (default true when `isRecurring` is true).
  - `[sprout_app/lib/features/transactions/data/local/transaction_hive_model.dart](sprout_app/lib/features/transactions/data/local/transaction_hive_model.dart)` add a stored `recurringEnabled` field.
  - `[sprout_app/lib/core/storage/hive_adapters.dart](sprout_app/lib/core/storage/hive_adapters.dart)` extend `TransactionHiveAdapter` with backward-compatible read/write of the extra boolean.
  - `[sprout_app/lib/features/transactions/data/transaction_mapper.dart](sprout_app/lib/features/transactions/data/transaction_mapper.dart)` map new field to/from Hive and Supabase rows.
- UI filtering:
  - `[sprout_app/lib/features/transactions/presentation/bloc/recurring_payments_bloc.dart](sprout_app/lib/features/transactions/presentation/bloc/recurring_payments_bloc.dart)` filter by template-ness (e.g. `t.isRecurring == true` and kind deposit) rather than “enabled”.
  - `[sprout_app/lib/features/transactions/presentation/recurring_payments_page.dart](sprout_app/lib/features/transactions/presentation/recurring_payments_page.dart)` show an Enabled/Disabled indicator and allow toggling `recurringEnabled`.
- Update API:
  - `[sprout_app/lib/features/transactions/application/transactions_service.dart](sprout_app/lib/features/transactions/application/transactions_service.dart)` keep method signature, but change meaning so it updates `recurringEnabled` without clearing the template.
  - `[sprout_app/lib/features/transactions/data/transactions_repository_impl.dart](sprout_app/lib/features/transactions/data/transactions_repository_impl.dart)` update `addTransaction` and `updateTransactionRecurringConfig` accordingly.

**Supabase note**
- If you’re syncing transactions to Supabase, we’ll need a new column (e.g. `recurring_enabled boolean default true`) and update the upsert mapping. If you already have migrations in-repo, we’ll add one; if not, we’ll guard with a safe fallback so the app still runs offline.

### 4) Goal graph: project recurring “steps” until target
- Update `predictGoalReach` to:
  - Consider only **enabled recurring templates** assigned to this goal.
  - Simulate upcoming occurrences from `max(lastActualDate, now)` forward.
  - Add prediction points at each occurrence date, increasing cumulative cents by the recurring amount(s), until the goal target is reached (or a safety cap like 5 years / N points).
  - Return a polyline of multiple spots (a stepped/segmented dashed line), rather than only two points.

**Targets**
- `[sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart](sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart)`
  - Add a small recurrence simulator (advance next date by frequency; handle multiple templates).
  - Keep existing fallback (historical average) when no enabled recurring templates exist.

## Implementation todos
- **scheduled-ui**: Split lists into `Scheduled` and `History` in `TransactionsPage` and `GoalDetailPage` using `TransactionDisplay.isPendingByDate`.
- **scheduled-allocations**: In `DepositBottomSheet`, schedule allocations with the same `occurredAt` as the selected deposit date; ignore future-dated transactions in “available unallocated” math.
- **recurring-enabled-flag**: Add `recurringEnabled` to `Transaction` + Hive model + adapter + mappers; update repository/service update logic.
- **recurring-page**: Update `RecurringPaymentsBloc` filtering and edit sheet to toggle enabled without deleting the item.
- **goal-projection-steps**: Update `predictGoalReach` to produce a multi-point dashed projection that reflects expected recurring deposits until target.

## Quick acceptance checks
- Creating a deposit dated next month shows it under **Scheduled** (Pending) and does not affect portfolio/goal saved until that date.
- Creating “deposit to account then allocate” dated next month schedules both deposit and allocations for next month (no immediate goal progress/balance changes).
- Disabling a recurring payment keeps it visible in **Recurring payments** with status Disabled; re-enabling restores it.
- A goal with an enabled recurring deposit shows a dashed projection that increases at each expected occurrence until the goal reaches the target.