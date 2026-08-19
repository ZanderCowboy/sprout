---
name: Expand terms markdown
overview: "Replace the placeholder Terms of Service with a plain-language, South Africa–oriented draft: Sprout is a tracker (not a bank), you own your financial decisions, and we do not waive rights South African law will not let us waive."
todos:
  - id: rewrite-terms
    content: Rewrite sprout_app/assets/legal/terms.md with the SA-oriented plain-language Terms draft
    status: completed
  - id: docs-rc-note
    content: Update SUPABASE_AUTH_TODOS.md §7 so bundled Terms is the current draft, not a placeholder
    status: completed
isProject: false
---

# Expand in-app Terms of Service

Replace the placeholder in [`sprout_app/assets/legal/terms.md`](sprout_app/assets/legal/terms.md) with a readable in-app draft. **This is not legal advice** and is not a substitute for a South African attorney before Play Store launch. The goal is an honest, CPA-aware starter that matches what Sprout actually does.

Operator (locked): **Stackmint** (trading name, no registered company yet), based in the Republic of South Africa. App name remains **Sprout**.

No Dart/UI changes. Tests load injected markdown, so they do not need to assert on the new wording. After ship, you still paste the same markdown into **dev** Firebase Remote Config `terms_of_service` ([docs/SUPABASE_AUTH_TODOS.md](docs/SUPABASE_AUTH_TODOS.md) §7) so online devices match the bundle.

## What South African law actually constrains here

Plain-language summary of the statutes that shape the draft (not a legal opinion):

- **Consumer Protection Act 68 of 2008 (CPA).** You cannot use terms that are unfair or that strip rights the CPA gives consumers. You **cannot** fully say “we take no responsibility for anything.” In particular, the CPA blocks excluding liability for death or personal injury caused by **gross negligence**, and you cannot contract out of the CPA itself. So the disclaimer will be: you are responsible for your money decisions; we are not liable for those choices **except where South African law does not allow that exclusion**.
- **Electronic Communications and Transactions Act 25 of 2002 (ECTA).** Electronic suppliers should identify themselves and how to be contacted. We will name Stackmint, say we are in South Africa, and give an email. We will **not** invent a street address or company registration number you do not have.
- **Protection of Personal Information Act 4 of 2013 (POPIA).** Short “Your information” section in the same file (there is no `privacy.md` yet). Stackmint is the responsible party for the personal information we process to run the app.
- **What Sprout is not (financial law).** We are not a bank (**Banks Act**), not a licensed financial services provider and we do not give advice (**FAIS Act**), and we are not a credit provider (**National Credit Act**). The app’s “accounts / deposits / portfolio” are **your records of your own money**, not deposits held with us.

Play purchases (when Premium is live) stay under **Google Play** billing/refund rules; we do not store card numbers.

## Document structure (markdown, `flutter_markdown`-friendly)

Keep headings, short paragraphs, and bullet lists. No tables. Include **Last updated: 19 August 2026**.

1. **Agreement** — Creating an account or signing in means you accept these Terms. Written in plain language; not legal advice.
2. **Who we are** — Sprout is operated by Stackmint, a trading name based in South Africa. Contact: `hello@stackmint.app` (change this on review if that inbox does not exist).
3. **What Sprout is** — Personal savings tracker: you log accounts, goals, and transactions (ZAR), optionally sync across devices. We do **not** hold, transfer, invest, or insure your money.
4. **Not a financial institution** — Explicit list: not a bank, FSP, credit provider, or payment institution; not financial, tax, or investment advice; in-app totals are records only.
5. **Your responsibility** — You are responsible for real-world saving/spending decisions, the accuracy of what you enter, and activity on your account. We are not responsible for outcomes of those actions, **except where SA law does not allow us to exclude that**.
6. **Your account** — Email OTP or Google; keep credentials safe; you must be 18+ (age of majority in SA) to agree to these Terms.
7. **Your information (POPIA)** — We store account identifiers (e.g. email, display name) and the savings data you enter so the app and sync can work. We do not sell your data. Processors you already use (Supabase, Firebase, Google sign-in, RevenueCat when enabled). You can delete your account in-app when that flow ships; until then, contact the email above.
8. **Premium** — Optional paid features via the store; store terms govern payment and refunds.
9. **Acceptable use** — Don’t abuse the service or other users’ data.
10. **Availability** — App provided as-is; sync and servers can fail; we do not guarantee uninterrupted service.
11. **Limitation of liability** — CPA carve-out (we do not exclude liability that South African law says we cannot exclude). Otherwise, no liability for indirect loss or for relying on the app as financial advice, to the extent permitted.
12. **Changes** — We may update Terms in-app (including via Remote Config). Continued use after an update means you accept the new Terms.
13. **Governing law** — Laws of the Republic of South Africa. These Terms do not limit mandatory rights under the CPA or other SA law. If a clause is unenforceable, the rest stays.

## Docs tweak

In [docs/SUPABASE_AUTH_TODOS.md](docs/SUPABASE_AUTH_TODOS.md) §7, drop “placeholder” language: the bundled file is the current Terms draft; RC paste is still required so fetched clients stay in sync.

## Out of scope

- Separate Privacy Policy page/asset (Play Console will want a public URL later).
- Registering a Pty Ltd, VAT number, or physical address.
- Lawyer review (recommended before production store listing).
- Dart, tests, or Firebase console (human pastes RC after this lands).

## Human check after implementation

1. Open Sign-in → Terms and read the new markdown on device.
2. Confirm `hello@stackmint.app` is the contact you want (or tell me a different address and I will update it).
3. Paste the same markdown into **dev** Firebase RC `terms_of_service` when you are ready.
