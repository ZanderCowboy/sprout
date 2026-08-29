#!/usr/bin/env bash
# Copy gitignored local config between this repo and a cloud folder (OneDrive).
# Never prints file contents. Skips machine-specific paths (SDK, build, IDE).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEST_NAME="sprout-local-config"
MANIFEST_NAME="MANIFEST.txt"

usage() {
  cat <<'EOF'
Usage:
  scripts/sync-local-config.sh export [DEST]
  scripts/sync-local-config.sh import [DEST]
  scripts/sync-local-config.sh status [DEST]

Copies portable gitignored files (flavor JSON, google-services, signing, .secrets,
and repo-root config/) so another machine can run the app after a git clone.

DEST defaults to OneDrive Personal:
  ~/Library/CloudStorage/OneDrive-Personal/Projects/sprout-local-config
  ~/OneDrive/Projects/sprout-local-config
  $OneDrive/Projects/sprout-local-config

Override with DEST, or SPROUT_LOCAL_CONFIG_DIR.

Not copied (machine-specific):
  android/local.properties, .dart_tool, build/, .gradle, IDE caches
EOF
}

detect_dest() {
  if [[ -n "${1:-}" ]]; then
    printf '%s\n' "$1"
    return
  fi
  if [[ -n "${SPROUT_LOCAL_CONFIG_DIR:-}" ]]; then
    printf '%s\n' "$SPROUT_LOCAL_CONFIG_DIR"
    return
  fi

  local candidates=(
    "$HOME/Library/CloudStorage/OneDrive-Personal/Projects/$DEST_NAME"
    "$HOME/OneDrive/Projects/$DEST_NAME"
    "${OneDrive:-}/Projects/$DEST_NAME"
  )
  local c
  for c in "${candidates[@]}"; do
    [[ -z "$c" || "$c" == "/Projects/$DEST_NAME" ]] && continue
    local parent
    parent="$(dirname "$c")"
    if [[ -d "$parent" ]] || [[ -d "$(dirname "$parent")" ]]; then
      printf '%s\n' "$c"
      return
    fi
  done

  echo "Could not find OneDrive Personal. Pass DEST or set SPROUT_LOCAL_CONFIG_DIR." >&2
  exit 1
}

# Relative paths that must exist to run flavors / Android / release signing.
CORE_FILES=(
  sprout_app/assets/config/development.json
  sprout_app/assets/config/production.json
  sprout_app/android/app/src/development/google-services.json
  sprout_app/android/app/src/production/google-services.json
  sprout_app/android/key.properties
  sprout_app/android/app/release-key.p12
)

# Helpful extras; skipped quietly if missing.
EXTRA_FILES=(
  sprout_app/assets/config/development.md
  .secrets
)

is_skipped() {
  case "$1" in
    */local.properties|sprout_app/android/local.properties) return 0 ;;
    *) return 1 ;;
  esac
}

list_export_paths() {
  local f
  for f in "${CORE_FILES[@]}" "${EXTRA_FILES[@]}"; do
    if [[ -f "$ROOT/$f" ]]; then
      printf '%s\n' "$f"
    fi
  done
  if [[ -d "$ROOT/config" ]]; then
    find "$ROOT/config" -type f ! -name '.DS_Store' -print | sed "s|^$ROOT/||" | sort
  fi
}

copy_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp -p "$src" "$dest"
}

cmd_export() {
  local dest="$1"
  mkdir -p "$dest"
  local count=0
  local missing=()
  local f

  for f in "${CORE_FILES[@]}"; do
    if [[ ! -f "$ROOT/$f" ]]; then
      missing+=("$f")
    fi
  done

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    is_skipped "$f" && continue
    copy_file "$ROOT/$f" "$dest/$f"
    count=$((count + 1))
    echo "  exported  $f"
  done < <(list_export_paths)

  {
    echo "Sprout local config export"
    echo "exported_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "source_host=$(hostname)"
    echo "file_count=$count"
    echo
    list_export_paths
  } >"$dest/$MANIFEST_NAME"

  echo
  echo "Wrote $count files to $dest"
  if ((${#missing[@]} > 0)); then
    echo "Missing locally (not exported):"
    for f in "${missing[@]}"; do
      echo "  $f"
    done
  fi
}

cmd_import() {
  local dest="$1"
  if [[ ! -d "$dest" ]]; then
    echo "Export folder not found: $dest" >&2
    exit 1
  fi

  local count=0
  local f
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ "$f" == "$MANIFEST_NAME" ]] && continue
    is_skipped "$f" && continue
    if [[ -f "$dest/$f" ]]; then
      copy_file "$dest/$f" "$ROOT/$f"
      count=$((count + 1))
      echo "  imported  $f"
    fi
  done < <(
    if [[ -f "$dest/$MANIFEST_NAME" ]]; then
      awk 'NF && $0 !~ /^(Sprout |exported_|source_|file_count)/ {print}' "$dest/$MANIFEST_NAME"
    else
      find "$dest" -type f ! -name '.DS_Store' ! -name "$MANIFEST_NAME" -print \
        | sed "s|^$dest/||" | sort
    fi
  )

  echo
  echo "Imported $count files into $ROOT"
}

cmd_status() {
  local dest="$1"
  echo "Repo: $ROOT"
  echo "Dest: $dest"
  echo
  printf '%-10s %-10s %s\n' "LOCAL" "DEST" "PATH"
  local f
  for f in "${CORE_FILES[@]}" "${EXTRA_FILES[@]}"; do
    local loc="missing"
    local rem="missing"
    [[ -f "$ROOT/$f" ]] && loc="ok"
    [[ -f "$dest/$f" ]] && rem="ok"
    printf '%-10s %-10s %s\n' "$loc" "$rem" "$f"
  done
  if [[ -d "$ROOT/config" ]] || [[ -d "$dest/config" ]]; then
    echo
    echo "config/ extras:"
    local paths
    paths="$(
      {
        [[ -d "$ROOT/config" ]] && find "$ROOT/config" -type f ! -name '.DS_Store' -print | sed "s|^$ROOT/||"
        [[ -d "$dest/config" ]] && find "$dest/config" -type f ! -name '.DS_Store' -print | sed "s|^$dest/||"
      } | sort -u
    )"
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      local loc="missing"
      local rem="missing"
      [[ -f "$ROOT/$f" ]] && loc="ok"
      [[ -f "$dest/$f" ]] && rem="ok"
      printf '%-10s %-10s %s\n' "$loc" "$rem" "$f"
    done <<<"$paths"
  fi
}

main() {
  local action="${1:-}"
  shift || true
  case "$action" in
    export|import|status)
      local dest
      dest="$(detect_dest "${1:-}")"
      echo "$action → $dest"
      echo
      "cmd_$action" "$dest"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
