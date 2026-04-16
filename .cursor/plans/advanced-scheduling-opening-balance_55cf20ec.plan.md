---
name: advanced-scheduling-opening-balance
overview: Add user-selected deposit dates (scheduled + recurring anchor) and goal opening-balance creation (as deposit+allocation) while keeping goal progress derived only from transactions/allocations. Update UI list styling and charts to treat future-dated transactions as pending and exclude them from historical graphs.
todos:
  - id: add-create-goal-bloc
    content: Introduce `CreateGoalBloc` with sequential goal-save then opening-balance transaction creation.
    status: completed
  - id: create-goal-ui
    content: Update/create CreateGoal UI to add already-saved amount + conditional account dropdown and wire it to `CreateGoalBloc`.
    status: completed
  - id: deposit-date-ui
    content: Update deposit UI to include date picker and pass selected date to transaction creation; preserve recurring anchor semantics.
    status: completed
  - id: pending-ui-mapper
    content: Add centralized UI mapper/helper for cleared vs pending-by-date and apply it to account/goal detail transaction lists.
    status: completed
  - id: chart-filter-future
    content: Update goal growth chart mapper to ignore future-dated transactions.
    status: completed
isProject: false
---

## Goals
- Add a **user-selectable date** to deposits that drives both **scheduled one-time** deposits and the **anchor date** for recurring deposits.
- Add an **opening balance** flow when creating a goal: save the goal, then create transactions that represent the already-saved money without adding `initialBalance` to `Goal`.
- Visually differentiate **future-dated** transactions (“Pending”) and ensure the **growth chart ignores future dates**.

## Key repo realities (what exists today)
- **Goal creation is currently UI-driven** via `[sprout_app/lib/features/goals/presentation/goal_form_sheet.dart](sprout_app/lib/features/goals/presentation/goal_form_sheet.dart)` calling `[sprout_app/lib/features/goals/application/goals_service.dart](sprout_app/lib/features/goals/application/goals_service.dart)`.
- **Deposit UI** is `[sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart](sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart)` and deposits already support `occurredAt` (optional) through `[sprout_app/lib/features/transactions/application/transactions_service.dart](sprout_app/lib/features/transactions/application/transactions_service.dart)` and `[sprout_app/lib/features/transactions/data/transactions_repository_impl.dart](sprout_app/lib/features/transactions/data/transactions_repository_impl.dart)`.
- `Transaction` already has `occurredAt` + `nextScheduledDate` in `[sprout_app/lib/features/transactions/domain/transaction.dart](sprout_app/lib/features/transactions/domain/transaction.dart)`.
- Goal growth chart mapping is in `[sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart](sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart)` and currently plots **all** transactions regardless of whether `occurredAt` is in the future.

## Design decisions locked in (from your answers)
- **Introduce a `CreateGoalBloc`** and route goal creation through it.
- Treat `Transaction.occurredAt` as the required **`date` field** (no rename), and keep using `nextScheduledDate`.

## Implementation outline

### A) Scheduled & recurring dates
- **Domain**
  - Keep `Transaction.occurredAt` as the “first/only occurrence date”. Continue to use `Transaction.nextScheduledDate` for recurring.
- **Deposit UI** (`DepositBottomSheet`)
  - Add a `DateTime _selectedDate` state defaulting to `DateTime.now()`.
  - Add a “Date” selector UI (Material date picker).
  - On submit:
    - Pass `occurredAt: _selectedDate` into `recordDeposit(...)` / `recordAccountDeposit(...)`.
    - The existing recurrence logic already uses the passed `occurredAt` as the anchor when computing `nextScheduledDate`.
  - Semantics:
    - If `_selectedDate` is in the future and `_isRecurring == false`: this becomes a **scheduled one-time** deposit.
    - If `_isRecurring == true`: this becomes the **anchor date** for the schedule.

### B) Goal initial balances (opening balance)
- **UI** (new “Create Goal Screen”, implemented as a sheet-compatible widget)
  - Base it on the existing `[sprout_app/lib/features/goals/presentation/goal_form_sheet.dart](sprout_app/lib/features/goals/presentation/goal_form_sheet.dart)` / `NameColorFormSheet` pattern.
  - Add optional input: **Already Saved Amount (ZAR)**.
  - If amount > 0: reveal a **required** account dropdown (active accounts) “Which Account holds this money?”.
