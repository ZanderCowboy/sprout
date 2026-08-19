# Sprout app icon — creative brief

**Status:** Concept selected — not yet the app launcher  
**Date:** 2026-08-19  
**Audience:** Another AI creating the launcher icon (human review after)  
**Purpose:** Audit trail of the brief, generated concepts, and human selection.

## Decision log

| When | Who | Decision |
|---|---|---|
| 2026-08-19 | Brief | Commission a seedling-on-disc mark (teal `#0D9488`, lime `#BEF264`, slate `#0F172A`). |
| 2026-08-19 | Image AI | Returned a 3-up sheet: (1) seedling on disc, (2) leaf-in-circle, (3) sprout from split seed. |
| 2026-08-19 | Human | **Chose the top icon** — two-leaf seedling on a circular disc. |

Archived artwork:

- Full sheet: [`docs/branding/icon-sheet-2026-08-19.jpg`](branding/icon-sheet-2026-08-19.jpg)
- Selected crop, 1024×1024: [`docs/branding/sprout-icon-selected-1024.png`](branding/sprout-icon-selected-1024.png)

**Selected mark:** A two-leaf sapling from a thick circular disc (soil/coin). Teal-to-emerald leaves, lime highlight on the upper-right leaf tip, dark charcoal field. Soft 3D lighting, not flat vector. Not chosen: leaf-in-circle (bottom left) and cracked-seed sprout (bottom right).

Current Android launcher is still the default Flutter mark. Wiring this PNG into `mipmap/` is a separate step.

---

## Job

Generate a **mobile app launcher icon** for **Sprout**, a personal savings app.

Output a **single centered glyph** on a **square canvas**. Do not add the word “Sprout”, a slogan, a phone frame, or a mock home screen unless asked.

Produce **one hero concept** plus **two close variants** of that same idea (not three unrelated ideas).

---

## Product

**Name:** Sprout  
**One line:** Watch your money grow. Reach goals faster.  
**What it is:** A dark, premium personal-finance app for **savings, accounts, goals, and progress**. Users track money, set targets, and watch balances grow. South Africa / ZAR, but the icon must feel **global**, not local.

**Not:** a bank, crypto wallet, stock trader, tax tool, or kids’ piggy-bank toy.

---

## Brand personality

| Be | Don’t be |
|---|---|
| Calm, optimistic growth | Aggressive “get rich” |
| Premium, quiet, modern | Cute / cartoon / childish |
| Organic + precise | Generic fintech (dollar, chart, coin stack) |
| Dark, vivid, Material 3 | Neon cyber, glassmorphism overload |

Tone: a **seedling that is also a mark** — simple enough to read at 16×16 px, distinctive enough on a crowded home screen.

---

## Core metaphor

**A young sprout / seedling = money growing toward a goal.**

Best visual: one small plant pushing up, maybe from a round soil/coin/pot that reads as **wealth taking root**. Growth should feel **steady and alive**, not explosive.

Secondary (optional, only if it stays readable at small size): a hint of **upward progress** (a lift, a fold, a stem that also reads as a rising curve). Never a stock chart.

---

## Recommended concept (hero)

**Mark:** A single simplified seedling: two rounded cotyledon leaves + a short stem, rising from a small circular base.

**Base:** A flat disc that can read as **soil and a coin** at once — not a photoreal coin, not a piggy bank. Think a pebble or seed-pod with a faint inner ring.

**Leaves:** Soft, slightly asymmetric. One leaf slightly higher (growth, not a logo “S”).

**Background:** Solid dark slate, matching the app UI.

**Accent:** Teal stem/leaves; one small lime highlight on the newer leaf (the app’s FAB color). Keep it to one spark, not a rainbow.

This should look like a **modern app glyph**, not an illustration of a plant in a pot.

---

## Alternate concepts (only if the hero fails at small size)

1. **Leaf-in-circle:** One bold leaf inside a filled teal circle on the dark field. More logo-like, less “plant photo.”
2. **Sprout from a split seed:** A round seed cracking, one shoot up. Stronger “beginning” story. Keep the crack as 1–2 simple lines.

Do not combine all three. Pick one family and refine.

