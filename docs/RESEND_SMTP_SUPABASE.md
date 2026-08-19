# Resend + Supabase SMTP (email OTP)

Human console work only. No app code changes.

**Goal:** Supabase emails the 6-digit login code your app already asks for.

**Do this on the Supabase project you care about first** (right now: **dev**). Repeat later for prod with the same Resend account if you want.

---

## Plain English

1. Your app asks Supabase for a login code.
2. Supabase generates something like `123456`.
3. Supabase must **email** that code.
4. On Free tier, Supabase’s built-in mailer is limited and you often can’t customize the template.
5. **Resend** is a third-party email sending service. You create an account; they give you SMTP settings.
6. You paste those into Supabase **Custom SMTP**. Supabase then sends auth emails through Resend.
7. You edit the Magic link template so the email body includes `{{ .Token }}` (the 6-digit code).

You are **not** running a mail server. Resend is the server. Hostname `smtp.resend.com` is just Resend’s address.

**Skip for now:** Send Email hooks, Postgres functions, Edge Functions, Pro upgrade (unless you prefer paying instead of Resend).

---

## Checklist


| Done | Step                                              |
| ---- | ------------------------------------------------- |
|      | Resend account + API key                          |
|      | Domain added in Resend (`stackmint.app` or subdomain) |
|      | DNS records on GoDaddy (or Auto Configure)        |
|      | Domain shows **Verified** in Resend               |
|      | Custom SMTP filled in on **dev** Supabase         |
|      | Magic link template includes `{{ .Token }}`       |
|      | App: send code → inbox → enter 6 digits → signed in |


---

## 1. Create a Resend account

