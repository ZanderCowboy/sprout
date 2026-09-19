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
3. **Commit** `Bump version to x.y.z+N [skip ci]` via Version Bot only after both uploads succeed

`[skip ci]` stops CI Dev Checks from re-running on the bot commit. The release workflow triggers on `pull_request` closed, not on the bot push.

Manual retries and one-offs use the same workflow’s **Run workflow** form (`bump_type`, `play_track`, `skip_firebase` / `skip_play`, `commit_version`). Prefer promoting the existing Play internal release in Play Console over rebuilding for production.

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
