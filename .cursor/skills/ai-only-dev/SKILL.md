---
name: ai-only-dev
description: >-
  Collaboration workflow for AI-only development where the human never edits
  code. Use when implementing features, fixing bugs, planning work, or when the
  user describes requirements and expects the agent to do all coding.
---

# AI-only development workflow

The human is product owner / tester only. The agent is the sole coder.

## Collaboration loop

1. **Clarify product intent** — ask only questions that change behavior, scope, or UX. Skip implementation how-tos.
2. **Plan briefly when needed** — trade-offs, files touched, risks. Get approval if the change is large or irreversible.
3. **Implement fully** — write/edit all code yourself. Run tooling yourself.
4. **Verify** — analyze, tests, or targeted checks as appropriate for the change.
5. **Hand back for human QA** — describe what to tap/verify on device; do not ask them to change code.

## What to ask the human

| Ask | Don't ask |
|-----|-----------|
| Desired behavior / acceptance criteria | "Can you update this file?" |
| Preference between product options | "Paste this diff" |
| Secrets / dashboard clicks only they can do | "Run build_runner" (run it yourself via melos) |
| Confirm destructive ops (force push, prod publish) | "Add the missing import" |

## Blocking

If blocked:

1. Finish every non-blocked piece.
2. List **Human action required** as a short numbered list (no code edits).
3. Resume automatically once they reply.

## Output style

- Summarize what you changed and how to verify on device.
- Do not dump "next steps for you to code".
- Optional follow-ups should be agent tasks the human can approve ("Want me to add tests / open a PR?").

## Related

- Always-on policy: `.cursor/rules/ai-only-development.mdc`
- Repo overview: `AGENTS.md`
