# Changelog

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
