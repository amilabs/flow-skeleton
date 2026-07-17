# Changelog

## 0.1.20 — 2026-07-16

Owner rule: WIP stays local within a version. GitHub carries finished
versions — research branches, worktrees, and drafts need not be pushed
until their iteration completes. accept now reminds at the release
checkpoint what is still local-only (unpushed branches, worktrees,
untracked deliverables); pushing is the owner's per-release decision.
Recorded in docs/conventions.md.

## 0.1.19 — 2026-07-16

Lean CLAUDE.md: release history moves to CHANGELOG.md (F1/F2 of the
2026-07-09 flow review, verified by the Fable pass). CLAUDE.md loads into
every session; on the review's flagship consumer, 18 releases of appended
narrative had grown it to 539 lines — 70% release history drowning the
standing instructions.

- accept: after the owner accepts, the release is recorded as a
  CHANGELOG.md entry (file created on first release); the CLAUDE.md
  `Current state` block is refreshed, never appended — a copy of the
  latest release entry, open branches/tasks as links, pointers to
  CHANGELOG/archives (shape set by the owner). A leanness guardrail
  outranks recorded release conventions: conventions that append release
  narrative to CLAUDE.md get a one-line amendment in the same release
  commit, and CLAUDE.md drifting past the project ceiling (default ~200
  lines) is pruned at the archive commit — this is what reaches projects
  whose conventions were derived and frozen before this version.
- init: new projects scaffold CHANGELOG.md and the bounded Current state
  block from day one; `--existing` migration bounds current-state notes to
  the same shape and offers moving accumulated history to CHANGELOG.md.
- template: the worktree bullet points work state at openspec/ +
  CHANGELOG.md instead of "this file carries everything".

## 0.1.18 — 2026-07-07

The spec phase scales its latitude to the model, over one unchanged
quality floor. Default stance (Opus/Sonnet/anything unrecognized): follow
the design path in order — the tested script. Fable-class stance (opt-in
by positive self-identification, so any misfire lands on the safe script):
the path items are mandatory outcomes, not a sequence — investigation-led,
depth follows risk, assumptions get challenged. Declarative controls: the
phase declares model/effort/stance up front, must flag a model↔change
weight mismatch in either direction before proceeding, and records
"Designed on:" in proposal.md and the approval summary (with
deviations-from-path noted under the Fable stance). Designed by a Fable
session executing the external Part 2 meta-task (project D of the
2026-07-09 review); proposal archived in that project's repo at
docs/analysis/FLOW-FABLE-DESIGN-PROPOSAL.md.

## 0.1.17 — 2026-07-07

Closing the owner-intent ↔ artifact gap, from a live acceptance incident
where reviewers passed a change the owner then faulted — every complaint
lived in what the artifacts didn't say, not in what reviewers missed.
Spec's behavior inventory now maps each shared control to every surface
it drives (acceptance verifies they move together), new surfaces near an
existing control must declare whether it affects them, and visualizations
record what data/period they reflect. The approval summary states the few
consequences that would otherwise surprise the owner in production — the
owner approves consequences, not just features. Accept treats recurring
owner feedback as a gate failure: the rule is restated as a general
principle in project invariants and gets a deterministic check in the
same round.

## 0.1.16 — 2026-07-06

Acceptance concurrency rules, from a real incident: one checkout — one
active session (implement must be committed and idle before accept
starts; stale app servers on shared ports produce phantom findings;
worktree if overlap is unavoidable). Acceptance-round fixes and
owner-requested additions are recorded in inventory.md before the summary.

## 0.1.15 — 2026-07-06

/flow:spec warns about bundle cost: changes past ~8 tasks get an explicit
hours-scale cost estimate and a split recommendation along a natural seam;
the owner decides. Phase duration follows bundle size — this makes the
trade-off visible at design time instead of surprising at implement time.

## 0.1.14 — 2026-07-06

Release mechanics follow the project's recorded convention in CLAUDE.md;
on the first release the convention is derived from history once and
recorded, so later releases stop re-deriving merge/tag/archive style.

## 0.1.13 — 2026-07-05

Acceptance cost control, from the first heavy real acceptance: the live
verification gate now reuses/extends a project-local walk script instead
of rebuilding one per run, and expensive pipelines are exercised only
when the diff touches them.

## 0.1.12 — 2026-07-05