---

## Visual system (match the real app)

The app is **Material 3, dark mode**, rounded cards, circular FAB.

Palette from `sprout_app/lib/core/constants/app_colors.dart`:

| Role | Hex | Use |
|---|---|---|
| Primary / teal | `#0D9488` | Stem, main leaf, primary fill |
| Lime accent | `#BEF264` | One highlight (new growth, leaf tip, or small inner glow) |
| Deep surface | `#0F172A` | Background (preferred) |
| Sky (optional, tiny) | `#38BDF8` | Avoid unless a 2nd variant needs a cooler leaf |
| Violet (optional, tiny) | `#A78BFA` | Do not use on the icon unless a variant is explicitly “goals” |
| Coral | `#FF6B6B` | **Do not use** — error / env, not brand |

**Shape language:** Rounded, generous curves. No sharp spikes. No 3D chrome. Flat or very slight inner lighting (one light source from top-left). No drop shadows that look like they sit on a desk.

**Corners:** Design as a **full-bleed square**. iOS/Android will mask it (squircle / circle). Keep the glyph in the **center ~70–80%** so masking does not clip leaves or the base.

---

## App-icon constraints (non-negotiable)

- **Square, 1024×1024 px**, centered composition.
- **No text.** No “S”, no wordmark, no currency symbols (R, $, €).
- **No photorealism.** No grass photos, no 3D clay, no skeuomorphic coins.
- **No clutter.** One object. Max two colors on the glyph + the dark background.
- **Readable at small size.** If it fails as a 48×48 thumbnail, simplify.
- **Unique silhouette.** Must not look like Mint, Robinhood, Acorns, Forest, or a generic bank leaf.
- **Not the Flutter logo.** Current launcher is the default Flutter mark on black — replace that completely.
- **Safe for Android adaptive icons:** important detail in the center; no thin strokes at the edges.
- **Opaque background.** No transparency. Fill the square with `#0F172A` (or a close teal wash, never white).

---

## Style keywords

`flat vector app icon`, `Material 3`, `dark mode`, `geometric organic`, `soft rounded seedling`, `teal and lime on slate`, `premium fintech`, `high contrast glyph`, `centered`, `simple silhouette`, `no text`

## Negative keywords

`text, letters, wordmark, Flutter logo, dollar sign, pie chart, bar chart, bitcoin, piggy bank, cartoon, kawaii, 3D render, glassmorphism, neon, photoreal plant, white background, busy illustration, many leaves, tree, forest, gradient mesh, drop shadow, bevel, skeuomorphic coin`

---

## Ready-to-paste image prompt (hero)

> App icon, square 1024x1024, full-bleed. Solid dark slate background #0F172A. Centered flat vector mark: a simple young seedling with two soft rounded leaves and a short stem, growing from a small circular disc that reads as both a seed and a coin. Teal #0D9488 for stem and leaves. One small lime #BEF264 highlight on the upper leaf tip. Slightly asymmetric leaves, one a bit higher. Generous rounded shapes, Material 3, premium, calm, not cute. No text, no letters, no currency symbols, no charts, no piggy bank, no 3D, no shadows under the icon, no Flutter logo. High contrast, readable at small size, glyph occupies the center 75% of the canvas.

**Variant A — bolder / more logo:** same prompt, but “single bold leaf inside a filled teal circle, lime spark on the leaf, dark slate field.”

**Variant B — more story:** same prompt, but “round seed splitting with one shoot rising; crack is two simple curved lines; still flat vector.”

---

## What “done” looks like

The image AI should return:

1. **Hero icon** matching the seedling-on-disc concept.
2. **Two tight variants** of that same mark (e.g. more lime, simpler leaves).
3. Optionally a **true-black** (`#000000`) background version if the slate feels muddy on a home screen.

If only one image is possible: the hero prompt is enough.

---

## Human check after generation

Shrink to phone-icon size and ask:

- Does it still look like a **sprout**, not a blob or a tree?
- Is it obviously **not** a bank or a kids’ app?
- Does teal + lime on dark slate feel like the same product as a dark savings app?

If yes, it is ready to become the Android/iOS launcher.
