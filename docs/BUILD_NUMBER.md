# Build number

Flutter version lives in [`sprout_app/pubspec.yaml`](../sprout_app/pubspec.yaml) as `version: x.y.z+N`.

- `x.y.z` is the user-facing version name — bump this by hand for a named release
- `N` is the Android `versionCode` (via `flutter.versionCode` in Gradle)

Every merge (or push) to `main` increments `N` and commits it with a GitHub App, same pattern as Multichoice.

## Workflow

**Bump Build Number** runs on push to `main` and on manual dispatch. It calls [`.github/actions/version-management`](../.github/actions/version-management/action.yml) with `bump_type: none` (build only).

The bot commits `Bump version to x.y.z+N [skip ci]`. `[skip ci]` stops the bump workflow from looping and skips **CI Dev Checks** on that commit.

Play / Firebase uploads read whatever `+N` is on the ref you build. Merge to `main` first so the published artifact has a unique, increasing `versionCode`.

## GitHub App secrets (required)

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
