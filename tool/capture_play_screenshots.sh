#!/usr/bin/env bash
#
# Capture Play Store screenshots using Maestro on the production flavor.
#
# Usage:
#   ./tool/capture_play_screenshots.sh [device_class] [--device <adb_serial>]
#
# Arguments:
#   device_class - Optional. One of: phone (default), sevenInch, tenInch
#   --device      - Optional. ADB serial / Maestro device id (e.g. emulator-5554)
#
# Prerequisites:
#   - Production RELEASE APK installed (banner-free; see below)
#   - Device/emulator connected and running (CT-MAC-75: Pixel_10_Pro / emulator-5554)
#   - Maestro installed and available in PATH
#   - Human ready to enter email OTP when the flow pauses (or pass OTP_CODE)
#
# Before running (banner-free production release — required):
#   cd sprout_app
#   flutter build apk --release --flavor production -t lib/main_production.dart
#   flutter install --release --flavor production
#
# debug_lens bubble must stay off (PROD Remote Config default; toggle lives on
# the Environment page, not main Settings). Do not capture with the bubble visible.
#
# OTP:
#   Default = human pause on the verify screen (enter code on-device).
#   Optional fast-path: OTP_CODE=xxxxxx ./tool/capture_play_screenshots.sh
#

set -euo pipefail

# Configuration
DEVICE_CLASS="phone"
MAESTRO_DEVICE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
MAESTRO_DIR="$WORKSPACE_ROOT/.maestro"
FLOW_FILE="$MAESTRO_DIR/play-store-screenshots.yaml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    phone|sevenInch|tenInch)
      DEVICE_CLASS="$1"
      shift
      ;;
    --device)
      MAESTRO_DEVICE="${2:-}"
      if [[ -z "$MAESTRO_DEVICE" ]]; then
        echo "❌ ERROR: --device requires an ADB serial (e.g. emulator-5554)" >&2
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "❌ ERROR: Unknown argument '$1'" >&2
      echo "   Usage: $0 [phone|sevenInch|tenInch] [--device <adb_serial>]" >&2
      exit 1
      ;;
  esac
done

OUTPUT_DIR="$WORKSPACE_ROOT/store/play/screenshots/$DEVICE_CLASS"

case "$DEVICE_CLASS" in
  phone|sevenInch|tenInch)
    echo "📱 Capturing screenshots for device class: $DEVICE_CLASS"
    ;;
esac

if ! command -v maestro &> /dev/null; then
  echo "❌ ERROR: Maestro not found in PATH" >&2
  echo "   Install from: https://maestro.mobile.dev/getting-started/installing-maestro" >&2
  exit 1
fi

if [[ ! -f "$FLOW_FILE" ]]; then
  echo "❌ ERROR: Maestro flow not found at $FLOW_FILE" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo ""
echo "🔧 Running Maestro flow: play-store-screenshots.yaml"
echo "   App id: app.stackmint.sprout (production)"
echo "   Output directory: $OUTPUT_DIR"
if [[ -n "$MAESTRO_DEVICE" ]]; then
  echo "   Device: $MAESTRO_DEVICE"
fi
if [[ -n "${OTP_CODE:-}" ]]; then
  echo "   OTP: OTP_CODE fast-path"
else
  echo "   OTP: human pause — enter the 6-digit code on-device when verify appears"
fi
echo ""

cd "$WORKSPACE_ROOT"

MAESTRO_OUTPUT=$(mktemp)
trap "rm -f $MAESTRO_OUTPUT" EXIT

MAESTRO_ARGS=(test "$FLOW_FILE")
if [[ -n "$MAESTRO_DEVICE" ]]; then
  MAESTRO_ARGS=(test --device "$MAESTRO_DEVICE" "$FLOW_FILE")
fi

if maestro "${MAESTRO_ARGS[@]}" 2>&1 | tee "$MAESTRO_OUTPUT"; then
  echo ""
  echo "✅ Maestro flow completed successfully"

  MAESTRO_OUTPUT_DIR="$HOME/.maestro/tests"

  if [[ -d "$MAESTRO_OUTPUT_DIR" ]]; then
    LATEST_TEST_DIR=$(ls -td "$MAESTRO_OUTPUT_DIR"/*/ 2>/dev/null | head -1)

    if [[ -n "$LATEST_TEST_DIR" ]]; then
      echo ""
      echo "📸 Copying screenshots from $LATEST_TEST_DIR"

      COPIED_COUNT=0
      while IFS= read -r screenshot; do
        filename=$(basename "$screenshot")
        cp "$screenshot" "$OUTPUT_DIR/$filename"
        echo "   ✓ Copied $filename"
        COPIED_COUNT=$((COPIED_COUNT + 1))
      done < <(find "$LATEST_TEST_DIR" -name 'play-*.png' -type f)

      if [[ $COPIED_COUNT -gt 0 ]]; then
        echo ""
        echo "✅ Successfully copied $COPIED_COUNT screenshot(s) to:"
        echo "   $OUTPUT_DIR"
        echo ""
        echo "📋 Next steps:"
        echo "   1. Review screenshots in $OUTPUT_DIR (no DEV/PROD ribbon, no debug bubble)"
        echo "   2. Upload to Play Console: https://play.google.com/console (Zander only)"
        echo "   3. Repeat for other device classes if needed (sevenInch, tenInch)"
      else
        echo ""
        echo "⚠️  WARNING: No play-*.png screenshots found in $LATEST_TEST_DIR" >&2
        echo "   Check Maestro output above for errors" >&2
        exit 1
      fi
    else
      echo ""
      echo "⚠️  WARNING: No test directories found in $MAESTRO_OUTPUT_DIR" >&2
      exit 1
    fi
  else
    echo ""
    echo "⚠️  WARNING: Maestro output directory not found at $MAESTRO_OUTPUT_DIR" >&2
    exit 1
  fi
else
  echo ""
  echo "❌ ERROR: Maestro flow failed" >&2
  echo "   Check output above for details" >&2
  exit 1
fi
