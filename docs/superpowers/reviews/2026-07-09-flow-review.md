# flow review — problems & improvements (2026-07-15)

Retrospective over the flow plugin (v0.1.0→v0.1.18) and its real use across
four consumer projects: **A** (the flagship — 18 releases v0.1→v0.18,
through 2026-07-09), **B** and **C** (small, few/no releases), and **D**
(the external Part 2 meta-task). Project names are anonymized per this
repo's standing rule against cross-project references (public repo); the
owner holds the mapping. Owner-initiated; done on Opus. Findings ranked by
impact.

> **Prepared for a later Fable review.** This doc is process/structure only —
> no crypto/security content that would trip Fable's classifier. Items that
> would need code-level security/crypto judgment are tagged
> `→ security/crypto pass` and NOT investigated here.

---

## F1 — CLAUDE.md grows unbounded; the release convention is the cause (HIGH)

**Symptom (owner-surfaced).** Project A's CLAUDE.md is **539 lines**; the
`Current state` section alone is **~380 lines (70%)** — a per-release
narrative dump (v0.7 … v0.18, each a paragraph). Project B is 36 lines,
project C 49. The whole 539 loads into context **every session**, diluting
the actual standing instructions (Commands/Architecture/Invariants/Workflow
sit in the first 160 lines, then drown).

**Root cause — a flow *gap* (missing guardrail), not a direct flow
instruction** (corrected 2026-07-15 after independent verification; the
first draft overstated this):
- `/flow:init` sets a ceiling: *"Keep it at or under 60 lines."*
- **flow's accept skill does NOT itself say "update Current state."**
  Re-verified 2026-07-15 (Fable): no `current state` wording anywhere in
  the accept skill. The full sentence (introduced 0.1.14; the earlier draft
  trimmed it) is: *"Release mechanics follow the project's recorded
  convention in CLAUDE.md (merge style, where the tag points, what gets
  archived); if none is recorded yet, derive it once from history and
  record it there as part of the release commit — the next release must
  not re-derive it."* The trimmed parenthetical matters: the convention
  hook is scoped to release *mechanics*; project A's step 2 ("update the
  CLAUDE.md Current state section") extended it into content maintenance
  on its own.
- The *"update the CLAUDE.md Current state section"* wording lives in
  **project A's own self-derived release convention** (its CLAUDE.md,
  step 2), not in the plugin. So flow didn't instruct the dump — it left
  the project free to derive an append-only convention and provided **no
  guardrail** against it (no standing "keep CLAUDE.md lean; history →
  CHANGELOG" rule to constrain the derived convention). The defect is the
  absence, not a command.
- Stronger provenance (Fable pass, 2026-07-15): the `Current state` section
  **predates the plugin entirely**. Project A's first CLAUDE.md — 94 lines,
  hand-written, `## Current state` already present — was committed the day
  before flow 0.1.0 shipped. `/flow:init` never generated that file, so the
  ≤60 ceiling never applied to it at all: the ceiling exists only in init's
  new-project path, and the `--existing` migration explicitly keeps
  "current-state notes" untouched.
- The freeze, however, is not passive (refined 2026-07-15). 0.1.14's
  mechanism — derive once, record, *"the next release must not re-derive
  it"* — took a habit three releases old (A's convention: *"Derived once
  from the v0.5–v0.7 releases; follow it verbatim for every version
  bump"*) and locked it in as permanent policy, with no quality filter on
  what got codified. flow didn't write the bad convention; flow's mechanism
  made it immune to revision. "Gap" slightly understates this: it is an
  **amplifier without a filter** — which is why the fix must re-validate
  already-recorded conventions (fix 5 below), not just guard new
  derivations.
- Result: for init-born projects the ≤60 ceiling is set at birth and never
  defended afterward; for pre-flow projects like A it never existed at all
  (corrected 2026-07-15). The self-derived convention appends every
  release: 18 releases → 380 lines of Current state.
- Note: **flow-skeleton keeps a `CHANGELOG.md` and has no bloated
  CLAUDE.md** (it has none at all). The plugin's own repo demonstrates the
  good pattern; the plugin just never exports it as a rule to consumers.

**Why it matters.** The official Claude Code best-practices docs
([code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices);
source located 2026-07-15 — the earlier draft's citation sentence was
garbled) say plainly: *"Bloated CLAUDE.md files cause Claude to ignore your
actual instructions"* — and put the adherence target at **under ~200
lines**. So this gap actively degrades every downstream project as
it matures — the most successful projects (most releases) get the worst
context dilution. Confirmed here: project A (18 releases) is 539 lines; B
and C (few/no releases) stay at 36–49.

**Fix (proposed, flow ~0.1.19):**
1. **Redirect release history to `CHANGELOG.md`.** The release convention
   should record each version as a `CHANGELOG.md` entry (what flow itself
   does), NOT a CLAUDE.md paragraph. Per-change full detail already lives in
   `openspec/archive/<id>/` — Current state paragraphs largely duplicate it.
2. **Bound `Current state` in CLAUDE.md.** It should carry only: the current
   version + branch, and pointers (`CHANGELOG.md`, `openspec/archive/`). At
   most the last release as a one-liner. Not an accumulating log.
3. **Defend leanness at release, not just at init** (reworded 2026-07-15:
   re-asserting a raw ≤60 is the wrong number — the official guidance is
   <~200 lines, and a mature project's legitimate standing content already
   runs ~160 here). Enforce the *structural* rule: `Current state` never
   accretes per-release entries; history goes to CHANGELOG; when CLAUDE.md
   drifts past the project's recorded ceiling (default ~200), prune as
   part of the archive commit.
4. **`/flow:init` scaffolds `CHANGELOG.md`** so there is a designated home
   for release history from day one. (Softened 2026-07-15: project A had
   no CHANGELOG, but per-change detail always had a home in
   `openspec/archive/` — what was missing is the release-*summary* layer,
   and that vacuum is what CLAUDE.md absorbed.)
5. **Accept must re-validate already-recorded conventions** (added
   2026-07-15 — without this the fix never reaches existing projects).
   0.1.14's *"the next release must not re-derive it"* makes every
   recorded convention immune to items 1–4: a project whose convention
   says "append to Current state" keeps appending forever, plugin update
   or not. The 0.1.19 guardrail must be checked at each release *against*
   the recorded convention; where they conflict, the guardrail wins and
   the convention gets a one-line amendment in the same release commit —
   that amendment is a mechanics change, exactly what the convention hook
   owns.
6. **Align the plugin's own latent wordings with the rule** (added
   2026-07-15). Two plugin lines currently bless the pattern: the
   `--existing` migration keeps "current-state notes" untouched, and the
   CLAUDE.md template's worktree bullet says "this file and openspec/
   carry everything". Neither caused this instance (project A predates
   both), but the first re-blesses dumps at migration and the second
   points session state at CLAUDE.md for every new project. Both should
   point at CHANGELOG/openspec instead, with current-state notes bounded
   the same way as item 2.

