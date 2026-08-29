# GitHub CLI: personal account for this repo

Default `gh` on this machine is the **work** account (`Zander-K`). Sprout is a **personal** repo (`ZanderCowboy/sprout`). Git push already used the personal SSH key; `gh` (PRs, issues, `gh api`) did not, because CLI auth is a separate login from Git.

This setup points **only this Cursor window / workspace** at `ZanderCowboy`. Other repos and terminals keep `Zander-K`.

Do **not** run `gh auth switch --user ZanderCowboy` for this. That changes the global active account.

## What was already in place (Git)

| Piece | Value |
|-------|--------|
| Remote | `git@github.com-personal:ZanderCowboy/sprout.git` |
| SSH host alias (`~/.ssh/config`) | `Host github.com-personal` → `github.com` with `IdentityFile ~/.ssh/id_ed25519_personal` |
| Local Git identity | `user.name=ZanderCowboy`, `user.email=zanderkotze99@gmail.com` |

`ssh -T git@github.com-personal` should print `Hi ZanderCowboy!`.

Git and `gh` are independent: SSH can be personal while `gh` is still work.

## What was added (`gh`)

`gh` reads `~/.config/gh` unless `GH_CONFIG_DIR` is set. A second config directory isolates the personal login.

### 1. Isolated config (outside the repo)

Directory: `~/.config/gh-zandercowboy`

Contains a normal `config.yml` (`git_protocol: ssh`). After login, `hosts.yml` plus a macOS keyring entry for `ZanderCowboy`. Do not commit this directory.

### 2. Workspace env so this window uses it

Set in both:

- [`.vscode/settings.json`](../.vscode/settings.json)
- [`sprout.code-workspace`](../sprout.code-workspace)

```json
"terminal.integrated.env.osx": {
  "GH_CONFIG_DIR": "${env:HOME}/.config/gh-zandercowboy"
}
"terminal.integrated.env.windows": {
  "GH_CONFIG_DIR": "${env:USERPROFILE}/.config/gh-zandercowboy"
}
```

This overrides `gh` only in Cursor terminals for this workspace. User-level `gh` (Terminal.app, other windows) is unchanged.

Open a **new** terminal after changing this. Existing terminals keep the old env.

Agent shells do not always inherit workspace terminal env. Before any `gh` command they must export:

```bash
export GH_CONFIG_DIR="$HOME/.config/gh-zandercowboy"
```

That is also noted in [`AGENTS.md`](../AGENTS.md).

### 3. One-time personal login

```bash
export GH_CONFIG_DIR="$HOME/.config/gh-zandercowboy"
gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key
```

Complete the device flow in the browser **while signed in as ZanderCowboy**, not the work account.

SSH keys were already uploaded, so `--skip-ssh-key` avoids a second key prompt.

## Verify

```bash
# This workspace / personal config
GH_CONFIG_DIR="$HOME/.config/gh-zandercowboy" gh auth status
# Expect: Logged in to github.com account ZanderCowboy

# Default (work) — omit GH_CONFIG_DIR
gh auth status
# Expect: Logged in to github.com account Zander-K
```

In a **new** Cursor terminal in this window, `echo $GH_CONFIG_DIR` (PowerShell: `$env:GH_CONFIG_DIR`) should be `~/.config/gh-zandercowboy` and plain `gh auth status` should show `ZanderCowboy`.

## Recreate on a new machine

1. Point `origin` at SSH. On the Mac (work + personal keys): `git@github.com-personal:ZanderCowboy/sprout.git` with the `Host github.com-personal` SSH alias. On Windows, if the only key already authenticates as `ZanderCowboy`, `git@github.com:ZanderCowboy/sprout.git` is enough.
2. Create `~/.config/gh-zandercowboy` and set `GH_CONFIG_DIR` in the workspace files above (Windows: `terminal.integrated.env.windows` + `%USERPROFILE%`).
3. Run the `gh auth login` command in the previous section as `ZanderCowboy`.
4. Confirm with `gh auth status` as in **Verify**.
