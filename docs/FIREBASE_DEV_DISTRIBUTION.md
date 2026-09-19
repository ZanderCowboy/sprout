# Firebase Dev Distribution (Android)

This repo uses GitHub Actions for:

- **CI Dev Checks** on every push: `flutter analyze` + `flutter test`
- **PR Version Labels** on PRs into `main`: require exactly one of `major` / `minor` / `patch` / `no-build`
- **Release Main** on merge to `main` (and manual dispatch): development APK → Firebase App Distribution **and** production AAB → Play internal, then commit the version

Versioning details: [BUILD_NUMBER.md](BUILD_NUMBER.md). Play details: [PLAY_PUBLISH_PROD_ANDROID.md](PLAY_PUBLISH_PROD_ANDROID.md).

Firebase upload is a job inside **Release Main**, not a separate workflow.

## Android flavors

| Flavor | applicationId | Entry point | Launcher name |
|--------|---------------|-------------|---------------|
| `development` | `app.stackmint.sprout.dev` | `lib/main_development.dart` | [DEV] Sprout |
| `production` | `app.stackmint.sprout` | `lib/main_production.dart` | Sprout |

Both can be installed on the same device. Only **development** uses Firebase App Distribution.

Local `firebase` commands in this workspace use a personal config directory. See [FIREBASE_CLI_PERSONAL.md](FIREBASE_CLI_PERSONAL.md).

## Firebase App Distribution prereqs (development)

1. In the **development** Firebase project, register the Android app with package `app.stackmint.sprout.dev`.
2. Download `google-services.json` and place it at `sprout_app/android/app/src/development/google-services.json` (gitignored).
3. Copy the Firebase App Distribution Android `appId` (format: `1:...:android:...`).
4. Create your Distribution groups (for example: `default`).
5. Create a service account key with the **Firebase App Distribution Admin** role.

## GitHub Secrets required (dev distribute)

Full inventory (all secrets, encode/`gh` restore): [GITHUB_SECRETS.md](GITHUB_SECRETS.md).

- `FIREBASE_APP_ID`: Firebase App Distribution Android appId (dev app)
- `FIREBASE_SERVICE_ACCOUNT_JSON`: the full private key JSON content (raw JSON string)
- `GOOGLE_SERVICES_DEV_BASE64`: base64-encoded `src/development/google-services.json`
- `APP_CONFIG_DEV_BASE64`: base64-encoded `sprout_app/assets/config/development.json`
- `ANDROID_SIGNING_CONFIG_BASE64`: base64-encoded JSON blob containing the keystore and credentials (optional for local testing; recommended for installable CI APKs)
- `VERSION_BOT_APP_ID` / `VERSION_BOT_APP_PRIVATE_KEY`: see [BUILD_NUMBER.md](BUILD_NUMBER.md)

## Android signing secret format

Encode a JSON object like this as base64, then store the result in `ANDROID_SIGNING_CONFIG_BASE64`:

```json
{
  "KEYSTORE_BASE64": "<base64 contents of release-key.jks>",
  "KEY_ALIAS": "your-key-alias",
  "KEY_PASSWORD": "your-key-password",
  "STORE_PASSWORD": "your-store-password"
}
```

Example command:

```bash
python3 - <<'PY'
import base64
import json
from pathlib import Path

payload = {
    "KEYSTORE_BASE64": base64.b64encode(Path("release-key.jks").read_bytes()).decode(),
    "KEY_ALIAS": "your-key-alias",
    "KEY_PASSWORD": "your-key-password",
    "STORE_PASSWORD": "your-store-password",
}

print(base64.b64encode(json.dumps(payload).encode()).decode())
PY
```

The workflow decodes this secret, recreates the keystore, and writes `android/key.properties` automatically.

## App config / google-services secret format

```bash
base64 -i sprout_app/assets/config/development.json | tr -d '\n'
base64 -i sprout_app/android/app/src/development/google-services.json | tr -d '\n'
```

If `APP_CONFIG_DEV_BASE64` is omitted, the workflow falls back to a placeholder config so the asset bundle still builds.

## How to ship

### Automatic (preferred)

1. Open a PR into `main` and add exactly one version label (`major`, `minor`, `patch`, or `no-build`).
2. Merge. **Release Main** builds the development APK with the new version and uploads it to Firebase group `default`. Release notes default to the PR title.

### Manual (retry / rebuild)

**Actions** → **Release Main** → **Run workflow**:

- `git_ref` — branch/tag/SHA (default `main`)
- `bump_type` — `none` / `patch` / `minor` / `major`
- `skip_play` — set true to only ship Firebase
- `commit_version` — set false with `bump_type: none` to rebuild without bumping
- `tester_groups`, `release_notes`

## Artifact path used

`sprout_app/build/app/outputs/flutter-apk/app-development-release.apk`

Build command (CI also passes `--build-name` / `--build-number`):

```bash
flutter build apk --release --flavor development -t lib/main_development.dart --no-tree-shake-icons
```
