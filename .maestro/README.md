# Maestro flows (Sprout development flavor)

Root journeys live here; shared helpers are under `shared/` (not runnable alone). Workspace `config.yaml` discovers only root `*`.

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

Device: prefer a single emulator (Pixel_10_Pro / `emulator-5554` on CT-MAC). Pass `EMAIL` if not using the flow default `sprout.play.review@gmail.com`.

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
maestro test .maestro/   # all root journeys
```

See the repo root [README — Maestro UI Tests](../README.md#maestro-ui-tests-development-flavor-only) for prerequisites, OTP env vars, and semantic IDs.
