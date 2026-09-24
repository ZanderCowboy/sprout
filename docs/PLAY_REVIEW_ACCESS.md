# Play Store review account

Test account for reviewers to access internal testing builds.

## Account details

- **Email:** `sprout.play.review@gmail.com`
- **Sign-in method:** Google only
- **2FA:** Disabled
- **Password:** Gitignored `.secrets` key `PLAY_REVIEW_EMAIL` (never commit the value)

`.secrets` is a local `KEY=value` file at the repo root. It is listed in `.gitignore` and copied with other local config via `make config-export` / `make config-import`. It is **not** a GitHub Actions secret.

## Before submitting for review

Verify the review account can access and sign in on an Internal testing build:

1. Add `sprout.play.review@gmail.com` to the Play Console Internal testing track testers list.
2. Install the latest Internal build on a test device (from the Play Store Internal testing page).
3. Sign in using `sprout.play.review@gmail.com` + Google via the app's sign-in screen. Read the password from `.secrets` (`PLAY_REVIEW_EMAIL`); do not print it into chat, commits, or docs.
4. Confirm the account successfully authenticates and reaches the Overview screen.

## Security

- **Never commit** `.secrets`, the account password, recovery codes, or other credentials to this repository.
- Do not add `PLAY_REVIEW_EMAIL` to GitHub Actions secrets. Reviewers sign in on a device; CI does not need this value.

## Related

- Play Console publishing: [PLAY_PUBLISH_PROD_ANDROID.md](PLAY_PUBLISH_PROD_ANDROID.md)
- GitHub Actions secrets: [GITHUB_SECRETS.md](GITHUB_SECRETS.md)
- Local secrets map: [`.cursor/references/secrets.md`](../.cursor/references/secrets.md)
