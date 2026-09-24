# GitHub Actions secrets

Canonical inventory for **ZanderCowboy/sprout**. Where each secret comes from, how to encode it, and how to restore it.

**Where they live:** GitHub → repo → **Settings → Secrets and variables → Actions**.

**Do not** commit secret values, keystores, PEMs, or service-account JSON. Local copies belong under gitignored paths (`sprout_app/assets/config/`, `…/google-services.json`, `/config/`, `.secrets`).

The Play review Google password is local only: `.secrets` key `PLAY_REVIEW_EMAIL` (see [PLAY_REVIEW_ACCESS.md](PLAY_REVIEW_ACCESS.md)). Do not add it here.

Related: local flavor files + OneDrive restore → [`.cursor/references/secrets.md`](../.cursor/references/secrets.md). Workflows: [FIREBASE_DEV_DISTRIBUTION.md](FIREBASE_DEV_DISTRIBUTION.md), [PLAY_PUBLISH_PROD_ANDROID.md](PLAY_PUBLISH_PROD_ANDROID.md), [BUILD_NUMBER.md](BUILD_NUMBER.md). Play review account setup: [PLAY_REVIEW_ACCESS.md](PLAY_REVIEW_ACCESS.md).

---

## Inventory

| Secret | Format | Used by | Source |
|--------|--------|---------|--------|
| `APP_CONFIG_DEV_BASE64` | base64 of file | Release Main → Firebase | `sprout_app/assets/config/development.json` |
| `GOOGLE_SERVICES_DEV_BASE64` | base64 of file | Release Main → Firebase | `sprout_app/android/app/src/development/google-services.json` |
| `FIREBASE_APP_ID` | plain string | Release Main → Firebase upload | Firebase App Distribution Android **App ID** (`1:…:android:…`) for `app.stackmint.sprout.dev` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | raw JSON | Release Main → Firebase upload | GCP SA key with **Firebase App Distribution Admin** |
| `APP_CONFIG_PROD_BASE64` | base64 of file | Release Main → Play | `sprout_app/assets/config/production.json` |
| `GOOGLE_SERVICES_PROD_BASE64` | base64 of file | Release Main → Play | `sprout_app/android/app/src/production/google-services.json` |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | raw JSON | Release Main → Play upload | GCP SA key invited in Play Console for `app.stackmint.sprout` |
| `ANDROID_SIGNING_CONFIG_BASE64` | base64 of JSON blob | Firebase + Play builds | Upload keystore + passwords (see below) |
| `VERSION_BOT_APP_ID` | plain number | Release Main / bump commit | GitHub App **App ID** |
| `VERSION_BOT_APP_PRIVATE_KEY` | raw PEM text | Release Main / bump commit | GitHub App private key `.pem` |

Legacy standalone workflows may still reference the same names; **Release Main** is the ship path.

---

## Set / update with `gh` (preferred)

Always use the personal CLI config, then confirm the **token** is personal (`gh auth status` is not enough):

```powershell
$env:GH_CONFIG_DIR = "$env:USERPROFILE\.config\gh-zandercowboy"
gh api user --jq .login   # must print ZanderCowboy
```

On macOS / zsh:

```bash
export GH_CONFIG_DIR="$HOME/.config/gh-zandercowboy"
gh api user --jq .login   # must print ZanderCowboy
```

If `gh secret list` returns 403 about “repository read permissions” / “secrets fine-grained permission”, the work token (`Zander-K`) is still in use. Re-login as in [GITHUB_CLI_PERSONAL.md](GITHUB_CLI_PERSONAL.md).

From repo root:

```powershell
# base64 file → secret (no newline)
python -c "import base64, pathlib; print(base64.b64encode(pathlib.Path(r'PATH\to\file').read_bytes()).decode(), end='')" | gh secret set SECRET_NAME --repo ZanderCowboy/sprout

# raw JSON or PEM file → secret
Get-Content -Raw "PATH\to\file.json" | gh secret set SECRET_NAME --repo ZanderCowboy/sprout

# plain string
"1:123:android:abc" | gh secret set FIREBASE_APP_ID --repo ZanderCowboy/sprout
```

List (names + update times only):

```powershell
gh secret list --repo ZanderCowboy/sprout
```

Never `echo` secret bodies into chat or commit history.

---

## Per secret

### `APP_CONFIG_DEV_BASE64` / `APP_CONFIG_PROD_BASE64`

