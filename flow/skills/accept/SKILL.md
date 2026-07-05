---
name: accept
description: Acceptance gate before merge - full checks, live-app verification, plan-compliance review, risk-scaled code review, acceptance summary for the owner. Invoke only when the owner explicitly asks to accept or finalize a change (in any wording); never start it on your own initiative.
argument-hint: "[change-id]"
---

# Acceptance gate

Change: $ARGUMENTS (default: the single active change under
`openspec/changes/`).

Run the gates in order and collect evidence as you go. When a gate finds a
blocker: fix it, then rerun ONLY the affected check and the reviewer that
found the issue — no full re-review loops.

1. **Full project checks** — the commands from CLAUDE.md (tests, lint,
   typecheck, build). All must pass.
2. **Live verification (ui-surface changes)** — run /verify against the
   running app, walking the change's behavior inventory as the checklist.
3. **Plan compliance** — launch the plan-reviewer agent from the flow
   plugin with the change id; it reports gaps between the diff and the
   approved change.
4. **Code review** — run /code-review at the effort the change's risk
   profile prescribes (see the flow risk-profiles table).
5. **Security review** — run /security-review when the profile demands it.
6. **Acceptance summary** — report to the owner: what changed, evidence
   (test output, verify results, review findings), unresolved risks, and
   your recommendation. STOP — the owner decides.

After the owner accepts:

- finish the branch (use the superpowers finishing-a-development-branch
  skill when available: merge or PR per the owner's choice);
- archive the change: `openspec archive <id>` with the CLI, otherwise move
  the folder to `openspec/changes/archive/`;
- never commit or push without an explicit owner instruction.
