---
name: accept
description: Acceptance gate before merge - full checks, live-app verification, plan-compliance review, risk-scaled code review, acceptance summary for the owner. Invoke only when the owner explicitly asks to accept or finalize a change (in any wording); never start it on your own initiative.
argument-hint: "[change-id]"
---

# Acceptance gate

Change: $ARGUMENTS (default: the single active change under
`openspec/changes/`).

Model/effort for this run are the owner's choice: when the session model
looks mismatched for gate-running (e.g., Fable), confirm with the owner
before gate 1 — default is Opus at session effort. The plan-reviewer agent
runs on Opus by default; the owner may request otherwise.

One checkout — one active session. Before starting, make sure the
implement session has committed its work and gone idle, and no stale app
servers from earlier runs are still bound to your ports (they serve wrong
data and produce phantom findings). If overlap is unavoidable, take a
separate git worktree. Findings fixed during acceptance — and any
owner-requested additions — are recorded in the change's inventory.md
("Owner acceptance refinements") before the summary.

Run the gates in order and collect evidence as you go. Reviewers start
late by design: the cheap deterministic gates (1-2) must pass before any
reviewer (3-5) runs — never burn review passes on code that fails tests.

When a gate finds a blocker: fix it, then rerun the affected checks and
the reviewer that found the issue. A broader re-review is legitimate when
the fixes were broad (shared code, many files) — say so explicitly and run
it. If acceptance is still not converging after two full review rounds,
stop and report to the owner with the reason: a change that cannot
converge usually has a spec or scope problem, and continuing versus
re-scoping is the owner's call.

Recurring owner feedback is a gate failure, not a reminder. When the
owner reports an issue class they have already corrected before (a style
rule, an invariant), do not just fix the instance: restate the rule in
the project's CLAUDE.md invariants as a general principle — a rule
recorded narrower than the owner's intent (e.g., scoped to one widget
type) regresses on every new surface — and add a deterministic check for
it to the project's verification walk or tests in the same acceptance
round.

1. **Full project checks** — the commands from CLAUDE.md (tests, lint,
   typecheck, build). All must pass.
2. **Live verification (ui-surface changes)** — run /verify against the
   running app, walking the change's behavior inventory as the checklist.
   Reuse and extend the project's verification walk script when one exists
   (e.g., `scripts/verify_walk.py`) instead of rebuilding it per
   acceptance; commit improvements back so the next acceptance starts
   warm. Scale the depth to the diff: exercise expensive pipelines (e.g.,
   a staged-install update cycle) only when the diff touches them.
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
  skill when available: merge or PR per the owner's choice). Release
  mechanics follow the project's recorded convention in CLAUDE.md (merge
  style, where the tag points, what gets archived); if none is recorded
  yet, derive it once from history and record it there as part of the
  release commit — the next release must not re-derive it;
- record the release in `CHANGELOG.md` (create the file on the first
  release): one entry per version — date, highlights, deferred and
  known-minor notes. Release history lives there and in
  `openspec/archive/`, never as CLAUDE.md narrative;
- refresh the CLAUDE.md `Current state` block instead of appending to it:
  replace the latest-release copy with the new CHANGELOG entry, update the
  open branches/tasks links, keep the pointers (`CHANGELOG.md`,
  `openspec/archive/`). One release visible at a time; closed items leave
  the list;
- guard CLAUDE.md leanness — the file loads into every session, so
  per-release history and long reference belong in CHANGELOG, archives, or
  docs/, not there. This guardrail outranks the recorded release
  convention: if the convention says to append release narrative to
  CLAUDE.md, amend the convention (one line, in the same release commit)
  instead of following it. When CLAUDE.md drifts past the project's
  recorded ceiling (default ~200 lines), prune history and narrative to
  CHANGELOG as part of the archive commit;
- archive the change: `openspec archive <id>` with the CLI, otherwise move
  the folder to `openspec/changes/archive/`;
- remind about local-only work (owner rule: WIP stays local within a
  version — GitHub carries finished versions, not drafts). At the release
  checkpoint, list what still lives only on this machine: unpushed
  branches, worktrees, untracked deliverables. Pushing any of it is the
  owner's per-release decision — never push it yourself;
- never commit or push without an explicit owner instruction.