- **What:** Flavor JSON the app loads at runtime (Supabase, Google Web client ID, Firebase options block, RevenueCat key, `androidApplicationId`).
- **Files:**
  - Dev → `sprout_app/assets/config/development.json`
  - Prod → `sprout_app/assets/config/production.json`
- **When to update:** After any change to that JSON (new Supabase keys, Firebase `appId`, Google Web client ID, etc.).
- **Encode + set:**

```powershell
python -c "import base64, pathlib; print(base64.b64encode(pathlib.Path(r'sprout_app/assets/config/development.json').read_bytes()).decode(), end='')" | gh secret set APP_CONFIG_DEV_BASE64 --repo ZanderCowboy/sprout
python -c "import base64, pathlib; print(base64.b64encode(pathlib.Path(r'sprout_app/assets/config/production.json').read_bytes()).decode(), end='')" | gh secret set APP_CONFIG_PROD_BASE64 --repo ZanderCowboy/sprout
```

- **Notes:**
  - Missing `APP_CONFIG_DEV_BASE64` → CI may write a **placeholder** config so the APK still builds (testers won’t get real Supabase/Firebase).
  - Empty `supabaseUrl` / keys → local-only mode in that build.
  - Prod Flutter Firebase needs the `firebase { … }` block filled from the **production** `google-services.json` client for `app.stackmint.sprout` (see [SUPABASE_AUTH_TODOS.md](SUPABASE_AUTH_TODOS.md) field map).

### `GOOGLE_SERVICES_DEV_BASE64` / `GOOGLE_SERVICES_PROD_BASE64`

- **What:** Android Gradle Firebase plugin config.
- **Files:**
  - Dev → `sprout_app/android/app/src/development/google-services.json` (package `app.stackmint.sprout.dev`)
  - Prod → `sprout_app/android/app/src/production/google-services.json` (package `app.stackmint.sprout`)
- **Note:** Only `development/res/` is committed to git. The `production/` folder is local-only (gitignored). Both flavor `google-services.json` files are gitignored and live directly under their flavor folder (not nested under `res/`).
- **When to update:** After re-downloading from Firebase (new Android app, package rename, project change).
- **Encode + set:**

```powershell
python -c "import base64, pathlib; print(base64.b64encode(pathlib.Path(r'sprout_app/android/app/src/development/google-services.json').read_bytes()).decode(), end='')" | gh secret set GOOGLE_SERVICES_DEV_BASE64 --repo ZanderCowboy/sprout
python -c "import base64, pathlib; print(base64.b64encode(pathlib.Path(r'sprout_app/android/app/src/production/google-services.json').read_bytes()).decode(), end='')" | gh secret set GOOGLE_SERVICES_PROD_BASE64 --repo ZanderCowboy/sprout
```

- **Recreate:** Firebase Console → project → Project settings → Android app → download `google-services.json` → replace the flavor file → re-encode.

### `FIREBASE_APP_ID`

- **What:** App Distribution target for the **development** Android app.
- **Value:** Same as `mobilesdk_app_id` / flavor JSON `firebase.appId` for `app.stackmint.sprout.dev` (form `1:…:android:…`).
- **When to update:** New Firebase Android app / package rename.
- **Set:** plain string via `gh secret set FIREBASE_APP_ID` (see above).

### `FIREBASE_SERVICE_ACCOUNT_JSON`

- **What:** Uploads the development APK to Firebase App Distribution.
- **Format:** **Raw** service account JSON (not base64).
- **Recreate:**
  1. GCP project linked to **sprout-app-development** (or the Firebase project’s GCP).
  2. Create a service account → **Keys → Add key → JSON**.
  3. Grant role **Firebase App Distribution Admin** (IAM on that project).
  4. Pipe the downloaded JSON into `gh secret set FIREBASE_SERVICE_ACCOUNT_JSON`.
- **When to update:** Key rotation / lost key (create a new key; disable the old one).

### `PLAY_STORE_SERVICE_ACCOUNT_JSON`

- **What:** Uploads the production AAB via Play Developer API.
- **Format:** **Raw** service account JSON (not base64).
- **Recreate (GCP):**
  1. GCP → **IAM → Service Accounts → Create** (skip Permissions; skip Principals with access).
  2. **Keys → Add key → JSON** → keep the file under gitignored `/config/` if you want a local copy.
  3. Enable **Google Play Android Developer API** on that GCP project.
- **Recreate (Play Console):**
  1. **Users and permissions → Invite new users** → paste the SA email (`…@….iam.gserviceaccount.com`).
  2. App access: **Sprout only** (`app.stackmint.sprout`).
  3. App permissions to enable:
     - View app information and download bulk reports (read-only)
     - Release apps to testing tracks
     - Release apps to production
     - Manage Play App Signing (if listed)
  4. Leave store listing / financial / reviews off.
