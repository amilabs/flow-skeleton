# Design rationale (digest)

Why the plugin is shaped the way it is — the durable rationale, not the
dated log (that lives in
`docs/superpowers/specs/2026-07-05-flow-plugin-design.md`; versions in
`CHANGELOG.md`). Consumer projects are anonymized A–D as in
`docs/superpowers/reviews/`.

## Architecture — variant B, a thin plugin

Four layers, no duplication:

- **Claude Code** (native): plan mode, /code-review, /verify,
  /security-review, hooks, LSP, checkpoints, worktrees.
- **superpowers** (process): TDD, systematic-debugging, verification,
  finishing-a-development-branch.
- **OpenSpec** (artifacts): `specs/` = living behavior docs, `changes/` =
  proposal→design→tasks→archive. The CLI is optional — plain files
  first; CLIs/LSPs are accelerators, not dependencies.
- **flow** (the operating model): 6 skills (spec, implement, accept,
  blast-radius, init, risk-profiles), 1 agent (plan-reviewer,
  read-only), 1 git-guard hook. Budget 6/1/1 — growth only by removal.

The anti-pattern deliberately not reproduced (a predecessor project's
process-as-scars: 34 docs, 15 meta-scripts, review folders, 8 reviewer
roles): a pattern enters the plugin only after it appeared in real work.

## Key decisions

- **Fast path is mandatory**: one-sentence-diff changes with no
  dependents bypass the lifecycle (the `trivial` profile). When the
  expensive path is the only path, the process fights itself.
- **Models/effort are the owner's per-run choice**, not pinned. Sessions
  cannot switch their own model → skills direct to /model. Design on the
  strongest model; code/review on the workhorse.
- **Latitude scales with the model over one floor** (0.1.18): scripted
  default for Opus-class, outcome-led opt-in for Fable-class by positive
  self-identification, default-safe so misfires land on the script.
  Stance declared up front, model↔weight mismatches flagged both ways,
  "Designed on:" recorded in proposal.md and the approval summary.
- **Gates are soft**: skills advise; deterministic hooks only where
  failure is expensive; hard stop-gates are opt-in per project.
- **Design quality is not relaxed**: explicit architecture bar in spec;
  design.md is mandatory for boundary-crossing changes and for
  api-contract / data-storage / auth-security profiles;
  consumes/produces per task in multi-task changes.
- **Three brainstorming moves live inside spec** (they were being lost):
  decomposition check before the interview, 2–3 alternatives with
  tradeoffs before choosing, content self-review before validation.
  Bundles over ~8 tasks: spec prices the phases and offers a cut line;
  the owner decides.
- **Boundary with superpowers**: inside a flow change, spec IS the
  brainstorming phase and tasks.md IS the plan — their superpowers
  counterparts are not invoked (two artifact sets otherwise). Execution
  disciplines are invoked from flow phases. Outside flow, superpowers as
  usual.
- **Deliberate cuts** (owner-approved): full written plans → light
  tasks.md; subagent-per-task → one session + acceptance review; batched
  questions; one approval instead of per-section sign-offs.
- **Re-reviews at accept**: cheap deterministic gates run first;
  re-review is legitimate with explicit announcement when fixes were
  broad; non-convergence after two full rounds escalates to the owner
  (usually a spec/scope problem). Acceptance reuses the project's walk
  scripts; pipeline depth scales with the diff. One checkout — one
  active session (stale servers and parallel commits produce phantom
  findings).
- **Security layers**: gate-level /security-review is invoked from
  accept by risk profile; continuous security-guidance is an optional
  official plugin that init offers to projects with auth / payments /
  public deploys; supply-chain commands and secrets scanning
  deliberately live in project Commands/hooks, not in the plugin.
- **Acceptance verifies against artifacts**: post-acceptance owner
  complaints are almost always artifact gaps (intent ↔ letter), not
  reviewer misses — verified by dissecting a live incident. Hence: the
  behavior inventory maps each shared control to every surface it
  drives; new surfaces near a control declare whether it affects them;
  the approval summary states the few sharp consequences the owner would
  otherwise meet in production; recurring owner feedback is a gate
  failure → the rule is restated as a general principle in project
  invariants with a deterministic check in the same round.
- **Brownfield**: specs are created lazily — an area is documented at
  its first change, not the whole legacy up front. Regression shield:
  LSP diagnostics + blast-radius + characterization tests before the
  edit, /verify over the behavior inventory after.
- **Releases** follow the project's recorded convention in CLAUDE.md —
  derived once from history at the first release. Since 0.1.19 the
  leanness guardrail outranks the recorded convention: history goes to
  CHANGELOG.md, `Current state` stays a bounded status block.

Battle-tested: the full spec→implement→accept cycle shipped 18 releases
of the flagship consumer (project A); acceptance caught real bugs that
green tests had passed. Stack-agnostic by design (TS/React/Node, Python,
PHP, Vue — init detects).