- **BLoC**
  - Create `[sprout_app/lib/features/goals/presentation/create_goal_bloc.dart](sprout_app/lib/features/goals/presentation/create_goal_bloc.dart)` (new) with events/states for:
    - loading accounts list
    - validating form
    - submitting
    - success/failure
  - **Sequential requirement** implemented in the bloc submit handler:

```dart
// PSEUDOCODE SHAPE (will be implemented in bloc)
await goalsService.saveGoal(goal);
if (alreadySavedCents > 0) {
  final groupId = uuid.v4();
  await transactionsService.recordAccountDeposit(
    accountId: selectedAccountId,
    groupId: groupId,
    amountCents: alreadySavedCents,
    occurredAt: DateTime.now(),
    note: 'Opening Balance',
    isRecurring: false,
    frequency: TransactionFrequency.none,
  );
  await transactionsService.recordAllocation(
    accountId: selectedAccountId,
    goalId: goal.id,
    groupId: groupId,
    amountCents: alreadySavedCents,
    occurredAt: DateTime.now(),
    note: 'Opening Balance',
  );
}
```

- This preserves the **data-integrity rule** (no `initialBalance` on `Goal`) and keeps **unallocated funds balanced** by representing the opening balance as a deposit + a 100% allocation.

### C) Cleared vs pending (future-dated) UI differentiation
- Add a small, centralized mapper/helper:
  - New file suggestion: `[sprout_app/lib/features/transactions/presentation/utils/transaction_display.dart](sprout_app/lib/features/transactions/presentation/utils/transaction_display.dart)`
  - Provide:
    - `bool isPendingByDate(Transaction t, DateTime now)` => `t.occurredAt.isAfter(now)`
    - `TransactionListStyle mapTransactionToListStyle(...)` returning:
      - `opacity` (e.g. 0.6)
      - `leadingIcon` (hourglass)
      - `statusText` (“Pending”)
- Apply in these screens (currently inline list tiles):
  - `[sprout_app/lib/features/accounts/presentation/account_detail_page.dart](sprout_app/lib/features/accounts/presentation/account_detail_page.dart)`
  - `[sprout_app/lib/features/goals/presentation/goal_detail_page.dart](sprout_app/lib/features/goals/presentation/goal_detail_page.dart)`
  - (Optionally later) `[sprout_app/lib/features/home/presentation/overview_page.dart](sprout_app/lib/features/home/presentation/overview_page.dart)` and transactions list page.

### D) Chart mapper must ignore future-dated transactions
- Update `[sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart](sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart)`:
  - Filter `transactions` to `t.occurredAt <= now` before computing running totals.
  - Keep the starting point at `goalCreatedAt`.

## Files most likely to change/add
- **Add**: `[sprout_app/lib/features/goals/presentation/create_goal_bloc.dart](sprout_app/lib/features/goals/presentation/create_goal_bloc.dart)`
- **Add/Update**: create-goal UI wrapper/screen (or refactor existing sheet) in `[sprout_app/lib/features/goals/presentation/](sprout_app/lib/features/goals/presentation/)`
- **Update**: `[sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart](sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart)` (date selector + pass `occurredAt`)
- **Add**: `[sprout_app/lib/features/transactions/presentation/utils/transaction_display.dart](sprout_app/lib/features/transactions/presentation/utils/transaction_display.dart)`
- **Update**: `[sprout_app/lib/features/accounts/presentation/account_detail_page.dart](sprout_app/lib/features/accounts/presentation/account_detail_page.dart)` (pending styling)
- **Update**: `[sprout_app/lib/features/goals/presentation/goal_detail_page.dart](sprout_app/lib/features/goals/presentation/goal_detail_page.dart)` (pending styling)
- **Update**: `[sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart](sprout_app/lib/features/goals/presentation/utils/goal_growth_chart.dart)` (filter future)

## Acceptance checks
- Creating a goal with **Already Saved Amount** creates:
  - 1 new goal
  - 1 deposit transaction (unallocated) with note “Opening Balance”
  - 1 allocation transaction (same amount) to the new goal with the same groupId
- Deposit sheet allows selecting a date; selecting a future date creates a transaction dated in the future.
- Account/Goal detail lists show future-dated transactions as **Pending** (visual distinction).
- Goal growth line ignores future-dated deposits/allocations (historical line remains truthful).