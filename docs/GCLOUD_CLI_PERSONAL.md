# gcloud: personal account for this repo

Default `gcloud` on this machine uses `~/.config/gcloud` (work or mixed). Sprout’s Google Cloud / Stitch / Firebase projects are **personal**. This setup points **only this Cursor window / workspace** at a second config directory. Other repos and terminals keep the default CLI login.

Do **not** run `gcloud config set project` or `gcloud auth login` against the default config to “switch” to Sprout. That changes the global default (and Application Default Credentials).

## Why `CLOUDSDK_CONFIG`

gcloud has no `GH_CONFIG_DIR`-style flag. Config, named configurations, and Application Default Credentials live under one directory:

`$CLOUDSDK_CONFIG` (default: `~/.config/gcloud`)

ADC from `gcloud auth application-default login` is written to `$CLOUDSDK_CONFIG/application_default_credentials.json`. The Stitch MCP proxy with `STITCH_USE_SYSTEM_GCLOUD=1` uses that same directory.

`XDG_CONFIG_HOME` (used here for Firebase) does **not** isolate gcloud. Set `CLOUDSDK_CONFIG` explicitly.

## Isolated config (outside the repo)

Directory: `~/.config/gcloud-personal`

Do not commit this directory.

## Workspace env so this window uses it

Set in both:

- [`.vscode/settings.json`](../.vscode/settings.json)
- [`sprout.code-workspace`](../sprout.code-workspace)

```json
"terminal.integrated.env.osx": {
  "CLOUDSDK_CONFIG": "${env:HOME}/.config/gcloud-personal"
}
"terminal.integrated.env.windows": {
  "CLOUDSDK_CONFIG": "${env:USERPROFILE}/.config/gcloud-personal"
}
```

This overrides gcloud only in Cursor terminals for this workspace. User-level `gcloud` (Terminal.app, other windows) is unchanged.

Open a **new** terminal after changing this. Existing terminals keep the old env.

Agent shells do not always inherit workspace terminal env. Before any `gcloud` command they must export:

```bash
export CLOUDSDK_CONFIG="$HOME/.config/gcloud-personal"
```

That is also noted in [`AGENTS.md`](../AGENTS.md).

Stitch MCP does not inherit terminal env. `.cursor/mcp.json` runs [`scripts/stitch-mcp-proxy.sh`](../scripts/stitch-mcp-proxy.sh), which sets `CLOUDSDK_CONFIG`, mints `STITCH_ACCESS_TOKEN` from ADC, and starts the proxy.

`@_davideast/stitch-mcp` **0.9.0** `proxy` ignores `STITCH_USE_SYSTEM_GCLOUD` and will exit with “requires an API key or access token” unless that wrapper (or `STITCH_API_KEY`) is used. Tokens last about an hour — refresh the Stitch MCP server in Cursor if tools disappear.

## One-time personal login

```bash
export CLOUDSDK_CONFIG="$HOME/.config/gcloud-personal"
mkdir -p "$CLOUDSDK_CONFIG"

gcloud auth login
gcloud config set project sprout-app-development
gcloud auth application-default login
gcloud auth application-default set-quota-project sprout-app-development
```

Complete the browser flows **while signed in as the personal Google account** that owns `sprout-app-development`, not the work account.

If you already logged into the **default** `~/.config/gcloud` by mistake, re-run the block above so credentials land in `gcloud-personal`. Then in a **work** terminal (no `CLOUDSDK_CONFIG`) restore work with `gcloud auth login` if that default was overwritten.

## Verify

```bash
# This workspace / personal config
CLOUDSDK_CONFIG="$HOME/.config/gcloud-personal" gcloud config get-value project
CLOUDSDK_CONFIG="$HOME/.config/gcloud-personal" gcloud config get-value account
# Expect: sprout-app-development and the personal Google account

# Default (work / other windows) — omit CLOUDSDK_CONFIG
gcloud config get-value project
```

In a **new** Cursor terminal in this window, `echo $CLOUDSDK_CONFIG` should be `/Users/<you>/.config/gcloud-personal`.

## Recreate on a new machine

1. Create `~/.config/gcloud-personal` and set `CLOUDSDK_CONFIG` in the workspace files above and in `.cursor/mcp.json`.
2. Run the login commands in the previous section as the personal Google account.
3. Confirm with **Verify**.
