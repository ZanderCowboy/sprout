# Play Store review account

Test account for reviewers to access internal testing builds.

## Account details

- **Email:** `sprout.play.review@gmail.com`
- **Sign-in method:** Google only
- **2FA:** Disabled
- **Password:** Stored in password manager (not in git)

## Before submitting for review

Verify the review account can access and sign in on an Internal testing build:

1. Add `sprout.play.review@gmail.com` to the Play Console Internal testing track testers list.
2. Install the latest Internal build on a test device (from the Play Store Internal testing page).
3. Sign in using `sprout.play.review@gmail.com` + Google via the app's sign-in screen.
4. Confirm the account successfully authenticates and reaches the Overview screen.

## Security

- **Never commit** the account password, recovery codes, or other credentials to this repository.
- Manage credentials exclusively through your password manager or secure offline storage.

## Related

- Play Console publishing: [PLAY_PUBLISH_PROD_ANDROID.md](PLAY_PUBLISH_PROD_ANDROID.md)
- GitHub Actions secrets: [GITHUB_SECRETS.md](GITHUB_SECRETS.md)
