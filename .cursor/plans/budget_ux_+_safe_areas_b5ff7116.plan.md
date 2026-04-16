---
name: Budget UX + safe areas
overview: Make the Master Budget summary collapsible, improve new-item keyboard flow, show expand/collapse affordance on budget groups, tighten vertical spacing, and fix bottom-sheet padding so primary actions clear Android system navigation.
todos:
  - id: header-collapse
    content: Make _BudgetSummaryHeader stateful with collapsed-by-default breakdown (pills) + tap/chevron toggle
    status: completed
  - id: item-enter-focus
    content: "BudgetItemCard: textInputAction + onSubmitted to move focus name → amount"
    status: completed
  - id: group-chevron
    content: "GroupCard ExpansionTile: add up/down chevron reflecting _expanded in trailing UI"
    status: completed
  - id: tight-spacing
    content: Reduce ListView separator + item padding in budget planner + group_card
    status: completed
  - id: safe-bottom-padding
    content: Add viewInsets + padding bottom inset to NameColorFormSheet, DepositBottomSheet, add_group_sheet, recurring sheet, group appearance modal
    status: completed
isProject: false
---

# Master Budget UX and safe-area fixes

## 1. Collapsible “Theoretical disposable income” header

**Where:** [`sprout_app/lib/features/budget/presentation/budget_planner_screen.dart`](sprout_app/lib/features/budget/presentation/budget_planner_screen.dart) — `_BudgetSummaryHeader` (lines ~85–163).

**Approach (matches “keep total visible, collapse the pills”):**

- Convert `_BudgetSummaryHeader` to a `StatefulWidget` with local state, e.g. `bool _showBreakdown = false` (default **false** so tabs get more vertical space on first load).
- **Always show:** label row + large formatted total (same styling as today).
- **Toggle:** Tappable header row (InkWell) with a trailing chevron (`expand_more` / `expand_less` or `keyboard_arrow_down` / `keyboard_arrow_up`) and optional subtitle like “Tap for breakdown” when collapsed.
- **When expanded:** show the existing `Wrap` of `_MiniTotalPill` widgets unchanged.

This avoids restructuring `DefaultTabController` / `AppBar` + tabs (the “move to top of tabs” option would require a custom `NestedScrollView` / `SliverAppBar` layout and is a larger UX change). The collapsible card satisfies the main pain point (pinned height) with minimal risk.

---

## 2. Enter on item name → focus amount field

**Where:** [`sprout_app/lib/features/budget/presentation/widgets/budget_item_card.dart`](sprout_app/lib/features/budget/presentation/widgets/budget_item_card.dart) — name `TextField` when `_editingName` is true (~196–207).

**Implementation:**

- Set `textInputAction: TextInputAction.next` (or `done` if you prefer single-field semantics).
- Add `onSubmitted: (_) { ... }` that:
  - Switches to amount editing: `setState` → `_editingName = false`, `_editingAmount = true`, sync `_amount.text` with `_amountTextForField(widget.item.amount)` as the tap-to-edit path already does.
  - Requests focus on `_amountFocus` in a **post-frame callback** so focus order is reliable after rebuild.
- Ensure this path still ends up calling `_commit()` via the existing `_onAmountFocus` listener when the user leaves the amount field (unchanged behavior).

---

## 3. Visible expand/collapse affordance on groups

**Where:** [`sprout_app/lib/features/budget/presentation/widgets/group_card.dart`](sprout_app/lib/features/budget/presentation/widgets/group_card.dart) — `ExpansionTile` (~340+). A custom `trailing` replaces Material’s default expand icon, so users get no visual hint.

**Approach:**

- Add a small chevron icon that reflects `_expanded` (updated in existing `onExpansionChanged`):
  - Collapsed: **down** (e.g. `Icons.keyboard_arrow_down_rounded` or `Icons.expand_more_rounded`).
  - Expanded: **up** (e.g. `Icons.keyboard_arrow_up_rounded` or `Icons.expand_less_rounded`).
- Integrate it into the existing `trailing` `Column` / `Row` (e.g. place the chevron beside the total or above the edit/delete row) so tap targets for total and actions stay usable. `ExpansionTile` still handles expand/collapse from the tile tap; the chevron only needs to **communicate state**, not duplicate hit testing unless you wrap it in a small `Icon` with `IgnorePointer` or rely on the parent tile.

---

## 4. Tighter vertical spacing between items

**Where:**

- [`budget_planner_screen.dart`](sprout_app/lib/features/budget/presentation/budget_planner_screen.dart) — `_BudgetCategoryTab` `ListView.separated` uses `separatorBuilder: (…) => SizedBox(height: 10)`; reduce to **6** or **8**.
- [`group_card.dart`](sprout_app/lib/features/budget/presentation/widgets/group_card.dart) — `Padding(padding: EdgeInsets.only(top: 10))` around each `BudgetItemCard`; reduce proportionally (e.g. **6–8**).

Keep padding inside `BudgetItemCard`’s `Card` as-is unless the list still feels loose; only adjust the inter-item gaps above.

---

## 5. Safe areas: Save / primary actions above Android navigation bar

**Root cause:** Several sheets pad only with `MediaQuery.viewInsetsOf(context).bottom` (keyboard). That is **0** when the keyboard is closed, so content can sit under the **system gesture/navigation bar**. The missing piece is `MediaQuery.paddingOf(context).bottom` (safe-area inset) or an explicit `SafeArea`.

**Files to align (same pattern everywhere):**

| File | Current pattern |
|------|-----------------|
| [`sprout_app/lib/ui/widgets/name_color_form_sheet.dart`](sprout_app/lib/ui/widgets/name_color_form_sheet.dart) | `bottom: viewInsets.bottom + 20` |
| [`sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart`](sprout_app/lib/features/shell/presentation/deposit_bottom_sheet.dart) | same |
| [`sprout_app/lib/features/budget/presentation/widgets/add_group_sheet.dart`](sprout_app/lib/features/budget/presentation/widgets/add_group_sheet.dart) | `SafeArea` + `viewInsets` only in scroll padding — verify bottom inset is sufficient (may still need `padding.bottom` in the scroll padding when `SafeArea` does not fully apply) |
| [`sprout_app/lib/features/transactions/presentation/recurring_payments_page.dart`](sprout_app/lib/features/transactions/presentation/recurring_payments_page.dart) | same as `NameColorFormSheet` |
| [`group_card.dart`](sprout_app/lib/features/budget/presentation/widgets/group_card.dart) appearance modal | `viewInsets + 20` only |

**Recommended pattern** (single helper optional, or inline):

```dart
final mq = MediaQuery.of(context);
final bottomPadding = mq.viewInsets.bottom + mq.padding.bottom;
// use: EdgeInsets.only(..., bottom: bottomPadding + 20)
```

Apply to the **bottom** of the scrollable / column that contains the primary button so **Save** and other bottom actions clear the nav bar. Optionally add `useSafeArea: true` on `showModalBottomSheet` calls in [`shell_page.dart`](sprout_app/lib/features/shell/presentation/shell_page.dart) and nested opens **if** not already default — but the padding fix above is the reliable fix inside content.

**Scope:** Touch only these sheet/modal builders; avoid unrelated `app.dart` or global `MaterialApp` changes unless a gap remains after padding fixes.

---

## Dependency / testing notes

- **Manual:** Verify on a device or emulator with **3-button and gesture** navigation; open + → New account / New goal / Deposit and confirm **Save** is fully above the system bar with keyboard open and closed.
- **Budget:** Collapse/expand summary; confirm pills only when expanded; group chevrons match expanded state; new item: type name → Enter → cursor in amount field.
