# Maestro flows (Sprout)

Root journeys live here; shared helpers are under `shared/` (not runnable alone). Workspace `config.yaml` discovers only root `*`.

**Default target**: development flavor (`app.stackmint.sprout.dev`).  
**Exception**: `play-store-screenshots.yaml` targets production (`app.stackmint.sprout`) for banner-free Play listing captures — see [store/play/README.md](../store/play/README.md).

## P1 standing smoke (ordinary PRs)

Ordinary PRs run **`--include-tags p1` only** (three flows):

| Flow | Why |
|------|-----|
| `full-app-tour.yaml` | Signed-in core pages tour |
| `otp-auto-submit.yaml` | Real OTP auth (wrong stays, right navigates) |
| `premium-free-paywalls.yaml` | Free Premium + Master Budget paywall dismiss |

```bash
# Needs live OTP for the review account (do not commit secrets)
OTP_CODE=xxxxxx maestro test .maestro/ --include-tags p1
```

Device: prefer a single emulator (Pixel_10_Pro / `emulator-5554` on CT-MAC).

## Maestro account split

- Subscribed/Premium flows default to `sprout.play.review@gmail.com`.
- Free/unsubscribed flows (paywalls, killswitch-on free, purchase-from-free, and the free full-app tour) default to `sprout.play.review+free@gmail.com`.
- The `+free` alias shares the Play Review inbox; retrieve its OTP through the play.review Gmail connector. Keep it as a separate app/RevenueCat identity and never clear RevenueCat between free and subscribed runs.
- Pass `EMAIL` to override a flow default when needed.

## Play Store screenshots (production)

```bash
# Install banner-free production release first (see store/play/README.md)
./tool/capture_play_screenshots.sh phone --device emulator-5554
# Human enters OTP on-device when verify appears (or pass OTP_CODE=xxxxxx)
```

Shared auth helpers for that path: `shared/email-otp-human-pause.yaml`, `shared/google-signin-handoff.yaml`, `shared/complete-wizard-play.yaml`.

## Full matrix

Run the **full** `.maestro/` suite (or broader tags such as `page` / `smoke` / `edge` / `premium` / `auth`) for:

- Auth changes (OTP, sign-in/out, Google)
- Premium / RevenueCat / kill-switch / paywall / purchase work
- Large regressions before release

Examples:

```bash
maestro test .maestro/ --include-tags smoke
maestro test .maestro/ --include-tags premium
OTP_CODE=xxxxxx OTP_CODE_REAUTH=yyyyyy maestro test .maestro/sign-out-keeps-data.yaml
maestro test .maestro/   # all root journeys (DEV app id on most flows)
```

See the repo root [README — Maestro UI Tests](../README.md#maestro-ui-tests-development-flavor-only) for prerequisites, OTP env vars, and semantic IDs.
