---
name: unallocated-funds
overview: Add a dynamically computed Unallocated Funds balance (no persistence for the derived value) and surface it as a tappable card at the top of Goals, opening the deposit bottom sheet prefilled with the available amount.
todos:
  - id: evolve-transactions-to-support-unallocated
    content: Evolve `Transaction` model to support account deposits (unallocated) + goal allocations (assigned), via `kind` and nullable `goalId`; add migration + update repository mappers.
    status: completed
  - id: compute-unallocated-in-goals-bloc
    content: Update `GoalsBloc` to combine accounts/goals/transactions streams and emit `GoalsReady(progressList, unallocatedBalance)` computed from deposits minus allocations.
    status: completed
  - id: add-unallocated-card-widget
    content: Implement `UnallocatedFundsCard` with dashed border + ZAR formatting and tap callback.
    status: completed
  - id: deposit-and-allocation-ui
    content: Update deposit flow to support a toggle between (A) full deposit to a goal and (B) deposit to account then allocate/split across goals; tapping Unallocated card opens Allocate mode prefilled.
    status: completed
isProject: false
---

## Goal
Implement **Unallocated Funds** as a derived value:
- \(unallocatedCents = sum(AccountDepositsCents) - sum(GoalAllocationCents)\)
- Expose it on `GoalsState` (as `unallocatedBalance` double per requirement) and show a distinct, tappable UI card on the Goals screen when > 0.

## Key design decisions
- **No new storage for Unallocated Funds**: it will be computed in `GoalsBloc` from existing reactive sources.
- **Represent money in cents internally**: compute in cents to avoid floating point drift, then map to `double unallocatedBalance` as `unallocatedCents / 100.0`.
- **Reactive updates**: `GoalsBloc` will subscribe to **accounts + goals + transactions** streams so the value updates immediately after deposits or allocations.

## Required domain/data updates (enables partial allocation)
Your desired flow is:
- user deposits **X** into **Account A** (money exists, but not yet assigned to any goal)
- user allocates **some/all** of that deposit across one or more goals (A, B, ...)

The current model can’t express “unallocated sitting in an account” because `Transaction` always requires a `goalId`.

We will evolve the existing `transactions` model to support both concepts while keeping a **single source of truth** (and still not persisting any derived “unallocated” aggregate).

### Transaction model changes (single table)
- Add `kind` to `Transaction`:
  - `deposit` (adds money into an account; `goalId == null`)
  - `allocation` (assigns money from an account into a goal; `goalId != null`)
- Allow `goal_id` to be NULL in Supabase for `deposit` rows.
- Add a Supabase migration that:
  - adds `kind text not null default 'allocation'` (backward compatible)
  - makes `goal_id` nullable
  - adds a check constraint like `((kind = 'deposit' and goal_id is null) or (kind = 'allocation' and goal_id is not null))`
- Update Hive model + mappers accordingly.

## Application layer: `GoalsBloc` + `GoalsState`
Update `[sprout_app/lib/features/goals/presentation/goals_bloc.dart](sprout_app/lib/features/goals/presentation/goals_bloc.dart)`:
- **State changes**:
  - Extend `GoalsReady` to include `final double unallocatedBalance;`.
  - Update `props` to include it.
- **Bloc changes**:
  - Inject `AccountsService` (in addition to existing `GoalsService` + `TransactionsService`).
  - Update the internal stream combiner to listen to:
    - `_accountsService.watchAccounts()`
    - `_goalsService.watchGoals()`
    - `_transactionsService.watchTransactions()`
  - In the combined emission, compute:
    - `depositByAccountId` and `allocationByAccountId` from transactions
      - deposits: `kind == deposit` (sum by `accountId`)
      - allocations: `kind == allocation` (sum by `accountId`)
    - `unallocatedCents = sum(max(0, depositByAccountId[a.id] - allocationByAccountId[a.id]))`
    - `savedByGoalId` from **allocations only** (sum by `goalId`)
    - `unallocatedCents = unallocatedCents.clamp(0, 1<<62)`
    - emit `GoalsReady(progressList, unallocatedBalance: unallocatedCents / 100.0)`

## UI: `UnallocatedFundsCard`
Create a new widget in goals presentation, e.g.:
- `[sprout_app/lib/features/goals/presentation/widgets/unallocated_funds_card.dart](sprout_app/lib/features/goals/presentation/widgets/unallocated_funds_card.dart)`

Widget requirements:
- Distinct from goal cards:
  - Use a **custom dashed border** (no new dependency) via `CustomPainter`.
  - Muted background: `colorScheme.surfaceContainerHighest` (or similar) and an accent border (`colorScheme.tertiary` / `primary`).
- Text:
  - `Ready to Sprout! You have {formattedAmount} waiting to be assigned.`
  - Use existing formatter `formatZarFromCents(...)` from `[sprout_app/lib/core/utils/money_format.dart](sprout_app/lib/core/utils/money_format.dart)`.
- Interaction:
  - `onTap` callback.

## Wire-up: insert card into Goals screen
Update `[sprout_app/lib/features/goals/presentation/goals_page.dart](sprout_app/lib/features/goals/presentation/goals_page.dart)`:
- After the title sliver and **before** the goals `SliverList`, insert a `SliverToBoxAdapter` that renders `UnallocatedFundsCard` **only when** `state.unallocatedBalance > 0`.
- On tap, open the deposit/allocation sheet in **Allocate** mode, prefilled with the available unallocated amount.

## Deposit + allocation UX (single sheet with toggle)
Update `[sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart](sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart)`:
- Add a mode toggle:
  - **Full deposit (current behavior)**: choose account + goal + amount → records an `allocation` (backward compatible)
  - **Deposit to account then allocate**:
    - Step 1: record `deposit` (account + amount)
    - Step 2: allocate some/all of that amount to one or more goals (records one or more `allocation` rows)
- Add params to support prefill:
  - `initialAmountCents` (int?)
  - `initialMode` (depositToAccountThenAllocate)
  - keep existing `initialAccountId`/`initialGoalId` behavior for full-deposit mode

## Notes / verification
- Confirm the DI wiring where `GoalsBloc` is provided (likely in a `BlocProvider` setup under `[sprout_app/lib/features/goals/goals.dart](sprout_app/lib/features/goals/goals.dart)` or the app shell) and add `AccountsService` injection there.
- Verify the card hides at zero, and updates immediately after:
  - recording a deposit (`kind=deposit`)
  - recording allocations (`kind=allocation`), including partial splits across goals

