# Changelog

## 0.1.28 — 2026-08-19

The ordinary working context is separated from the closed area (owner
ruling 2026-08-19): normal surfaces — the SessionStart contract, the spec /
accept / init / risk-profiles skills and every auto-loaded name and
description — carry only a neutral route, and the substantive instruction
moved into the new invoke-only `closed-area-gate` skill, which loads solely
in the dedicated, compatible, owner-armed session. The gate's verdict is
bound to the exact git SHA it reviewed and the profile it covered; accept
consumes the verdict by reference and blocks on a SHA mismatch.

- **Profile rename, one-way**: `auth-security` → `auth-boundary` (applies-to,
  mandatory verification, inventory and review columns unchanged). Migration:
  new and active change folders use `auth-boundary` from this version on;
  archived proposals keep the old name as history and are NOT rewritten; no
  alias is recognized — a proposal still carrying the old name gets it
  updated when the change is next touched, not by a sweep.
- risk-profiles: the review column is titled `closed-area review`; cell
  values are unchanged.
- accept step 5: the gate is dispatched to the dedicated session and its
  SHA-bound verdict is consumed by reference.
- init step 7: the opt-in continuous layer is offered by pointer; the
  concrete plugin name lives in `closed-area-gate`.
- `closed-area-gate` is manually invocable (`/flow:closed-area-gate`) and
  never model-invoked; the dedicated session arms its tooling via a
  temporary `--settings` CLI override while the machine-wide default stays
  off.
- session-context.sh: the domain-skills example list is neutral.
- dispatch-guard.py: docstring wording neutralized ("enforcement boundary").

## 0.1.27 — 2026-08-12

The cross-marketplace superpowers dependency is removed — it became the
prime suspect for the desktop drop and was already redundant.

Evidence: desktop 2.1.227 (auto-updated overnight) mounts
third-party-marketplace plugins again — a dependency-free third-party
plugin with hooks mounts fine, while flow, the only installed plugin
carrying a cross-marketplace `dependencies` entry, remains the sole
plugin counted but not mounted; the same binary run headless loads flow
in full. Cross-marketplace resolution has now caused three distinct
failure classes (unscoped-name resolution, the missing-allowlist
silent skip, this desktop mount drop), while the dependency's only
benefit — auto-installing superpowers — is covered three other ways:
the init superpowers check, the 0.1.25 session-start hook warning, and
the CLAUDE.md required-plugins line.

- plugin.json: `dependencies` removed.
- marketplace.json: `allowCrossMarketplaceDependenciesOn` removed (moot
  without the dependency).
- README: superpowers is installed explicitly, one line in the install
  block, with the rationale.

## 0.1.26 — 2026-08-11

Owner rule: a technology or domain is worked on together with its skill
(ClickHouse work → the ClickHouse skill, UX acceptance → design/UX
skills, and so on — where applicable).

- Session contract: a task touching a specific technology or domain
  checks the skill list and invokes the matching domain skill before
  working; a core project technology with no skill in the session is
  said out loud, never silently accepted.
- init: new Domain-skills step — map core technologies to skills, record
  installed ones in CLAUDE.md as required, offer official-marketplace
  installs for missing ones (owner decides), scaffold a project-local
  `.claude/skills/<tech>-practices` when the ecosystem has none.
- spec: a change that introduces a new technology brings the technology's
  skill in the same design — or records explicitly that none exists.
- accept: gates run with the applicable domain skills — design/UX and
  accessibility at live verification of ui-surface changes, performance
  skills for perf profiles, touched database/framework skills at code
  review; a profile calling for an absent skill is a finding.

## 0.1.25 — 2026-08-11

Skill wiring made explicit and partly deterministic (owner: sessions
kept skipping mandatory skills), plus corrected desktop-drop guidance.

- Hooks now enforce what prose kept losing, the same way superpowers
  guarantees its meta-rule: a SessionStart hook injects the flow session
  contract into every session where the plugin loads (lifecycle, the
  mandatory superpowers wiring, analyzers-in-DoD, commit/push and
  language rules; warns if superpowers looks missing); a dispatch-guard
  (PreToolUse on subagent dispatch + PostToolUse skill recorder) blocks
  the second dispatch of a session once when dispatching-parallel-agents
  was never invoked — fail-open, warn-once, git-guard philosophy, 13
  regression tests.
- implement: systematic-debugging is now a numbered mandate on any
  unexpected failure (guess-and-retry is a process violation), and
  verification-before-completion gates every task tick (fresh evidence,
  then checkbox).
- accept: reviewer findings are processed through receiving-code-review
  (verify claims technically, no performative agreement).
