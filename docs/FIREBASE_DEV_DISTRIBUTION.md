# Firebase Dev Distribution (Android)

This repo uses GitHub Actions for:
- `CI Dev Checks` on every push: `flutter analyze` + `flutter test`
- `Firebase Distribute (Dev Android APK)` on manual trigger: builds a **development** APK and uploads it to Firebase App Distribution

Production Play uploads are documented separately in [PLAY_PUBLISH_PROD_ANDROID.md](PLAY_PUBLISH_PROD_ANDROID.md).

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

- `FIREBASE_APP_ID`: Firebase App Distribution Android appId (dev app)
- `FIREBASE_SERVICE_ACCOUNT_JSON`: the full private key JSON content (raw JSON string)
- `GOOGLE_SERVICES_DEV_BASE64`: base64-encoded `src/development/google-services.json`
- `APP_CONFIG_DEV_BASE64`: base64-encoded `sprout_app/assets/config/development.json`
- `ANDROID_SIGNING_CONFIG_BASE64`: base64-encoded JSON blob containing the keystore and credentials (optional for local testing; recommended for installable CI APKs)

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

The workflow decodes this secret, recreates `android/release-key.jks`, and writes `android/key.properties` automatically.

## App config / google-services secret format

```bash
base64 -i sprout_app/assets/config/development.json | tr -d '\n'
base64 -i sprout_app/android/app/src/development/google-services.json | tr -d '\n'
```

If `APP_CONFIG_DEV_BASE64` is omitted, the workflow falls back to a placeholder config so the asset bundle still builds.

## Manual workflow inputs

Go to **Actions** → **Firebase Distribute (Dev Android APK)** → **Run workflow**:

- `git_ref` (optional): branch/tag/commit SHA to build (default: current ref)
- `tester_groups`: comma-separated Firebase App Distribution groups
- `release_notes` (optional): release notes shown to testers

## Artifact path used

The workflow uploads:

`sprout_app/build/app/outputs/flutter-apk/app-development-release.apk`

Build command:

```bash
flutter build apk --release --flavor development -t lib/main_development.dart --no-tree-shake-icons
```
