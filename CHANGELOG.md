# Changelog

Changes heading to `main`. Newest entries at the top.

## 2026-09-02 — Goal icons

- Create and edit goal include a curated icon picker
- Chosen icon is stored locally, synced to Supabase, and shown on each goal card
- Existing goals without an icon keep the savings default

## 2026-09-02 — Goals page restyle

- Goals header matches the Lush Growth shell, with a short subtitle under the title
- Goal cards show name, saved/target, leading icon, progress ring, and chevron
- Account and goal cards share the same tinted tile treatment
- Unallocated funds card uses a glow icon, title plus amount, and an inset dashed border

## 2026-09-02 — Create goal form

- Name and target show a Required helper
- Amount fields show an `R` prefix while focused or filled
- The sheet scrolls so the icon picker stays reachable above the keyboard

## 2026-09-02 — Goal progress ring at 100%

- The percent label no longer touches the inner ring
- The ring fills the 56px badge instead of Flutter’s 36px default

## 2026-09-02 — Changelog

- Added this file to track features and fixes going into `main`
- Agents prepend a dated title plus bullets when work is ready to merge