Model/effort selection is confirmed with the owner instead of pinned
(supersedes 0.1.11): implement asks before starting (default Opus, Fable
offered for gnarly changes, effort selectable), accept asks only on a
mismatch, spec's Fable suggestion now mentions effort and the session-only
picker key. Skills direct the owner to /model when a switch is wanted —
a session cannot change its own model.

## 0.1.11 — 2026-07-05

/flow:implement and /flow:accept pin their turns to Opus via skill
frontmatter (model: opus) — running them from a Fable design session no
longer burns Fable pricing on execution turns. The override is per-turn
(session model returns after each owner message), so a fresh Opus session
remains the recommended pattern for long implementations; /flow:spec still
only suggests Fable, never forces it.

## 0.1.10 — 2026-07-05

/flow:init now offers the continuous security-guidance plugin for projects
with auth surfaces, payments, or public deployment (gate-level
/security-review via risk profiles remains the default for local-only
tools). CLAUDE.md template gains a plugin-less fallback: sessions without
flow (cloud VMs, fresh machines) still follow the lifecycle shape manually.

## 0.1.9 — 2026-07-05

Architecture bar in /flow:spec is now explicit and non-negotiable: units
with one purpose and well-defined interfaces; design.md is REQUIRED for
boundary-crossing changes (boundaries, exact interfaces, data flow, error
handling); multi-task changes state per-task consumes/produces. Review
re-run policy in /flow:accept reworded to the owner's actual rule: not
early (cheap gates first), re-runs allowed and announced when fixes were
broad, non-convergence after two full rounds escalates to the owner.

## 0.1.8 — 2026-07-05

/flow:spec regains the three strongest superpowers-brainstorming moves it
had silently dropped: decomposition check (multi-subsystem requests split
into separate changes), 2-3 alternative approaches with trade-offs before
settling, and a content self-review of the change folder before
validation. tasks.md entries now name the files they touch; proposal.md
records rejected alternatives. /flow:implement now requires a feature
branch — never main/master without explicit owner consent.

## 0.1.7 — 2026-07-05

Explicit superpowers boundary inside flow phases: /flow:spec IS the
brainstorming/design phase and tasks.md IS the plan — sessions must not
additionally invoke superpowers brainstorming / writing-plans /
executing-plans within a flow-managed change (duplicate artifact systems
otherwise). Superpowers execution disciplines (TDD, debugging,
verification, finishing-a-development-branch) remain in use from the flow
phases. Design spec §5 updated.

## 0.1.6 — 2026-07-05

CLAUDE.md template: sessions now explicitly offer /flow:spec (one line)
when the owner requests non-trivial work without mentioning flow, instead
of relying on the lifecycle rule being noticed.

## 0.1.5 — 2026-07-05

Lifecycle skills (spec, implement, accept, init) are model-invocable again:
`disable-model-invocation: true` removed them from the model's toolkit, so
prose instructions like "accept the change via /flow:accept" could not
trigger the skill (slash commands only expand at message start). The
explicit-owner-request rule moved into each skill's description; every
skill still stops at its internal owner gate. Found on the first real
/flow:accept run.

## 0.1.4 — 2026-07-05

git-guard: force-pushes addressed as `refs/heads/main` (including refspec
destinations like `HEAD:refs/heads/main`) are now blocked. Prefix-strip
only, so branches like `feature/main` stay unaffected. 23 regression tests.

## 0.1.3 — 2026-07-05

git-guard rewritten on python3 shlex (stdlib, fail-open without python3):
quote-aware tokenization ends the string-literal false positives — echoing
or committing text that mentions force-push commands is no longer blocked.
Also hardened: `+refspec` forced pushes to main/master, sudo/env/path-prefixed
git, and `git -C/-c` global options are now understood. 20 regression tests.

## 0.1.2 — 2026-07-05

Fix: git-guard no longer false-positives on compound commands. The
main/master and refspec checks now run per pipeline/list segment, so
`git push --force origin feature/x && git log main` is allowed while
`... && git push -f origin main` stays blocked. Found during real use.

## 0.1.1 — 2026-07-05

Fix: the superpowers dependency is now marketplace-scoped
(`superpowers@claude-plugins-official`). Bare dependency names resolve only
within the plugin's own marketplace, so 0.1.0 failed to load after install.

## 0.1.0 — 2026-07-05

Initial release: spec / implement / accept lifecycle skills, blast-radius
impact analysis, risk-profiles background knowledge, init bootstrap with
templates, plan-reviewer agent, git-guard hook.
