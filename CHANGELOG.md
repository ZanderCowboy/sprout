# Changelog

Changes heading to `main`. Newest entries at the top.

## 2026-09-12 — Wizard setup polish

- Goal, account, and deposit steps use the same icons and full color palette as the rest of the app
- Target and deposit errors clear when the field is emptied; deposits validate min R10 and the goal target
- Account and goal names must be readable (letters, numbers, spaces) instead of symbol soup
- Step 3 explains the optional first deposit; Allocate later is a checkbox under the amount
- Name errors wrap onto extra lines; the deposit hint sits in its own info banner
- Welcome toast uses dark contrast so the lime accent stays readable

## 2026-09-12 — Wizard redirect loop

- First-run users stay on the setup wizard instead of bouncing `/wizard` → Overview → `/wizard`

## 2026-09-12 — Flutter 3.41.4

- Project and CI pin Flutter **3.41.4** (Dart 3.11.1, DevTools 2.54.1)
- README shows version badges plus the prerequisites table

## 2026-09-12 — First-win setup wizard

- Fresh signup / first successful sign-in routes into 3-step wizard before Overview
- Step 1: Goal (name + target), Step 2: Account (name + color), Step 3: Deposit (amount to both)
- Skip exits immediately and persists — wizard never reappears
- Finish saves goal + account + deposit (amount > 0) and shows one-time "You're growing" toast
- Empty Overview CTAs reordered to goal → account → deposit

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
