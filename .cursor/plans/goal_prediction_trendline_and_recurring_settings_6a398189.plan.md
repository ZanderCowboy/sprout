---
name: goal_prediction_trendline_and_recurring_settings
overview: Adjust the goal detail chart to show only 0 and target on the Y axis, add a dotted prediction trendline to an estimated target date (based on recurring deposits when present), and add a Settings page entry to manage recurring deposits (list/edit/cancel) by updating the stored recurring transaction rows in Hive + Supabase.
todos:
  - id: chart-axis-and-borders
    content: Update goal chart to show only 0 and target labels; remove grid lines; set maxY to max(target,saved).
    status: completed
  - id: prediction-mapper
    content: "Add prediction calculation in mapper/BLoC: recurring-based effective rate; fallback to historical linear trend when available."
    status: completed
  - id: dotted-trend-line
    content: Render dotted prediction line to (predictedDate, targetY) when under-target and prediction available.
    status: completed
  - id: settings-entry
    content: Add Settings page entry point (gear icon) accessible from Home/Goals.
    status: completed
  - id: recurring-management-ui
    content: Add RecurringPaymentsPage under Settings with list + edit/cancel recurring configs.
    status: completed
  - id: transactions-update-recurring
    content: Add repository/service + sync support to update recurring config on existing transactions (Hive + Supabase + pending sync).
    status: completed
isProject: false
---

## What will change
### Goal detail graph (UX + prediction)
- **Axis labels**: Only show **0** (bottom) and **goal target** (top) on the Y axis.
- **Scale**:
  - `minY = 0`
  - `maxY = max(goal.targetAmountCents, currentSavedCents)` so over-target deposits still fit.
- **Grid lines**: Disable grid lines; keep chart border only.
- **Actual growth line**: Keep the existing solid line + gradient fill for cumulative saved amounts.
- **Prediction (“trend”) dotted line**:
  - If goal is **not yet reached** and we can compute a prediction, draw a **dotted diagonal** line from the **latest actual point** 
    to a **target point** at:
    - `y = goal.targetAmountCents`
    - `x = predictedReachDate.millisecondsSinceEpoch`
  - If goal is already reached/over, **hide** the prediction line.

### Prediction logic (STRICT: not in UI)
- Implement in BLoC or mapper (not widget):
  - Find **all recurring deposits** for the goal (`isRecurring == true`, `frequency != none`).
  - Compute an **effective daily savings rate** (cents/day) by summing each recurring config:
    - daily: `amountCents / 1`
    - weekly: `amountCents / 7`
    - monthly: `amountCents / 30.4375` (average month)
    - yearly: `amountCents / 365.25`
  - Remaining cents = `goal.targetAmountCents - currentSavedCents`.
  - Days to reach = `ceil(remaining / dailyRate)`.
  - Predicted reach date = `lastDepositDate + daysToReach`.
- If there are **no recurring deposits**, fall back to a linear projection:
  - If there are >=2 deposits, compute average daily rate from historical deposits:
    - `rate = (lastCumulative - firstCumulative) / daysBetween(first,last)`
  - If there is only 1 deposit (or 0), either:
    - hide prediction, or
    - use a simple default (we’ll hide prediction for 0–1 deposit to avoid misleading output).

## Recurring payments management (Settings)
### New Settings entry point
- Add a `SettingsPage` accessible from a consistent place:
  - Since `ShellPage` has no app bar, add a small **gear icon** action at the top of `HomePage` and `GoalsPage` headers (same route).

### Recurring management screen
- Add `RecurringPaymentsPage` with:
  - List of recurring transactions (show goal name, account name, amount, frequency, next scheduled date)
  - Actions per item:
    - **Edit**: frequency + toggle recurring off/on
    - **Cancel**: set `isRecurring=false`, `frequency=none`, `nextScheduledDate=null`

### Data updates required for managing recurring
- Add repository/service support to **update an existing transaction**:
  - `TransactionsRepository.updateTransactionRecurringConfig(...)`
  - Implementation updates Hive row and enqueues a pending sync operation that performs a Supabase `update` or `upsert` (consistent with current sync).
- Add a new pending sync operation type for updating transaction recurring fields (or reuse upsert if safe).

## Files to touch (expected)
- Chart + mapper + BLoC:
  - [`sprout_app/lib/features/goals/presentation/goal_growth_chart_mapper.dart`](sprout_app/lib/features/goals/presentation/goal_growth_chart_mapper.dart)
  - [`sprout_app/lib/features/goals/presentation/goal_detail_bloc.dart`](sprout_app/lib/features/goals/presentation/goal_detail_bloc.dart)
  - [`sprout_app/lib/features/goals/presentation/goal_detail_page.dart`](sprout_app/lib/features/goals/presentation/goal_detail_page.dart)
- Settings + recurring screen:
  - New: `sprout_app/lib/features/settings/presentation/settings_page.dart`
  - New: `sprout_app/lib/features/transactions/presentation/recurring_payments_page.dart`
  - Update `HomePage` and `GoalsPage` header UI to include settings icon.
- Transactions update support:
  - [`sprout_app/lib/features/transactions/domain/transactions_repository.dart`](sprout_app/lib/features/transactions/domain/transactions_repository.dart)
  - [`sprout_app/lib/features/transactions/application/transactions_service.dart`](sprout_app/lib/features/transactions/application/transactions_service.dart)
  - [`sprout_app/lib/features/transactions/data/transactions_repository_impl.dart`](sprout_app/lib/features/transactions/data/transactions_repository_impl.dart)
  - [`sprout_app/lib/features/transactions/data/pending_sync_payload.dart`](sprout_app/lib/features/transactions/data/pending_sync_payload.dart)
  - [`sprout_app/lib/features/sync/domain/pending_sync_operation.dart`](sprout_app/lib/features/sync/domain/pending_sync_operation.dart)
  - [`sprout_app/lib/features/sync/application/sync_service.dart`](sprout_app/lib/features/sync/application/sync_service.dart)

## Edge cases handled
- **Over-target**: chart `maxY` expands to show deposits above target.
- **No/low data**: prediction hidden when unreliable.
- **Multiple recurring configs**: summed into a single effective rate.

## Test plan
- Unit-ish: test prediction mapper (rate calculations) with multiple frequencies.
- Widget smoke: open goal detail with 0/1/many deposits and ensure axis labels are only 0 + target.
- Manual: edit/cancel recurring payment and confirm it persists locally and syncs when Supabase is enabled.