- **Prereqs or uploads fail:** Play app exists; first AAB accepted (manual draft OK); upload keystore matches `ANDROID_SIGNING_CONFIG_BASE64`.
- **Set:**

```powershell
Get-Content -Raw "config\your-play-sa.json" | gh secret set PLAY_STORE_SERVICE_ACCOUNT_JSON --repo ZanderCowboy/sprout
```

### `ANDROID_SIGNING_CONFIG_BASE64`

- **What:** Release/upload keystore for both CI APK and Play AAB.
- **Format:** Base64 of a **JSON object** (not the `.jks` alone):

```json
{
  "KEYSTORE_BASE64": "<base64 of release-key.jks bytes>",
  "KEY_ALIAS": "your-key-alias",
  "KEY_PASSWORD": "your-key-password",
  "STORE_PASSWORD": "your-store-password"
}
```

- **Build helper** (adjust paths/passwords; do not commit output):

```python
import base64, json
from pathlib import Path

payload = {
    "KEYSTORE_BASE64": base64.b64encode(Path("release-key.jks").read_bytes()).decode(),
    "KEY_ALIAS": "your-key-alias",
    "KEY_PASSWORD": "your-key-password",
    "STORE_PASSWORD": "your-store-password",
}
print(base64.b64encode(json.dumps(payload).encode()).decode(), end="")
```

Pipe that print into `gh secret set ANDROID_SIGNING_CONFIG_BASE64`.

- **When to update:** New upload keystore only (coordinate with Play App Signing / re-register upload key).
- **Restore:** Keep an offline backup of the `.jks` + passwords (OneDrive / password manager). Losing the upload key without Play reset is painful.

### `VERSION_BOT_APP_ID` / `VERSION_BOT_APP_PRIVATE_KEY`

- **What:** GitHub App that commits version bumps after a successful Release Main ship.
- **Full create steps:** [BUILD_NUMBER.md](BUILD_NUMBER.md).
- **Short:**
  - `VERSION_BOT_APP_ID` → numeric **App ID** (not Client ID).
  - `VERSION_BOT_APP_PRIVATE_KEY` → full PEM (`-----BEGIN …` through `END …`), raw, not base64.
- **When to update:** New private key generated on the App page; paste the new PEM and revoke the old key file.
- **Permissions on the App:** Contents Read and write; Metadata Read-only; install on `sprout`.

---

## Restore checklist (new machine / wiped secrets)

1. Restore local gitignored files via OneDrive (`make config-import` / [secrets reference](../.cursor/references/secrets.md)).
2. Re-set file-backed secrets from those local files (`APP_CONFIG_*`, `GOOGLE_SERVICES_*`).
3. Re-set `FIREBASE_APP_ID` from Firebase Console or `development.json` → `firebase.appId`.
4. Re-download or reuse offline copies of:
   - Firebase App Distribution SA → `FIREBASE_SERVICE_ACCOUNT_JSON`
   - Play upload SA → `PLAY_STORE_SERVICE_ACCOUNT_JSON`
   - Upload keystore → rebuild `ANDROID_SIGNING_CONFIG_BASE64`
   - Version Bot PEM → `VERSION_BOT_APP_PRIVATE_KEY` (+ App ID)
5. `gh secret list` and confirm all ten names are present.
6. Dry-run: Actions → **Release Main** → `skip_play: true` (Firebase only) then a Play run when ready.

---

## Quick “I changed X” map

| You changed… | Update secret(s) |
|--------------|------------------|
| `development.json` | `APP_CONFIG_DEV_BASE64` |
| `production.json` | `APP_CONFIG_PROD_BASE64` |
| Dev `google-services.json` | `GOOGLE_SERVICES_DEV_BASE64` (+ often `FIREBASE_APP_ID` + `APP_CONFIG_DEV_BASE64` firebase block) |
| Prod `google-services.json` | `GOOGLE_SERVICES_PROD_BASE64` (+ `APP_CONFIG_PROD_BASE64` firebase block) |
| Upload keystore / passwords | `ANDROID_SIGNING_CONFIG_BASE64` |
| Firebase Distro SA key | `FIREBASE_SERVICE_ACCOUNT_JSON` |
| Play API SA key | `PLAY_STORE_SERVICE_ACCOUNT_JSON` |
| Version Bot PEM | `VERSION_BOT_APP_PRIVATE_KEY` |
