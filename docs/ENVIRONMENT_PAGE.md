# Environment page

Hidden QA / break-glass screen for **test-only** Settings controls. Normal product Settings stay clean on PROD.

## What lives here

- **Debug Lens** — open the existing Debug Lens panel (relocated from Settings → Debug tools)
- **Show debug bubble** — toggle the floating Debug Lens bubble (relocated from Settings)
- **Show update prompt** — preview the Play update bottom sheet
- **Show review prompt** — preview the Play review bottom sheet

### Flag split

| Concern | Flag | Notes |
|---------|------|--------|
| Environment page entry (gesture / DEV row) | `environment_page_enabled` | PROD default false; DEV always on |
| Debug Lens runtime + bubble + Lens rows on Environment | `debug_lens_enabled` | Unchanged; DEV always on. When false, Environment still shows soft-prompt previews |

See [`DEBUG_LENS.md`](DEBUG_LENS.md) for Lens/bubble RC setup. Soft-prompt previews are **not** gated by `debug_lens_enabled`.

## Entry

### Gesture (all flavors when gate allows)

Settings footer **App version** label (plain metadata under the Sprout title):

- **Long-press** alone, **or**
- **Double-tap** alone

Either gesture opens Environment. Incomplete / gate-off gestures are a **silent no-op** (no toast, snackbar, haptic, or copy).

### DEV day-to-day (no PROD break-glass needed)

- Development flavor: `shouldEnableEnvironmentPage()` is always **true** (no RC dependency).
- Settings also shows an **Environment** nav row in DEV only so you do not need the version gesture for daily QA.
- DEV also has `shouldEnableDebugLens()` always true, so Lens + bubble appear on Environment without PROD RC.

### PROD

- No permanent Settings section for Environment, Debug Lens, or bubble.
- Entry is gesture-only when `environment_page_enabled` is true (default false; enable via Firebase condition for break-glass).
- Lens/bubble rows on Environment additionally require `debug_lens_enabled` (or they stay hidden while soft prompts remain).

## Remote Config flag (page entry)

### Parameter

```
environment_page_enabled
```

Type: Boolean. **Do not** reuse `debug_lens_enabled`.

### Defaults

| Flavor | In-app default | Recommended Firebase default |
|--------|----------------|------------------------------|
| development | always on (flavor check) | optional; unused for gate |
| production | `false` | **`false`** |

### Firebase setup (PROD break-glass)

1. Open [Firebase Console](https://console.firebase.google.com) → project **sprout-app-production**
2. **Remote Config** → add or edit parameter:
   - **Key:** `environment_page_enabled`
   - **Type:** Boolean
   - **Default value:** `false`
3. Optional **condition** for break-glass (recommended):
   - e.g. **App version** `==` or `>=` a specific build you control
   - Conditional value: `true`
4. **Publish changes**
5. Cold-start the production app (or wait for the next RC fetch). Long-press or double-tap **App version** on Settings to open Environment.

To also use Debug Lens / bubble on that page in PROD, enable `debug_lens_enabled` the same way (see [`DEBUG_LENS.md`](DEBUG_LENS.md)).

Disable by setting the conditional / default back to `false` and publishing — no new build required.

## Code

- Gate: `shouldEnableEnvironmentPage()` in `lib/bootstrap.dart`
- Flag: `RemoteFeatureFlag.environmentPageEnabled`
- Page: `lib/features/settings/presentation/environment_page.dart`
- Route: `AppRoute.environment` (`/settings/environment`)
- Gesture: `SettingsFooter.onVersionEnvironmentEntry`
- Lens rows gated by `shouldEnableDebugLens()` inside Environment

## References

- Issue: [#114 Environment page](https://github.com/ZanderCowboy/sprout/issues/114)
- Debug Lens: [`DEBUG_LENS.md`](DEBUG_LENS.md)
