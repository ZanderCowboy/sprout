#!/usr/bin/env bash
# Copy gitignored local config between this repo and a cloud folder (OneDrive).
# Never prints file contents. Skips machine-specific paths (SDK, build, IDE).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEST_NAME="sprout-local-config"
DEST_REL="Projects/$DEST_NAME"
MANIFEST_NAME="MANIFEST.txt"
ONEDRIVE_FILE=".sprout-onedrive"
DEST_FILE=".sprout-local-config-dir"

usage() {
  cat <<'EOF'
Usage:
  scripts/sync-local-config.sh export [--onedrive PATH] [--dest PATH]
  scripts/sync-local-config.sh import [--onedrive PATH] [--dest PATH]
  scripts/sync-local-config.sh status [--onedrive PATH] [--dest PATH]
  scripts/sync-local-config.sh set-onedrive PATH

Copies portable gitignored files (flavor JSON, google-services, signing, .secrets,
and repo-root config/) so another machine can run the app after a git clone.

Default dest is <OneDrive>/Projects/sprout-local-config

Override OneDrive root (recommended on Windows), first match wins:
  1. --onedrive PATH
  2. make ONEDRIVE=...  /  env SPROUT_ONEDRIVE_DIR
  3. gitignored .sprout-onedrive (one line; create with set-onedrive)
  4. Windows %OneDrive% / $OneDrive, then common Personal folders

Override the full dest folder instead:
  --dest PATH, DEST=..., SPROUT_LOCAL_CONFIG_DIR, or .sprout-local-config-dir

Windows (PowerShell, no Make):
  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 import -OneDrive "$env:OneDrive"
  powershell -ExecutionPolicy Bypass -File scripts\sync-local-config.ps1 set-onedrive -OneDrive "C:\Users\you\OneDrive"

Not copied (machine-specific):
  android/local.properties, .dart_tool, build/, .gradle, IDE caches
EOF
}

