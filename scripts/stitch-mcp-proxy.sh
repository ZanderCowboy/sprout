#!/usr/bin/env bash
# Cursor MCP entrypoint for Stitch.
#
# @_davideast/stitch-mcp@0.9.0's `proxy` command does not read gcloud. It only
# accepts STITCH_API_KEY or STITCH_ACCESS_TOKEN. This wrapper mints a token from
# the isolated personal gcloud config and execs the proxy.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"
export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-${HOME}/.config/gcloud-personal}"
export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-sprout-app-development}"

if [[ ! -f "${CLOUDSDK_CONFIG}/application_default_credentials.json" ]]; then
  echo "Stitch MCP: missing ADC at ${CLOUDSDK_CONFIG}/application_default_credentials.json" >&2
  echo "In a Cursor terminal: export CLOUDSDK_CONFIG=\$HOME/.config/gcloud-personal && gcloud auth application-default login" >&2
  exit 1
fi

STITCH_ACCESS_TOKEN="$(gcloud auth application-default print-access-token)"
export STITCH_ACCESS_TOKEN

exec npx -y @_davideast/stitch-mcp@latest proxy "$@"
