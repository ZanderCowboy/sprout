# Firebase Dev Distribution (Android)

This repo uses GitHub Actions for:
- `CI Dev Checks` on every push: `flutter analyze` + `flutter test`
- `Firebase Distribute (Dev Android APK)` on manual trigger: builds a **dev APK** and uploads it to Firebase App Distribution

## Android package name (important)
The Android `applicationId` is configured in `sprout_app/android/app/build.gradle.kts` and defaults to `com.example.sprout`.

To override it (without code changes), set a secret named `ANDROID_APPLICATION_ID` in GitHub. The build will read it at runtime.

## Firebase App Distribution prereqs
1. In Firebase, open your project and register the Android app using the final `applicationId`.
2. Copy the Firebase App Distribution Android `appId` (format: `1:...:android:...`).
3. Create your Distribution groups (for example: `dev`).
4. Create a service account key with the **Firebase App Distribution Admin** role.

## GitHub Secrets required
Create the following repository secrets:
- `FIREBASE_APP_ID`: Firebase App Distribution Android appId
- `FIREBASE_SERVICE_ACCOUNT_JSON`: the full private key JSON content (raw JSON string)

Signing (used to produce installable APKs in CI):
- `ANDROID_SIGNING_CONFIG_BASE64`: base64-encoded JSON blob containing the keystore and credentials

Optional:
- `ANDROID_APPLICATION_ID`: overrides the Gradle `applicationId`/`namespace` at build time

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

## Manual workflow inputs
Go to **Actions** -> **Firebase Distribute (Dev Android APK)** -> **Run workflow**:
- `git_ref` (optional): branch/tag/commit SHA to build (default: current ref)
- `tester_groups`: comma-separated Firebase App Distribution groups
- `release_notes` (optional): release notes shown to testers

## Artifact path used
The workflow uploads:
`sprout_app/build/app/outputs/flutter-apk/app-release.apk`

If your Flutter/Gradle output path differs, update the workflow’s `file:` field accordingly.

