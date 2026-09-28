# Play Store Listing Assets

This directory contains assets for the Google Play Store listing.

## Contents

- **icon-512.png** — App icon (512×512 PNG)
- **feature-graphic-1024x500.png** — Feature graphic (1024×500 PNG, no alpha channel)
- **screenshots/** — Screenshot images organized by device class

## Generating Assets

### Icon and Feature Graphic

The icon and feature graphic are generated from the source branding assets in `docs/branding/`:

```bash
python3 tool/generate_play_assets.py
```

This script:
- Resizes `docs/branding/sprout-icon-selected-1024.png` to 512×512 for the Play Store icon
- Creates a 1024×500 feature graphic with "Sprout" text + icon on the left, and phone screenshots on the right (if available)

**Note**: The feature graphic works best after capturing phone screenshots. If screenshots are not found, the graphic falls back to text + icon only. Regenerate after running `./tool/capture_play_screenshots.sh phone` to include screenshots in the feature graphic.

To regenerate with different branding, modify `tool/generate_play_assets.py` or update the source icon.

## Capturing Screenshots

Screenshots are captured with Maestro on a **production release** build (banner-free) using real email OTP. Debug sign-in is gone (#101). Prefer the email OTP human-pause path; Google handoff is documented in `.maestro/shared/google-signin-handoff.yaml` for completeness.

### Flavor + bubble requirement (future recaptures)

| Requirement | Detail |
|-------------|--------|
| Flavor | **production** (`app.stackmint.sprout`) |
| Build mode | **release** — EnvironmentBanner hides only when `production && kReleaseMode`. Production **debug** still shows a PROD ribbon. |
| Install | `flutter build apk --release --flavor production -t lib/main_production.dart` then `flutter install --release --flavor production` |
| Debug Lens bubble | Must be **off** in every shot. PROD Remote Config defaults `debug_lens_enabled=false`; bubble toggle lives on the **Environment** page (#114), not main Settings. Do not reintroduce Debug Lens on Settings. |
| Auth | Real email OTP (`shared/email-otp-human-pause.yaml`). No debug / bypass auth. |

### Prerequisites

1. **Install Maestro** (if not already installed):
   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```

2. **Connect a device or start an emulator** (standing QA lock: CT-MAC-75 Pixel_10_Pro / `emulator-5554`):
   ```bash
   adb devices
   # Leave the emulator up for the whole capture
   emulator -avd Pixel_10_Pro
   ```

3. **Build and install the production release APK** (banner-free):
   ```bash
   cd sprout_app
   flutter build apk --release --flavor production -t lib/main_production.dart
   flutter install --release --flavor production
   ```

4. **OTP handoff**: be ready to enter the 6-digit code for `sprout.play.review@gmail.com` when Maestro reaches the verify screen (or pass `OTP_CODE=xxxxxx` for the optional fast-path).

### Running the Capture Script

From the workspace root:

```bash
# Phone screenshots on CT-MAC-75 standing emulator (human OTP pause)
./tool/capture_play_screenshots.sh phone --device emulator-5554

# Optional OTP fast-path
OTP_CODE=xxxxxx ./tool/capture_play_screenshots.sh phone --device emulator-5554

# Other device classes
./tool/capture_play_screenshots.sh sevenInch --device emulator-5554
./tool/capture_play_screenshots.sh tenInch --device emulator-5554
```

The script will:
1. Run `.maestro/play-store-screenshots.yaml` against `app.stackmint.sprout`
2. Pause for human OTP (unless `OTP_CODE` is set)
3. Complete the wizard and capture Overview, Goals, and Accounts
4. Copy `play-*.png` into `store/play/screenshots/<device_class>/`

### Manual Maestro Run

```bash
maestro test --device emulator-5554 .maestro/play-store-screenshots.yaml
# or
OTP_CODE=xxxxxx maestro test --device emulator-5554 .maestro/play-store-screenshots.yaml
```

Screenshots land in `~/.maestro/tests/<timestamp>/play-*.png`. Copy them into `screenshots/<device_class>/` (or use the capture script).

## Maestro Flow Details

`.maestro/play-store-screenshots.yaml`:
- Launches production app with clean state
- Real email OTP via `shared/email-otp-human-pause.yaml` (human pause by default; optional `OTP_CODE`)
- Completes the first-run wizard: "Cape Town trip" goal (R12 000), "EasyEquities TFSA" account, R2 500 deposit (`shared/complete-wizard-play.yaml`)
- Captures:
  - `play-overview.png`
  - `play-goals.png`
  - `play-accounts.png`
- Tagged `[play-store]` (excluded from default smoke / p1 runs)

Related shared subflows (#70):
- `shared/email-otp-human-pause.yaml` — email → request code → human OTP pause (or `OTP_CODE` fast-path)
- `shared/google-signin-handoff.yaml` — Google path with documented account-picker / consent handoffs Maestro cannot automate

DEV E2E flows stay on `app.stackmint.sprout.dev` + `shared/otp-signin-intro.yaml` (still require `OTP_CODE`).

## Uploading to Play Console

**Zander only** (PM / agents do not drive Play Console).

1. Navigate to [Google Play Console](https://play.google.com/console)
2. Select the Sprout app
3. Go to **Store presence** → **Main store listing**
4. Upload:
   - **App icon**: `icon-512.png`
   - **Feature graphic**: `feature-graphic-1024x500.png`
   - **Screenshots**: `screenshots/phone/` (required); `sevenInch/` / `tenInch/` optional

## Screenshot Requirements

Per Google Play Console:
- **Format**: PNG or JPEG
- **Minimum**: 2 screenshots per device class
- **Maximum**: 8 screenshots per device class
- **Dimensions**: 320px–3840px per side, aspect ratio 16:9 to 9:16
- **Phone screenshots**: Required
- **Tablet screenshots**: Optional but recommended

## Notes

- Existing PNGs under `screenshots/` may still be from an older DEV capture — replace after a production OTP handoff run on CT-MAC-75
- No DEV/PROD ribbon and no debug_lens bubble in listing shots
- Test data is consistent across captures for reproducible results
- Rebuild and reinstall the production **release** APK if UI changes before recapturing
- See `.cursor/rules/maestro.mdc` and `.maestro/README.md` for Maestro conventions