trim() {
  local p="$1"
  p="${p#"${p%%[![:space:]]*}"}"
  p="${p%"${p##*[![:space:]]}"}"
  printf '%s' "$p"
}

# Git Bash / make: accept C:\Users\... and quoted paths.
normalize_path() {
  local p
  p="$(trim "${1:-}")"
  [[ -z "$p" ]] && return 1
  p="${p#\"}"
  p="${p%\"}"
  p="${p#\'}"
  p="${p%\'}"
  p="${p//\\//}"
  if [[ "$p" == ~* ]]; then
    p="${p/#\~/$HOME}"
  fi
  printf '%s' "$p"
}

read_override_file() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(trim "$line")"
    [[ -z "$line" || "$line" == \#* ]] && continue
    normalize_path "$line"
    return 0
  done <"$file"
  return 1
}

dest_from_onedrive() {
  local root
  root="$(normalize_path "$1")"
  printf '%s/%s' "${root%/}" "$DEST_REL"
}

detect_dest() {
  local dest_override="${1:-}"
  local onedrive_override="${2:-}"

  if [[ -n "$dest_override" ]]; then
    normalize_path "$dest_override"
    return
  fi
  if [[ -n "${DEST:-}" ]]; then
    normalize_path "$DEST"
    return
  fi
  if [[ -n "${SPROUT_LOCAL_CONFIG_DIR:-}" ]]; then
    normalize_path "$SPROUT_LOCAL_CONFIG_DIR"
    return
  fi
  local file_dest
  if file_dest="$(read_override_file "$ROOT/$DEST_FILE")"; then
    printf '%s' "$file_dest"
    return
  fi

  if [[ -n "$onedrive_override" ]]; then
    dest_from_onedrive "$onedrive_override"
    return
  fi
  if [[ -n "${SPROUT_ONEDRIVE_DIR:-}" ]]; then
    dest_from_onedrive "$SPROUT_ONEDRIVE_DIR"
    return
  fi
  # Make ONEDRIVE=... — do not treat empty Windows %OneDrive% as a miss later.
  if [[ -n "${MAKE_ONEDRIVE:-}" ]]; then
    dest_from_onedrive "$MAKE_ONEDRIVE"
    return
  fi
  local file_od
  if file_od="$(read_override_file "$ROOT/$ONEDRIVE_FILE")"; then
    dest_from_onedrive "$file_od"
    return
  fi

  local roots=()
  [[ -n "${OneDrive:-}" ]] && roots+=("$(normalize_path "$OneDrive")")
  [[ -n "${USERPROFILE:-}" ]] && roots+=(
    "$(normalize_path "$USERPROFILE/OneDrive")"
    "$(normalize_path "$USERPROFILE/OneDrive - Personal")"
  )
  roots+=(
    "$HOME/Library/CloudStorage/OneDrive-Personal"
    "$HOME/OneDrive"
  )

  local root dest parent
  for root in "${roots[@]}"; do
    [[ -z "$root" ]] && continue
    dest="$(dest_from_onedrive "$root")"
    parent="$(dirname "$dest")"
    if [[ -d "$dest" || -d "$parent" || -d "$root" ]]; then
      printf '%s' "$dest"
      return
    fi
  done

  echo "Could not find OneDrive. Set it once:" >&2
  echo "  scripts/sync-local-config.sh set-onedrive \"C:/Users/you/OneDrive\"" >&2
  echo "Windows: scripts\\sync-local-config.ps1 set-onedrive -OneDrive \"C:\\Users\\you\\OneDrive\"" >&2
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
    echo "Point at this PC's OneDrive root (the folder that contains Projects/):" >&2
    echo "  scripts/sync-local-config.sh set-onedrive \"C:/Users/you/OneDrive\"" >&2
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
  if [[ -f "$ROOT/$ONEDRIVE_FILE" ]]; then
    echo "Override: $ONEDRIVE_FILE"
  fi
  if [[ -f "$ROOT/$DEST_FILE" ]]; then
    echo "Override: $DEST_FILE"
  fi
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
        if [[ -d "$ROOT/config" ]]; then
          find "$ROOT/config" -type f ! -name '.DS_Store' -print | sed "s|^$ROOT/||"
        fi
        if [[ -d "$dest/config" ]]; then
          find "$dest/config" -type f ! -name '.DS_Store' -print | sed "s|^$dest/||"
        fi
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

cmd_set_onedrive() {
  local root dest
  root="$(normalize_path "${1:-}")" || true
  if [[ -z "$root" ]]; then
    echo "Usage: scripts/sync-local-config.sh set-onedrive \"C:/Users/you/OneDrive\"" >&2
    exit 1
  fi
  printf '%s\n' "$root" >"$ROOT/$ONEDRIVE_FILE"
  dest="$(dest_from_onedrive "$root")"
  echo "Wrote $ONEDRIVE_FILE (gitignored)"
  echo "OneDrive: $root"
  echo "Dest:     $dest"
  if [[ ! -d "$root" ]]; then
    echo "Warning: that OneDrive folder does not exist on this machine yet." >&2
  fi
}

parse_and_run() {
  local action="${1:-}"
  shift || true

  if [[ "$action" == "set-onedrive" ]]; then
    cmd_set_onedrive "${1:-}"
    return
  fi

  local dest_override=""
  local onedrive_override=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --onedrive)
        onedrive_override="${2:-}"
        shift 2
        ;;
      --onedrive=*)
        onedrive_override="${1#--onedrive=}"
        shift
        ;;
      --dest)
        dest_override="${2:-}"
        shift 2
        ;;
      --dest=*)
        dest_override="${1#--dest=}"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
      *)
        dest_override="$1"
        shift
        ;;
    esac
  done

  case "$action" in
    export|import|status)
      local dest
      dest="$(detect_dest "$dest_override" "$onedrive_override")"
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

parse_and_run "$@"
