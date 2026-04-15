---
name: Goals psychology-first UI
overview: Reframe goal UI to lead with actionable progress (remaining/overall progress) and add an overall goals progress header to increase salience and contribution intent.
todos:
  - id: aggregate-overall-goals-progress
    content: Compute totalSaved/totalTarget/overallPercent in Goals page from GoalsReady.progressList and add a header widget under the title.
    status: completed
  - id: rework-goal-card-hierarchy
    content: Update each goal card to make Remaining the primary line, with name + saved/target secondary, while keeping the circular % indicator.
    status: completed
  - id: polish-copy-and-accessibility
    content: Adjust microcopy (optional “away from all goals”) and add Semantics labels for the new header.
    status: completed
isProject: false
---

# Goals psychology-first UI plan

## What we’ll change (high impact, low risk)

- **Goals list cards**: change the information hierarchy so users see the *most actionable number first*.
  - Current: `title = goal name`, subtitle shows target/remaining/%.
  - Proposed: **primary line shows Remaining (big)**, secondary shows goal name and Saved/Target, while keeping the existing circular % indicator.
  - File: [`/Users/zander.kotze/Workspace/Personal/sprout/sprout_app/lib/features/goals/presentation/goals_page.dart`](/Users/zander.kotze/Workspace/Personal/sprout/sprout_app/lib/features/goals/presentation/goals_page.dart)

- **Goals page overall progress header**: add a header section *below the Goals title* that summarizes all active goals.
  - Show:
    - **Overall %** (weighted): \(\lfloor 100 \cdot \text{totalSaved} / \text{totalTarget} \rfloor\)
    - **Saved**: totalSaved
    - **Target**: totalTarget
    - Optional small line: “You’re R X away from all goals” (totalRemaining = max(totalTarget - totalSaved, 0))
  - This uses data already available in `GoalsReady.progressList`.
  - Files:
    - [`/Users/zander.kotze/Workspace/Personal/sprout/sprout_app/lib/features/goals/presentation/goals_page.dart`](/Users/zander.kotze/Workspace/Personal/sprout/sprout_app/lib/features/goals/presentation/goals_page.dart)
    - (Optional helper) [`/Users/zander.kotze/Workspace/Personal/sprout/sprout_app/lib/features/goals/domain/goal_progress.dart`](/Users/zander.kotze/Workspace/Personal/sprout/sprout_app/lib/features/goals/domain/goal_progress.dart)

## Psychology / behavioral levers we’ll explicitly use

- **Actionable gap framing**: “Remaining” is a concrete next-step target; it reduces cognitive load compared to “Target”.
- **Goal gradient effect**: keeping % visible (and making it more prominent) boosts motivation as users approach completion.
- **Portfolio momentum**: the overall header creates a sense of cumulative progress and encourages “just a bit more” behavior.
- **Immediate opportunity cue**: keep `UnallocatedFundsCard` near the top; the overall header will sit *above or below* it depending on what feels most motivating (we’ll place it just below the title and above unallocated so the page opens with progress-first framing).

## Data computations (no backend changes)

- In `GoalsPage` (when `state is GoalsReady`):
  - `totalTargetCents = sum(g.targetAmountCents)`
  - `totalSavedCents = sum(p.savedCents)`
  - `totalRemainingCents = max(totalTargetCents - totalSavedCents, 0)`
  - `overallPercent = totalTargetCents <= 0 ? 0 : (totalSavedCents * 100) ~/ totalTargetCents`

## UI sketch (structural)

- `CustomScrollView` slivers order:
  - Title row (existing)
  - **Overall progress header** (new)
  - `UnallocatedFundsCard` (existing, conditionally shown)
  - Goals list (existing)

## Implementation notes

- Reuse existing formatting: `formatZarFromCents(...)` from `sprout/core/core.dart` (already used in goals UI).
- Keep accessibility: header should use `Semantics` labels similar to `UnallocatedFundsCard`.
- Keep the list compact: avoid multi-line subtitle blocks; convert to a tighter layout so the number-first emphasis is clear.

## Test plan (lightweight)

- Run the app and verify:
  - Header totals match sum of individual goals.
  - Overall % behaves correctly when there are no goals, or when total target is 0.
  - Card layout doesn’t overflow on small screens / long goal names.
  - The unallocated card still appears when `unallocatedBalance > 0` and remains tappable.
