# Firebase CLI: personal account for this repo

Default `firebase` on this machine uses `~/.config/configstore/firebase-tools.json` (work or empty). Sprout’s Firebase projects are **personal**. This setup points **only this Cursor window / workspace** at a separate config directory. Other repos and terminals keep the default CLI login.

Do **not** run `firebase login:use` on the default config to switch accounts for Sprout. That changes the global default.

## Why `XDG_CONFIG_HOME`

The Firebase CLI has no `GH_CONFIG_DIR` equivalent. Auth lives in the [configstore](https://www.npmjs.com/package/configstore) file:

`$XDG_CONFIG_HOME/configstore/firebase-tools.json`

If `XDG_CONFIG_HOME` is unset, that is `~/.config/configstore/firebase-tools.json`.

Pointing `XDG_CONFIG_HOME` at a second directory isolates the personal login. Other XDG-aware CLIs in **this workspace’s terminals** also use that directory; `gh` is unaffected because `GH_CONFIG_DIR` is set separately. `gcloud` is unaffected because `CLOUDSDK_CONFIG` is set separately ([GCLOUD_CLI_PERSONAL.md](GCLOUD_CLI_PERSONAL.md)).

## Isolated config (outside the repo)

Directory: `~/.config/firebase-personal`

After login, contains `configstore/firebase-tools.json`. Do not commit this directory.

## Workspace env so this window uses it

Set in both:

- [`.vscode/settings.json`](../.vscode/settings.json)
- [`sprout.code-workspace`](../sprout.code-workspace)

```json
"terminal.integrated.env.osx": {
  "GH_CONFIG_DIR": "${env:HOME}/.config/gh-zandercowboy",
  "XDG_CONFIG_HOME": "${env:HOME}/.config/firebase-personal"
}
"terminal.integrated.env.windows": {
  "GH_CONFIG_DIR": "${env:USERPROFILE}/.config/gh-zandercowboy",
  "XDG_CONFIG_HOME": "${env:USERPROFILE}/.config/firebase-personal"
}
```

This overrides Firebase CLI config only in Cursor terminals for this workspace. User-level `firebase` (Terminal.app, other windows) is unchanged.

Open a **new** terminal after changing this. Existing terminals keep the old env.

Agent shells do not always inherit workspace terminal env. Before any `firebase` command they must export:

```bash
export XDG_CONFIG_HOME="$HOME/.config/firebase-personal"
```

That is also noted in [`AGENTS.md`](../AGENTS.md).

## One-time personal login

```bash
export XDG_CONFIG_HOME="$HOME/.config/firebase-personal"
mkdir -p "$XDG_CONFIG_HOME"
firebase login
```

Complete the browser flow **while signed in as the personal Google account** that owns Sprout’s Firebase projects (`sprout-app-development`, etc.), not the work account.

## Verify

```bash
# This workspace / personal config
XDG_CONFIG_HOME="$HOME/.config/firebase-personal" firebase login:list
# Expect: the personal Google account

# Default (work / other windows) — omit XDG_CONFIG_HOME
firebase login:list
```

In a **new** Cursor terminal in this window, `echo $XDG_CONFIG_HOME` should be `/Users/<you>/.config/firebase-personal` and plain `firebase login:list` should show the personal account.

## Recreate on a new machine

1. Create `~/.config/firebase-personal` and set `XDG_CONFIG_HOME` in the workspace files above.
2. Run the `firebase login` command in the previous section as the personal Google account.
3. Confirm with `firebase login:list` as in **Verify**.
