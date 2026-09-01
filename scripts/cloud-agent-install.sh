#!/usr/bin/env bash
# Cloud Agent install step for Sprout.
#
# Idempotent bootstrap run after the repository is checked out. It:
#   1. Creates the gitignored flavor config assets in "local-only" mode if they
#      are missing, so `flutter analyze` / `flutter test` can bundle the assets
#      declared in pubspec.yaml. Empty Supabase/RevenueCat/Firebase values mean
#      the app runs offline (Hive only) with sync and paid features skipped.
#   2. Runs `flutter pub get` for the Flutter package.
#
# Real Supabase/Firebase/RevenueCat credentials and google-services.json belong
# to the human (secrets) and are never written here. Existing files are left
# untouched so a machine with real config is not overwritten.
set -euo pipefail

# Cloud Agent install runs in a non-login shell that does not source
# /etc/profile.d or ~/.bashrc, so make the toolchain discoverable here.
export PATH="$PATH:/opt/flutter/bin:$HOME/android-sdk/cmdline-tools/latest/bin:$HOME/android-sdk/platform-tools:$HOME/android-sdk/emulator"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/sprout_app"
CONFIG_DIR="$APP_DIR/assets/config"

mkdir -p "$CONFIG_DIR"

write_local_config() {
  local path="$1"
  local android_app_id="$2"
  if [ -f "$path" ]; then
    echo "config: $path already exists, leaving untouched"
    return
  fi
  cat >"$path" <<EOF
{
  "supabaseUrl": "",
  "supabaseAnonKey": "",
  "androidApplicationId": "$android_app_id",
  "revenueCatAndroidApiKey": "",
  "firebase": {
    "apiKey": "",
    "appId": "",
    "messagingSenderId": "",
    "projectId": "",
    "storageBucket": ""
  }
}
EOF
  echo "config: wrote local-only placeholder $path"
}

write_local_config "$CONFIG_DIR/development.json" "app.stackmint.sprout.dev"
write_local_config "$CONFIG_DIR/production.json" "app.stackmint.sprout"

echo "flutter: pub get in $APP_DIR"
cd "$APP_DIR"
flutter pub get