1. Go to [https://resend.com](https://resend.com) and sign up.
2. Open **API Keys** → **Create API Key**.
3. Copy the key somewhere safe (password manager).  
   That key is also the **SMTP password** later.

Do **not** commit the API key to git.

---

## 2. Add a sending domain in Resend

Resend will not send as `noreply@yourdomain` until they trust the domain via DNS.

1. In Resend → [Domains](https://resend.com/domains) → **Add Domain**.
2. Prefer a **subdomain** for sending reputation, e.g. `mail.stackmint.app` or `send.stackmint.app`.  
   Root `stackmint.app` also works for send-only; subdomain is safer if you ever enable receiving.
3. Region: leave default unless you have a reason to change it.
4. Resend shows DNS records (MX, TXT SPF, TXT DKIM). Keep that page open.

After the domain is verified, sender addresses like `noreply@mail.stackmint.app` (or whatever domain you verified) work without creating a mailbox.

---

## 3. GoDaddy DNS

Domain for Sprout: **`stackmint.app`** (registered at GoDaddy).

Official Resend guide: [Verify domain on GoDaddy](https://resend.com/docs/knowledge-base/godaddy).

### Option A — Auto Configure (easiest)

If Resend shows **Auto Configure** for GoDaddy:

1. On the Resend domain page, click **Auto Configure**.
2. Authorize Resend to update GoDaddy DNS.
3. Wait a few minutes → click **Verify** in Resend.
4. Skip to [section 4](#4-custom-smtp-in-supabase) when status is **Verified**.

Leave **Receiving** off unless you intentionally want Resend to receive mail for that domain (can conflict with existing MX / email hosting).

### Option B — Manual records

1. Log in to [GoDaddy](https://sso.godaddy.com).
2. Open **DNS** for `stackmint.app` (DNS management page).
3. Add the three **send** records Resend shows. Values below are **examples** — copy the real values from your Resend domain page.

#### Record 1 — MX (SPF / return path)

| GoDaddy field | What to enter |
| ------------- | ------------- |
| Type | `MX` |
| Name | `send` (not `send.stackmint.app`) |
| Value | Exactly what Resend shows (e.g. `feedback-smtp.us-east-1.amazonses.com`) |
| Priority | `10` (or `20`/`30` if `10` is already used) |
| TTL | `600` or default |

#### Record 2 — TXT (SPF)

| GoDaddy field | What to enter |
| ------------- | ------------- |
| Type | `TXT` |
| Name | `send` |
| Value | Exactly what Resend shows (e.g. `v=spf1 include:amazonses.com ~all`) |
| TTL | `600` or default |

#### Record 3 — TXT (DKIM)

| GoDaddy field | What to enter |
| ------------- | ------------- |
| Type | `TXT` |
| Name | `resend._domainkey` (not the full hostname) |
| Value | Entire value from Resend (long `p=…` string — do not truncate) |
| TTL | `600` or default |

### GoDaddy naming rule (most common mistake)

GoDaddy **auto-appends** `stackmint.app`.

- Resend may show name `send.stackmint.app` → in GoDaddy Name field type only **`send`**.
- Resend may show `resend._domainkey.stackmint.app` → type only **`resend._domainkey`**.
- If you verified a subdomain in Resend (e.g. `mail.stackmint.app`), names become like `send.mail` and `resend._domainkey.mail` — still **omit** `.stackmint.app`.

### Verify in Resend

1. Back in Resend → Domains → your domain → **Verify DNS Records**.
2. Often finishes in minutes; can take up to a few hours.
3. Wait until the domain is **Verified** before configuring Supabase SMTP with that From address.

### If verification fails

- Re-check Name fields (no doubled domain).
- Paste Value exactly (no extra quotes/spaces; full DKIM string).
- Confirm records under `send.…` not only on the root `@`.
- Optional check: [dns.email](https://dns.email) or:

```bash
nslookup -type=TXT resend._domainkey.stackmint.app
nslookup -type=TXT send.stackmint.app
nslookup -type=MX send.stackmint.app
```

(Adjust hostnames if you used a subdomain like `mail.stackmint.app`.)

More help: [Domain not verifying](https://resend.com/docs/knowledge-base/what-if-my-domain-is-not-verifying).

---

## 4. Custom SMTP in Supabase

**Where:** Supabase **dev** project → **Authentication** → **SMTP Settings** (sometimes under Email / Notifications).

Enable custom SMTP and fill:

| Field | Value |
| ----- | ----- |
| Sender email | e.g. `noreply@stackmint.app` or `noreply@mail.stackmint.app` (must match the **verified** Resend domain) |
| Sender name | e.g. `[DEV] Sprout` |
| Host | `smtp.resend.com` |
| Port | `465` |
| Username | `resend` |
| Password | your Resend **API key** |

You can also copy host/user/port from [Resend SMTP settings](https://resend.com/settings/smtp).

Save.

Resend + Supabase guide: [Send emails using Supabase with SMTP](https://resend.com/docs/send-with-supabase-smtp).

---

## 5. Magic link template (the OTP body)

**Where:** same Supabase project → **Authentication** → **Email Templates** → **Magic link**.

Custom SMTP unlocks editing this on Free tier. Email OTP uses this template (not a separate “OTP” template).

Do **not** include `{{ .ConfirmationURL }}` for v1 — the app only accepts the typed 6-digit code.

### Subject

```text
Your [DEV] Sprout login code is {{ .Token }}
```

That puts the digits in the inbox / lock-screen preview so they can type without opening the email. If you prefer the code only in the body:

```text
Your [DEV] Sprout login code
```

### Body (HTML)

Paste this into the **Body** field. Keep `{{ .Token }}` exactly as written (spaces around `.Token`).

```html
<div style="font-family: system-ui, -apple-system, Segoe UI, sans-serif; max-width: 480px; margin: 0 auto; color: #111827;">
  <p style="font-size: 16px; line-height: 1.5;">Enter this code in Sprout to sign in:</p>
  <p style="font-size: 32px; letter-spacing: 0.2em; font-weight: 700; margin: 24px 0;">{{ .Token }}</p>
  <p style="font-size: 14px; line-height: 1.5; color: #4b5563;">This code expires in about an hour. If you did not request it, you can ignore this email.</p>
  <p style="font-size: 12px; color: #9ca3af;">[DEV] Sprout · Stackmint</p>
</div>
```

Save the template.

---

## 6. Test in the app

1. Run **development** flavor.
2. Settings → **Account** → enter email → send code.
3. Open the inbox for that address (check spam).
4. Enter the 6 digits → should be signed in (email shown, Sign out available).

If the email never arrives: Resend dashboard → Logs / Emails, and Supabase → Logs → Auth.

---

## Prod later

When dev OTP works:

1. Same Resend domain/API key can be reused.
2. Enable Custom SMTP on the **prod** Supabase project with the same host/user/password.
3. Edit the **prod** Magic link template the same way (`{{ .Token }}`).
4. Prefer a dedicated sender if you like (`noreply@…` is fine for both).

---

## What you can ignore

| Thing | Why |
| ----- | --- |
| Send Email hook | Replaces templates; you write/deploy a function. Not needed for OTP. |
| Pro plan | Only needed if you want built-in mail + editable templates without Resend. |
| Google Sign-In | Does not use SMTP or email templates. |
| Creating a real mailbox `noreply@…` | Not required; Resend only needs DNS + a From address on the verified domain. |

---

## Related

- Auth console checklist: [SUPABASE_AUTH_TODOS.md](SUPABASE_AUTH_TODOS.md)
- Config shape: [supabase/README.md](../supabase/README.md)
