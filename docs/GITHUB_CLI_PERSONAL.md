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

`gh` reads `~/.config/gh` unless `GH_CONFIG_DIR` is set. A second config directory isolates **config files** (`config.yml`, `hosts.yml`). It does **not** isolate the macOS keyring token.

On macOS, `gh` stores OAuth tokens under keychain service `gh:github.com`, keyed by GitHub username. Work (`Zander-K`) and personal (`ZanderCowboy`) can both exist there. If `hosts.yml` says `user: ZanderCowboy` but the only token in the keyring is `Zander-K`, every API call still uses the work token.

`gh auth status` prints the **username from `hosts.yml`**, not who the token belongs to. It can say `Logged in … ZanderCowboy` while `gh api user` returns `Zander-K`. Treat status as a label check only.

### 1. Isolated config (outside the repo)

Directory: `~/.config/gh-zandercowboy`

Contains a normal `config.yml` (`git_protocol: ssh`). After a real personal login, `hosts.yml` lists `ZanderCowboy` **and** the keyring has a `gh:github.com` item whose account is `ZanderCowboy`. Do not commit this directory.

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

`! You were already logged in to this account` only means `hosts.yml` already named that user. It does **not** mean the token is personal. Always run the **Verify** API check after login.

SSH keys were already uploaded, so `--skip-ssh-key` avoids a second key prompt.

## Verify

Do **not** trust `gh auth status` for identity. Ask GitHub who the token is:

```bash
# This workspace / personal config — must print ZanderCowboy
gh api user --jq .login

# Default (work) — omit GH_CONFIG_DIR; must print Zander-K
env -u GH_CONFIG_DIR gh api user --jq .login
```

In a **new** Cursor terminal in this window, `echo $GH_CONFIG_DIR` (PowerShell: `$env:GH_CONFIG_DIR`) should be `~/.config/gh-zandercowboy`.

`gh auth status` can still be used as a quick “config dir is pointed at personal” check. If it says `ZanderCowboy` but `gh api user` says `Zander-K`, re-run the login command in section 3.

### If `gh secret list` returns 403

Typical message: `You must have repository read permissions or have the repository secrets fine-grained permission`.

That is the work token hitting a public repo it does not admin. `Zander-K` can clone `ZanderCowboy/sprout` but cannot list Actions secrets. Re-login as `ZanderCowboy`, then confirm `gh api user --jq .login` before listing secrets.

## Recreate on a new machine

1. Point `origin` at SSH. On the Mac (work + personal keys): `git@github.com-personal:ZanderCowboy/sprout.git` with the `Host github.com-personal` SSH alias. On Windows, if the only key already authenticates as `ZanderCowboy`, `git@github.com:ZanderCowboy/sprout.git` is enough.
2. Create `~/.config/gh-zandercowboy` and set `GH_CONFIG_DIR` in the workspace files above (Windows: `terminal.integrated.env.windows` + `%USERPROFILE%`).
3. Run the `gh auth login` command in the previous section as `ZanderCowboy`.
4. Confirm with `gh api user --jq .login` as in **Verify** (must print `ZanderCowboy`).
