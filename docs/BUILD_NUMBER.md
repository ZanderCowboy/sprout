# Build number and version labels

Flutter version lives in [`sprout_app/pubspec.yaml`](../sprout_app/pubspec.yaml) as `version: x.y.z+N`.

- `x.y.z` is the user-facing version name — bumped from PR labels on merge to `main`
- `N` is the Android `versionCode` (via `flutter.versionCode` in Gradle) — always increments with every release ship

## PR labels (required)

Every PR into `main` must have **exactly one** of:

| Label | Result (example from `1.0.0+2`) |
|-------|----------------------------------|
| `major` | `2.0.0+3` |
| `minor` | `1.1.0+3` |
| `patch` | `1.0.1+3` |
| `no-build` | No deploy, no version commit (docs/chore) |

Config: [`.github/config/version-labels.json`](../.github/config/version-labels.json).

**PR Version Labels** validates on open/sync/label. Add that check as a **required status check** on `main` so unlabeled PRs cannot merge.

## Release flow

**Release Main** (`.github/workflows/release-main.yml`) runs when a labeled PR merges into `main` (unless `no-build`):

1. **Compute** the next `x.y.z+N` (no commit yet)
2. **Ship in parallel** — development APK → Firebase App Distribution; production AAB → Play **internal**, both with `--build-name` / `--build-number`
3. **Commit** `Bump version to x.y.z+N [skip ci]` via Version Bot when **Play upload succeeds** (approach A / #94)

Play is the hard uniqueness store for Android `versionCode`. Commit Version therefore treats **Play success** as the commit trigger of record:

| Play job | Firebase job | Commit version? |
|----------|--------------|-----------------|
| success | success / failure / skipped | **Yes** — record the code Play accepted |
| skipped (`skip_play`) | success | **Yes** — existing skip_play path |
| failure | any | **No** — do not leave git ahead of Play |
| skipped | skipped / failure | **No** |

Firebase failure after a successful Play upload still **fails the overall workflow** (Firebase is not `continue-on-error`) so the APK issue surfaces, but the version commit proceeds so the next Release Main does not reuse a burned `versionCode`.

`[skip ci]` stops CI Dev Checks from re-running on the bot commit. The release workflow triggers on `pull_request` closed, not on the bot push.

Manual retries and one-offs use the same workflow’s **Run workflow** form (`bump_type`, `play_track`, `skip_firebase` / `skip_play`, `commit_version`). Prefer promoting the existing Play internal release in Play Console over rebuilding for production.

## Manual recovery: realign git with Play after a burned `versionCode`

If Play already accepted build `N` but `main` still shows a lower `+` build number (e.g. Commit Version was skipped on an older workflow, or a manual Play upload):

1. In Play Console → **App bundle explorer** (or the Internal track release), note the highest `versionCode` Play has accepted.
2. On `main`, set `sprout_app/pubspec.yaml` `version:` so the `+N` build number is **strictly greater** than that Play code (e.g. Play has 15 → commit at least `x.y.z+16`), or dispatch **Release Main** with `bump_type: patch` (or higher) and `commit_version: true` so Version Bot advances past Play.
3. If you only need to record the already-shipped code without another Play upload: commit the bumped `pubspec` on `main` (`Bump version to x.y.z+N [skip ci]`), or dispatch with `skip_play: true` only after git is already past Play’s max (otherwise a later Play upload can still collide).
4. Re-run Release Main only after git’s build number is ahead of Play’s highest accepted code.

## GitHub App secrets (required)

Full Actions secrets inventory: [GITHUB_SECRETS.md](GITHUB_SECRETS.md).

The default `GITHUB_TOKEN` cannot reliably push version commits. Workflows mint a short-lived installation token with [`peter-murray/workflow-application-token-action@v5`](https://github.com/peter-murray/workflow-application-token-action), then commit as **VersionBumpingBot**.

Add these repository secrets (**Settings → Secrets and variables → Actions**):

| Secret | Value |
|--------|--------|
| `VERSION_BOT_APP_ID` | Numeric **App ID** from the GitHub App page |
| `VERSION_BOT_APP_PRIVATE_KEY` | Full contents of the downloaded `.pem` |

`*.pem` is gitignored. Do not commit the key.

You can reuse Multichoice’s Version Bot app (install it on `sprout`) or create a new one.

### Create the app (if you do not already have one)

1. GitHub → **Settings → Developer settings → GitHub Apps → New GitHub App**
2. Name: e.g. `Sprout Version Bot`
3. Homepage URL: `https://github.com/ZanderCowboy/sprout`
4. Disable **Webhook**
5. Repository permissions: **Contents: Read and write**, **Metadata: Read-only**
6. Install on this account → only `sprout` (or all repos if you reuse it)
7. Copy the **App ID** (not the Client ID)
8. **Generate a private key** and paste the PEM into `VERSION_BOT_APP_PRIVATE_KEY`

If `main` later requires pull requests, add the app to the ruleset **bypass** list so it can push version commits.