**One-time cleanup for project A** (separate, owner-approved): move the ~380
lines of Current state into `CHANGELOG.md`, collapse Current state to a
bounded pointer, **and rewrite the recorded release convention's step 2** to
log the version in CHANGELOG.md instead of appending a CLAUDE.md paragraph
(amended 2026-07-15 — moving the history alone regrows it at the very next
release). Purely editorial — no code, no behavior. Recommended as its own
trivial change.

---

## F2 — Multiple unbounded growth vectors into CLAUDE.md (MEDIUM)

Current state is the worst, but not the only one:
- **Invariants** grows every time 0.1.17's rule fires ("restate recurring
  owner feedback as a general principle in CLAUDE.md invariants"). This is
  legitimate — invariants ARE standing instructions — but has no size
  awareness either. Project A's Invariants block is already dense (money,
  currencies, migrations, UI) and correct; watch it doesn't accrete
  instance-level notes instead of general principles.
- **Architecture** naturally accretes as a project grows (project A's is
  now a wall of module descriptions). Fine in kind, but no periodic prune.

**Fix:** fold into F1's principle — flow should carry one explicit standing
rule: *CLAUDE.md is loaded every session; keep it lean; per-release history
and long reference go to CHANGELOG/archives/docs, not here; prune at
release.* One rule, referenced by both init and accept.

---

## F3 — Sessions largely went WELL; the scars are already captured (INFO)

The process worked at real scale: 18 project-A releases through
spec→implement→accept, project D's Part 2, and the plugin's own 18 versions —
all shipped. The accumulated operational friction (dependency scoping,
desktop spare processes, git-guard evolution, model fallback) is already in
memory (`flow-operational-lessons.md`) and mostly fixed in the plugin. No
new process defects surfaced beyond F1/F2. The one visible scar of scale is
exactly F1 — CLAUDE.md bloat is what 18 successful releases *look like* under
the current convention.

---

## Deferred to a security/crypto pass (not investigated here)

Project A's later releases carry auth/SaaS and stablecoin-payment surfaces
(v0.13–v0.18). Reviewing those for correctness is out of scope for this
process review and would need Fable code-level judgment on triggering
content. `→ security/crypto pass` if the owner wants it; it is orthogonal to
F1/F2, which are pure documentation-structure fixes.

---

## Recommendation

Apply F1+F2 as flow **0.1.19** (release convention redirects history to
CHANGELOG + defends the CLAUDE.md ceiling + init scaffolds CHANGELOG + one
lean-CLAUDE.md standing rule). Then a separate trivial project-A cleanup moves
its 380 lines of history to CHANGELOG. Both are documentation-only, no code,
no behavior — safe to do on any model.