- spec, hardened after an audit against superpowers
  brainstorming/writing-plans (it replaces them by design and must not
  be weaker): tasks.md opens with a verbatim Global-constraints block;
  placeholder wordings ("TBD", "add appropriate error handling",
  "similar to task N") are named plan failures; self-review gains a
  requirement→task coverage check and a cross-task signature-consistency
  check.
- Desktop-drop guidance corrected. The 0.1.21 line "reinstall + app
  restart cures" no longer holds: current desktop builds (app 1.26832.x
  / CC 2.1.222) mount only official-marketplace local plugins into
  sessions and silently drop third-party ones, while the same binary run
  headless loads them fine — upstream anthropics/claude-code #27049,
  #39897, #41514, #39400. Template tells the owner the truth (terminal
  works, manual fallback in desktop); operational-lessons carries the
  full evidence chain, the PATH bin-mount diagnostic, and the workaround
  ladder including the #39400 zip-upload path. Note the honest limit:
  flow's own hooks fire only where flow loads — in a dropped desktop
  session only superpowers' hook is present.

## 0.1.24 — 2026-08-08

Owner rule wired into flow (it was already recorded in the owner's
project memory and discussed; sessions kept skipping it): multi-agent
and multi-session work runs under the superpowers
dispatching-parallel-agents discipline, with per-writer isolation.
Trigger: Batcher night cycles dispatched parallel work without the
skill; a shared tree split by file lists had already produced a defect.

- implement, Agent policy: any fan-out to 2+ agents or any
  multi-session batch (night cycles included) starts by invoking
  dispatching-parallel-agents — visibly, before the first dispatch;
  one agent per independent domain, self-contained prompts, independent
  verification (an agent's own success report is never evidence).
  Every writing agent gets its own worktree via the native mechanism
  (using-git-worktrees when available) — never one shared tree split by
  file lists; read-only researchers may share. Parallel sessions verify
  their branch/worktree before running gates or reporting them green.

## 0.1.23 — 2026-08-05

Rule refinement (owner): Russian is fine in local working docs —
untracked files and unpushed work — the English-artifacts rule binds at
push time. The accept sweep and the convention now say so: outgoing
non-English content is a push blocker unless the owner has explicitly
permitted it for that repo (permission recorded in the project's
CLAUDE.md); the fix is translate — or keep it local, dropped from the
push.

## 0.1.22 — 2026-08-05

Owner rule: nothing non-English reaches GitHub without explicit
permission. Trigger: a public consumer repo had accumulated Russian
owner quotes in openspec artifacts and in pushed commit-message bodies —
the convention existed in this repo's docs but nothing enforced it in
consumer projects.

- accept: new English-artifacts sweep at the release checkpoint — before
  any push, outgoing tracked files and `git log origin/<branch>..HEAD`
  messages are scanned with a Unicode-aware matcher (byte-range grep
  classes false-positive on em-dashes/arrows). Public repos: blocker,
  translate first (owner quotes become English translations marked
  "translated"). Private repos: deliberately non-English docs are the
  owner's recorded call — flag once.
- conventions: the English-artifacts rule now states the permission
  requirement and the enforcement point.

## 0.1.21 — 2026-08-05

Owner rules: required plugins are verified at session start, and static
analyzers are part of every code project's definition of done.

- template: CLAUDE.md names the required plugins (flow + superpowers) and
  instructs sessions to surface missing /flow: skills to the owner before
  starting work — the desktop GUI is known to silently drop
  third-party-marketplace plugins (reinstall + app restart cures) — then
  fall back to the manual lifecycle shape.
- init: new static-analyzer step with a verified per-stack table
  (2026-08): Python ruff ≥0.16 via extend-select (a bare select opts out
  of the expanded defaults) + ruff format + pyright; JS/TS ESLint v10 /
  oxlint (type-aware stable 2026-07); Swift toolchain swift-format with a
  project-style .swift-format; PHP PHPStan with baseline ratchet; Go
  golangci-lint v2; Rust clippy; Shell shellcheck. Zero-install toolchain
  options rank first; configs codify the codebase's conventions, not the
  tool's defaults. Adoption is one owner-approved mechanical commit
  proven neutral by the full suite — landed on an idle line the owner
  names, never onto a branch other sessions are working — or a recorded
  no-growth baseline when instant-clean is not feasible.
- accept: gate 1 treats a code project with no analyzer wired as a gate
  finding (bootstrap gap to report), not business as usual.
- marketplace: allowCrossMarketplaceDependenciesOn now names
  claude-plugins-official — without the allowlist the cross-marketplace
  superpowers dependency does not auto-resolve, which matches the
  observed "superpowers missing from sessions" failure.

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
