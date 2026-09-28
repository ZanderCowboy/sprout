# Profile avatar (Supabase Storage) — #117

## Bucket

| Item | Value |
|------|-------|
| Bucket id | `avatars` |
| Public | **false** (private) |
| Object path | `{auth.uid()}/avatar.jpg` |
| Max object size | 2 MiB (Storage + app encode) |
| MIME | `image/jpeg`, `image/png`, `image/webp` |
| App metadata | `user_metadata.avatar_path` |

## Policies

Owner-only via `auth.uid()` on the first path folder:

- `select` / `insert` / `update` / `delete` for `authenticated` when `(storage.foldername(name))[1] = auth.uid()::text`

Migration: [`supabase/migrations/20260928164500_profile_avatars_storage.sql`](../supabase/migrations/20260928164500_profile_avatars_storage.sql). Apply to **both** Dev and Prod projects.

## App flow

1. Settings header avatar tap → action sheet (gallery / camera / remove when set).
2. Circular crop (`crop_your_image`) → resize long side ≤ 512px → JPEG ≤ ~2 MB.
3. Upload upsert to Storage; then set `avatar_path` in user metadata.
4. Display uses a signed URL (1h). Failures keep the prior avatar.

## Play brand mark (#112)

Official colourful Google Play prism SVG (Google product logo):

`sprout_app/assets/images/google_play_icon.svg`

Do not recolour to monochrome. Brand guidance: https://developer.android.com/distribute/marketing-tools/brand-guidelines
