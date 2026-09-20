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

Screenshots are captured automatically using Maestro flows on a connected device or emulator.

### Prerequisites

1. **Install Maestro** (if not already installed):
   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```

2. **Connect a device or start an emulator**:
   ```bash
   # List connected devices
   adb devices
   
   # Or start an emulator
   emulator -avd <your_avd_name>
   ```

3. **Build and install the development APK**:
   ```bash
   cd sprout_app
   flutter build apk --debug --flavor development -t lib/main_development.dart
   flutter install --debug --flavor development
   ```
   
   ⚠️ **Important**: The development flavor is required for debug sign-in. Production builds will not work with the Maestro screenshot flows.

### Running the Capture Script

From the workspace root:

```bash
# Capture phone screenshots (default)
./tool/capture_play_screenshots.sh

# Or specify device class explicitly
./tool/capture_play_screenshots.sh phone
./tool/capture_play_screenshots.sh sevenInch
./tool/capture_play_screenshots.sh tenInch
```

The script will:
1. Run the Maestro flow `.maestro/play-store-screenshots.yaml`
2. Capture screenshots of Overview, Goals, and Accounts screens with seeded data
3. Copy the screenshots to `store/play/screenshots/<device_class>/`

### Manual Maestro Run

You can also run the Maestro flow directly:

```bash
maestro test .maestro/play-store-screenshots.yaml
```

Screenshots will be saved to `~/.maestro/tests/<timestamp>/play-*.png`. You'll need to manually copy them to the appropriate `screenshots/<device_class>/` directory.

## Maestro Flow Details

The screenshot capture flow (`.maestro/play-store-screenshots.yaml`):
- Launches with clean state (no previous data)
- Uses debug sign-in to bypass authentication
- Completes the first-run wizard: "Cape Town trip" goal (R12 000), "EasyEquities TFSA" account, R2 500 deposit
- Captures three screenshots:
  - `play-overview.png` — Overview screen with progress summary
  - `play-goals.png` — Goals screen showing the wizard goal
  - `play-accounts.png` — Accounts screen showing the wizard account
- Tagged `[play-store]` to exclude from default smoke test runs

## Uploading to Play Console

1. Navigate to [Google Play Console](https://play.google.com/console)
2. Select the Sprout app
3. Go to **Store presence** → **Main store listing**
4. Upload the generated assets:
   - **App icon**: `icon-512.png`
   - **Feature graphic**: `feature-graphic-1024x500.png`
   - **Screenshots**: Files from `screenshots/phone/` (required), `screenshots/sevenInch/`, `screenshots/tenInch/` (optional)

## Screenshot Requirements

Per Google Play Console:
- **Format**: PNG or JPEG
- **Minimum**: 2 screenshots per device class
- **Maximum**: 8 screenshots per device class
- **Dimensions**: 320px–3840px per side, aspect ratio 16:9 to 9:16
- **Phone screenshots**: Required
- **Tablet screenshots**: Optional but recommended

## Known Gaps

**Banner-free builds**: Play Store listing screenshots should ideally use a banner-free build (production or debug with banner disabled) for a cleaner appearance. The current Maestro flow uses the development flavor with debug sign-in, which displays the "DEV" banner ribbon.

Issue [#70](https://github.com/ZanderCowboy/sprout/issues/70) tracks Maestro flows with real Google authentication and email OTP, which will enable screenshot capture on production builds without the development banner.

For now, screenshots captured with the current workflow will include the development banner. This is acceptable for initial Play Store setup, but should be replaced with banner-free screenshots before public launch.

## Notes

- Screenshots show **development flavor** only (production hides debug sign-in)
- Test data is consistent across captures for reproducible results
- Rebuild and reinstall the APK if any UI changes are made before capturing screenshots
- See `.cursor/rules/maestro.mdc` for more details on Maestro conventions
