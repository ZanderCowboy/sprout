#!/usr/bin/env bash
# Local tests for resolve-version-labels.sh (run with bash).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/.github/scripts/resolve-version-labels.sh"
CONFIG="$ROOT/.github/config/version-labels.json"
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

read_out() {
  local key="$1"
  awk -v k="$key" '
    $0 ~ ("^" k "<<") { getline; print; exit }
  ' "$OUT"
}

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $name (expected='$expected' actual='$actual')"
    exit 1
  fi
  echo "PASS: $name"
}

run_ok() {
  local labels_json="$1"
  local mode="${2:-validate}"
  : > "$OUT"
  GITHUB_OUTPUT="$OUT" \
    LABELS_JSON="$labels_json" \
    CONFIG_PATH="$CONFIG" \
    TARGET_BRANCH=main \
    MODE="$mode" \
    bash "$SCRIPT" >/dev/null
}

run_fail() {
  local labels_json="$1"
  local mode="${2:-validate}"
  : > "$OUT"
  set +e
  GITHUB_OUTPUT="$OUT" \
    LABELS_JSON="$labels_json" \
    CONFIG_PATH="$CONFIG" \
    TARGET_BRANCH=main \
    MODE="$mode" \
    bash "$SCRIPT" >/dev/null 2>&1
  local exit_code=$?
  set -e
  echo "$exit_code"
}

run_ok '[{"name":"patch"}]'
assert_eq "patch bump_type" "patch" "$(read_out bump_type)"
assert_eq "patch valid" "true" "$(read_out valid)"

run_ok '[{"name":"major"}]'
assert_eq "major bump_type" "major" "$(read_out bump_type)"

run_ok '[{"name":"minor"}]'
assert_eq "minor bump_type" "minor" "$(read_out bump_type)"

run_ok '[{"name":"no-build"}]'
assert_eq "no-build bump_type" "none" "$(read_out bump_type)"
assert_eq "no-build valid" "true" "$(read_out valid)"

assert_eq "missing label exit" "1" "$(run_fail '[]')"
assert_eq "conflict exit" "1" "$(run_fail '[{"name":"major"},{"name":"patch"}]')"
assert_eq "no-build+patch exit" "1" "$(run_fail '[{"name":"no-build"},{"name":"patch"}]')"

# resolve mode with conflict picks major (highest tier) but valid=false
: > "$OUT"
set +e
GITHUB_OUTPUT="$OUT" \
  LABELS_JSON='[{"name":"major"},{"name":"patch"}]' \
  CONFIG_PATH="$CONFIG" \
  TARGET_BRANCH=main \
  MODE=resolve \
  bash "$SCRIPT" >/dev/null 2>&1
set -e
assert_eq "resolve conflict bump_type" "major" "$(read_out bump_type)"
assert_eq "resolve conflict valid" "false" "$(read_out valid)"

echo "All resolve-version-labels tests passed."
