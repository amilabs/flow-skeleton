# flow review — problems & improvements (2026-07-15)

Retrospective over the flow plugin (v0.1.0→v0.1.18) and its real use across
Batcher (18 releases v0.1→v0.18, through 2026-07-09), Tiler, pets-game,
ethplorer-flow. Owner-initiated; done on Opus. Findings ranked by impact.

> **Prepared for a later Fable review.** This doc is process/structure only —
> no crypto/security content that would trip Fable's classifier. Items that
> would need code-level security/crypto judgment are tagged
> `→ security/crypto pass` and NOT investigated here.

---

## F1 — CLAUDE.md grows unbounded; the release convention is the cause (HIGH)

**Symptom (owner-surfaced).** Batcher's CLAUDE.md is **539 lines**; the
`Current state` section alone is **~380 lines (70%)** — a per-release
narrative dump (v0.7 … v0.18, each a paragraph). Tiler is 36 lines,
pets-game 49. The whole 539 loads into context **every session**, diluting
the actual standing instructions (Commands/Architecture/Invariants/Workflow
sit in the first 160 lines, then drown).

**Root cause — this is a flow defect, not project sloppiness:**
- `/flow:init` sets a ceiling: *"Keep it at or under 60 lines."*
- The release convention (`/flow:accept`, and the recorded convention step 2)
  instructs every release to *"update the CLAUDE.md Current state section to
  record the version as accepted & merged, folding in deferred/known-minor
  notes."* It only ever **appends**. Nothing prunes.
- Result: the ≤60 ceiling is set at birth and never defended. 18 releases →
  380 lines of Current state.
- Irony: **flow-skeleton itself does it right** — it keeps a `CHANGELOG.md`
  and a lean CLAUDE.md. The plugin doesn't practice what it prescribes.

**Why it matters.** The flow best-practices flow is built on say plainly:
*"Bloated CLAUDE.md files cause Claude to ignore your actual instructions."*
So this defect actively degrades every downstream project as it matures —
the most successful projects (most releases) get the worst context dilution.

**Fix (proposed, flow ~0.1.19):**
1. **Redirect release history to `CHANGELOG.md`.** The release convention
   should record each version as a `CHANGELOG.md` entry (what flow itself
   does), NOT a CLAUDE.md paragraph. Per-change full detail already lives in
   `openspec/archive/<id>/` — Current state paragraphs largely duplicate it.
2. **Bound `Current state` in CLAUDE.md.** It should carry only: the current
   version + branch, and pointers (`CHANGELOG.md`, `openspec/archive/`). At
   most the last release as a one-liner. Not an accumulating log.
3. **Defend the ceiling at release, not just at init.** The release
   convention should re-assert the ≤~60-line target (or a project-chosen
   ceiling): if CLAUDE.md exceeds it, prune narrative/history to CHANGELOG
   as part of the archive commit.
4. **`/flow:init` scaffolds `CHANGELOG.md`** so there is a designated home
   for release history from day one (Batcher had none → history had nowhere
   to go but CLAUDE.md).

**One-time cleanup for Batcher** (separate, owner-approved): move the ~380
lines of Current state into `CHANGELOG.md`, collapse Current state to a
bounded pointer. Purely editorial — no code, no behavior. Recommended as its
own trivial change.

---

## F2 — Multiple unbounded growth vectors into CLAUDE.md (MEDIUM)

Current state is the worst, but not the only one:
- **Invariants** grows every time 0.1.17's rule fires ("restate recurring
  owner feedback as a general principle in CLAUDE.md invariants"). This is
  legitimate — invariants ARE standing instructions — but has no size
  awareness either. Batcher's Invariants block is already dense (money,
  currencies, migrations, UI) and correct; watch it doesn't accrete
  instance-level notes instead of general principles.
- **Architecture** naturally accretes as a project grows (Batcher's is now
  a wall of module descriptions). Fine in kind, but no periodic prune.

**Fix:** fold into F1's principle — flow should carry one explicit standing
rule: *CLAUDE.md is loaded every session; keep it lean; per-release history
and long reference go to CHANGELOG/archives/docs, not here; prune at
release.* One rule, referenced by both init and accept.

---

## F3 — Sessions largely went WELL; the scars are already captured (INFO)

The process worked at real scale: 18 Batcher releases through
spec→implement→accept, ethplorer Part 2, and the plugin's own 18 versions —
all shipped. The accumulated operational friction (dependency scoping,
desktop spare processes, git-guard evolution, model fallback) is already in
memory (`flow-operational-lessons.md`) and mostly fixed in the plugin. No
new process defects surfaced beyond F1/F2. The one visible scar of scale is
exactly F1 — CLAUDE.md bloat is what 18 successful releases *look like* under
the current convention.

---

## Deferred to a security/crypto pass (not investigated here)

Batcher's later releases carry auth/SaaS and stablecoin-payment surfaces
(v0.13–v0.18). Reviewing those for correctness is out of scope for this
process review and would need Fable code-level judgment on triggering
content. `→ security/crypto pass` if the owner wants it; it is orthogonal to
F1/F2, which are pure documentation-structure fixes.

---

## Recommendation

Apply F1+F2 as flow **0.1.19** (release convention redirects history to
CHANGELOG + defends the CLAUDE.md ceiling + init scaffolds CHANGELOG + one
lean-CLAUDE.md standing rule). Then a separate trivial Batcher cleanup moves
its 380 lines of history to CHANGELOG. Both are documentation-only, no code,
no behavior — safe to do on any model.
