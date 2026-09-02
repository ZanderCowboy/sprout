# Changelog

Changes heading to `main`. Newest entries at the top.

## 2026-09-02 — Manage opens Customer Center

- Settings Premium Manage opens RevenueCat Customer Center instead of the paywall
- The tile refreshes after restore, or if Premium is no longer active

## 2026-09-02 — Profile label

- Settings and the account screen say Profile instead of Edit Profile

## 2026-09-02 — Delete account on Edit Profile

- Delete account is a danger tile on Edit Profile, not a Settings footer link

## 2026-09-02 — Add button sits lower

- The center Add disc sits slightly lower on the bottom bar

## 2026-09-02 — Settings hub restyle

- Settings is a profile hub: avatar, name, email, and an Edit Profile button
- Premium shows an ACTIVE / Upgrade card; Finance lists Transactions, Recurring, and Master Budget as separate rows
- Sign out, version, Privacy, Terms, and Delete account live on Settings
- Edit Profile opens a slimmer Account page with display name editing and a coming-soon change-email row

## 2026-09-02 — Shell bottom bar

- Signed-in tabs live in a shared bottom bar widget instead of layout inside the shell
- Page canvas and the bar use distinct Lush Growth fills
- Cards, quick-action tiles, and progress panels use the same olive muted fill
- Selected tab is a terracotta disc with a dark icon; Add sits on top of the bar without a strip above it

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
