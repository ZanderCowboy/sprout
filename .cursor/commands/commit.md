# Commit (AI-only)

Create a git commit. The human does not run git.

Arguments after `/commit` (optional):

$ARGUMENTS

## Parse arguments

From `$ARGUMENTS` and earlier messages in this conversation:

- **Exclude list** — paths/globs the user said not to commit (e.g. `skip X`, `exclude Y`, `don't commit Z`, `--skip …`). Treat those as hard skips.
- **Message hint** — remaining text may inform the commit message; do not use it verbatim unless it clearly *is* the message.
- If `$ARGUMENTS` is empty, commit all relevant changes **except** excludes from this turn/conversation and the hard skips below.

## Hard skips (never stage)

- Secrets and credentials: `.env`, `*.pem`, `**/google-services.json`, flavor JSON under `sprout_app/assets/config/`, service-account JSON under `config/`, keystores, anything that looks like a key
- Machine-local noise: `android/local.properties`, `.sprout-onedrive`
- User-requested excludes from `$ARGUMENTS` or this chat

If the only pending changes are hard-skipped / user-excluded, **do not** create an empty commit — say what was left out and stop.

## Do this

1. In parallel:
   - `git status`
   - `git diff` and `git diff --staged`
   - `git log -5 --oneline` (match repo message style)
2. Build the stage list: every modified/untracked file that belongs in this commit, **minus** hard skips and the user exclude list.
3. Draft a concise 1–2 sentence commit message focused on **why** (match existing style: short, imperative or descriptive as the log shows).
4. Stage only the allowed paths (`git add -- <paths>`). Never `git add -A` / `git add .` if that would pick up excludes.
5. Commit with a HEREDOC (or PowerShell here-string equivalent). On Windows PowerShell:

```powershell
git commit -m @"
Commit message here.

"@
```

6. `git status` after commit; report:
   - commit hash + subject
   - files committed
   - files **intentionally left uncommitted** (user excludes + hard skips)

## Safety

- Only run when the user invoked `/commit` (or explicitly asked to commit).
- Never update git config, `--no-verify`, force push, or amend unless the user explicitly asked **and** amend rules in the user commit protocol are all met.
- Never push unless the user asked to push.
- Warn and refuse to stage files that look like secrets even if the user listed them — say which and ask how to proceed.
