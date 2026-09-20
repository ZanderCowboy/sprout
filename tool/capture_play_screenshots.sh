#!/usr/bin/env bash
#
# Capture Play Store screenshots using Maestro
#
# Usage:
#   ./tool/capture_play_screenshots.sh [device_class]
#
# Arguments:
#   device_class - Optional. One of: phone (default), sevenInch, tenInch
#
# Prerequisites:
#   - Development APK must be built and installed (see below)
#   - Device/emulator must be connected and running
#   - Maestro must be installed and available in PATH
#
# Before running:
#   cd sprout_app
#   flutter build apk --debug --flavor development -t lib/main_development.dart
#   flutter install --debug --flavor development
#

set -euo pipefail

# Configuration
DEVICE_CLASS="${1:-phone}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
MAESTRO_DIR="$WORKSPACE_ROOT/.maestro"
OUTPUT_DIR="$WORKSPACE_ROOT/store/play/screenshots/$DEVICE_CLASS"
FLOW_FILE="$MAESTRO_DIR/play-store-screenshots.yaml"

# Validate device class
case "$DEVICE_CLASS" in
  phone|sevenInch|tenInch)
    echo "📱 Capturing screenshots for device class: $DEVICE_CLASS"
    ;;
  *)
    echo "❌ ERROR: Invalid device class '$DEVICE_CLASS'" >&2
    echo "   Valid options: phone, sevenInch, tenInch" >&2
    exit 1
    ;;
esac

# Check prerequisites
if ! command -v maestro &> /dev/null; then
  echo "❌ ERROR: Maestro not found in PATH" >&2
  echo "   Install from: https://maestro.mobile.dev/getting-started/installing-maestro" >&2
  exit 1
fi

if [[ ! -f "$FLOW_FILE" ]]; then
  echo "❌ ERROR: Maestro flow not found at $FLOW_FILE" >&2
  exit 1
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo ""
echo "🔧 Running Maestro flow: play-store-screenshots.yaml"
echo "   Output directory: $OUTPUT_DIR"
echo ""

# Run the Maestro flow
# Screenshots will be saved to ~/.maestro/tests/<timestamp>/
cd "$WORKSPACE_ROOT"

# Capture the test run timestamp by running maestro and capturing output
MAESTRO_OUTPUT=$(mktemp)
trap "rm -f $MAESTRO_OUTPUT" EXIT

if maestro test "$FLOW_FILE" 2>&1 | tee "$MAESTRO_OUTPUT"; then
  echo ""
  echo "✅ Maestro flow completed successfully"
  
  # Find the most recent test output directory
  MAESTRO_OUTPUT_DIR="$HOME/.maestro/tests"
  
  if [[ -d "$MAESTRO_OUTPUT_DIR" ]]; then
    # Get the most recent test directory
    LATEST_TEST_DIR=$(ls -td "$MAESTRO_OUTPUT_DIR"/*/ 2>/dev/null | head -1)
    
    if [[ -n "$LATEST_TEST_DIR" ]]; then
      echo ""
      echo "📸 Copying screenshots from $LATEST_TEST_DIR"
      
      # Find and copy all play-*.png files
      COPIED_COUNT=0
      for screenshot in "$LATEST_TEST_DIR"/play-*.png; do
        if [[ -f "$screenshot" ]]; then
          filename=$(basename "$screenshot")
          cp "$screenshot" "$OUTPUT_DIR/$filename"
          echo "   ✓ Copied $filename"
          ((COPIED_COUNT++))
        fi
      done
      
      if [[ $COPIED_COUNT -gt 0 ]]; then
        echo ""
        echo "✅ Successfully copied $COPIED_COUNT screenshot(s) to:"
        echo "   $OUTPUT_DIR"
        echo ""
        echo "📋 Next steps:"
        echo "   1. Review screenshots in $OUTPUT_DIR"
        echo "   2. Upload to Play Console: https://play.google.com/console"
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
