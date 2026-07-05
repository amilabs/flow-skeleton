# flow — universal development workflow plugin (design)

Date: 2026-07-05
Status: approved-pending-owner-review
Repository: https://github.com/amilabs/flow-skeleton (public)

## 1. Purpose

A thin Claude Code plugin (`flow`) that packages the owner's development
operating model once and inherits it across every project via a plugin
marketplace, instead of re-writing workflow rules in each repository's
CLAUDE.md. It targets three needs:

1. **Inheritance**: rules live in one versioned repo; a user-scope install
   makes them available in all projects; one commit updates every machine.
2. **Model routing**: design on the strongest model (Fable 5), implementation
   on Opus 4.8, review agents on Opus — capability where it pays, economy
   where it doesn't.
3. **Brownfield safety**: rewriting large working web projects without
   regressions in dependent places that current tests do not cover.

## 2. Context and lessons applied

The predecessor is the Codex-era Invoicer workflow (reviewed from the INV-096
archive): 34 process documents, 15 scripts validating the process itself,
6 reviewer roles, mandatory review folders per iteration, a governance map
with a conflict-resolution hierarchy between rule documents. It accreted a
new rule after every failure and still failed. Root causes this design avoids:

- **Rules as prose competing for context.** Everything loaded always; the
  model ignored the noise. → flow uses skills: a one-line description in
  context, the body loaded only when relevant.
- **The expensive path as the default path.** Review ceremony for every
  iteration required a separate budget policy to contain itself. → flow makes
  the fast path the default for small changes and scales ceremony by risk.
- **Meta-bureaucracy.** Scripts checking consistency of process documents.
  → flow ships no process-validation tooling; enforcement is either a skill
  instruction (advisory) or a hook (deterministic), nothing in between.
- **Nothing portable.** All rules vendored per repo. → flow is a plugin.

What the predecessor got right is kept: spec-before-code, one task = one
controlled diff, risk-scaled verification, read-only review in fresh context,
affected-first checks, human acceptance as a separate layer, generated
artifacts outside the repo.

## 3. Goals

- One `/plugin install`, every project inherits the workflow.
- Design → implement → accept lifecycle with explicit human gates.
- Risk profiles: the type of change determines the depth of verification.
- Brownfield discipline: blast-radius analysis, characterization tests,
  behavior inventory, lazily written baseline specs.
- Model routing: Fable 5 for design, Opus 4.8 for implementation.
- Agent economy: single session by default; subagents only for exploration,
  fresh-context review, and genuinely independent parallel tasks.
- Multi-stack: TypeScript/React/Node, Python, PHP, Vue/Svelte detected and
  adapted per project by `/flow:init`.

## 4. Non-goals

- No YAML workflow config or lifecycle state machine (state = git + openspec).
- No review folders/archives (evidence = tool outputs, PR description).
- No reviewer role zoo (native `/code-review` + `/security-review` + one
  plan-compliance agent cover it).
- No scripts that validate the process.
- No agent teams, no broad review fan-out by default.
- No duplication of superpowers (process discipline) or OpenSpec (artifacts).
- No hard dependency on the OpenSpec CLI (Tiler has no Node.js; directory
  conventions are enough).
- flow is never vendored into a project; projects reference the marketplace.

## 5. Architecture: four layers

| Layer | Provides | Source |
|---|---|---|
| Claude Code native | plan mode, `/code-review`, `/verify` + run-skill, `/security-review`, hooks, LSP diagnostics, checkpoints, worktrees | built-in / official marketplace |
| superpowers | brainstorming, writing-plans, executing-plans, TDD, systematic-debugging, verification-before-completion, finishing-a-development-branch | `claude-plugins-official` |
| OpenSpec | `openspec/specs/*` (living behavior docs per capability), `openspec/changes/*` (proposal → design → tasks → archive) | CLI optional, conventions mandatory |
| **flow (this plugin)** | model routing, risk profiles, brownfield discipline, acceptance gate, project bootstrap | `amilabs/flow-skeleton` |

flow orchestrates the layers below it and adds only what none of them has.

## 6. Task lifecycle

```
Idea
 → /flow:spec       Fable session, plan mode: interview → blast-radius →
                    OpenSpec change (spec deltas, risk profile, behavior
                    inventory) → HUMAN approves the change
 → /flow:implement  fresh Opus session: TDD per tasks.md, scope discipline,
                    affected checks per task, full suite at checkpoints
 → /flow:accept     full checks + /verify + plan-compliance review +
                    /code-review [+ /security-review by profile] → acceptance
                    summary → HUMAN accepts → merge/PR → openspec archive
```

**Fast path (explicit default for small work).** Typos, log lines, renames,
comment fixes, single-file obvious changes: edit directly, run affected
tests, done. No flow ceremony. The `trivial` risk profile exists precisely to
say "skip the lifecycle". A change qualifies when the diff can be described
in one sentence and touches no dependents.

**Human gates** are exactly two: change approval after `/flow:spec` and
acceptance after `/flow:accept`. Implementation may additionally carry
`[USER GATE]` markers in tasks.md for decisions only the owner can make
(visual approval, product choices).

## 7. Plugin composition

Repository layout (also the marketplace):

```
flow-skeleton/
├── .claude-plugin/marketplace.json      # name: "flow-skeleton", one plugin
├── flow/
│   ├── .claude-plugin/plugin.json       # name: "flow", semver, dependency: superpowers
│   ├── skills/
│   │   ├── spec/SKILL.md
│   │   ├── implement/SKILL.md
│   │   ├── accept/SKILL.md
│   │   ├── blast-radius/SKILL.md
│   │   ├── init/SKILL.md                # + templates/ (CLAUDE.md skeleton, settings snippet)
│   │   └── risk-profiles/SKILL.md       # + reference.md
│   ├── agents/plan-reviewer.md
│   ├── hooks/hooks.json
│   └── README.md                        # plugin usage
├── docs/superpowers/specs/              # this document
├── CHANGELOG.md
├── LICENSE
└── README.md                            # onboarding: install, team setup
```

Budget rule for the plugin itself: 6 skills, 1 agent, 1 hook. Growth beyond
this requires removing something first.

### 7.1 `/flow:spec` — design a change

Frontmatter: `disable-model-invocation: true`, argument hint `[task description]`.

Behavior:
1. Advise (not block) `/model fable` and plan mode if not active.
2. Interview the owner (AskUserQuestion): scope, out-of-scope, constraints,
   success criteria. Skip questions already answered by the request.
3. Locate affected areas; use an Explore subagent for large codebases.
4. Brownfield: read `openspec/specs/` for affected capabilities. If a
   capability has no spec, first write a **baseline spec of current
   behavior** (lazy specs: document an area when first touching it, never
   the whole legacy project upfront).
5. Run `/flow:blast-radius` when modifying existing code with dependents.
6. Select risk profile(s) from `flow:risk-profiles`; record them in the change.
7. For `ui-surface` changes: write a **behavior inventory** — a checklist of
   observable behavior that must survive (routes/pages, navigation entries,
   table columns, form fields, states: empty/error/loading/success).
8. Produce the OpenSpec change folder `openspec/changes/<id>/`:
   `proposal.md` (why/what), spec deltas, `design.md` (only when there are
   non-obvious tradeoffs), `tasks.md` (ordered checkboxes, `[USER GATE]`
   markers where owner input is required).
9. Validate: `openspec validate` when the CLI exists, otherwise a structural
   checklist (all files present, tasks actionable, profile recorded).
10. Summarize and stop for owner approval. Never start implementation.

### 7.2 `/flow:implement` — execute the plan

Frontmatter: `disable-model-invocation: true`, argument hint `[change-id]`.

Behavior:
1. Preconditions: approved change with tasks.md. Recommend a fresh session on
   `/model opus`. If running in a git worktree, note that persistent memory
   is unavailable — CLAUDE.md and openspec/ carry everything needed.
2. Per task: TDD via superpowers (red → green → commit); touch only files
   within the change scope; no drive-by refactoring; tick the task checkbox
   **in the same commit** that completes it; when behavior changes, update
   the spec **in the same commit** as the code.
3. Checks: affected tests/lint after each task (commands from CLAUDE.md);
   full suite at phase checkpoints and before `/flow:accept` — not after
   every step.
4. Agent policy: Explore subagents for research only; no review fan-out
   during implementation.
5. On a blocker: stop and report; do not improvise beyond scope.

### 7.3 `/flow:accept` — acceptance gate

Frontmatter: `disable-model-invocation: true`.

Behavior:
1. Run the project's full checks (from CLAUDE.md Commands).
2. UI-affecting changes: `/verify` against the running app, walking the
   behavior inventory as the checklist.
3. Launch `flow:plan-reviewer` (fresh context): diff vs the OpenSpec change.
4. Run `/code-review` at the effort the risk profile prescribes;
   `/security-review` when the profile demands it.
5. Blockers found → fix → rerun only the affected checks and the reviewer
   that found the issue. No full re-review loops.
6. Produce an acceptance summary: what changed, evidence (test output,
   verify results, review findings), unresolved risks, recommendation.
7. Stop for the owner's decision. On acceptance: superpowers
   finishing-a-development-branch (merge/PR per owner choice), archive the
   change (`openspec archive` or manual move). Never commit/push without an
   explicit owner instruction.

### 7.4 `/flow:blast-radius` — brownfield impact analysis

Frontmatter: model-invocable (description instructs Claude to use it before
modifying shared/existing code) and user-invocable.

Behavior:
1. Map dependents of the code being changed: LSP find-references and call
   hierarchy when a code-intelligence plugin is active; otherwise grep-based
   search with import tracing.
2. Classify each dependent: covered by existing tests vs not.
3. For uncovered dependents inside the blast radius: write
   **characterization tests** first — golden tests pinning current observable
   behavior — before any modification.
4. Output a short impact note (dependents, risk classification, tests added)
   into the change's `design.md`, or as a task note for fast-path work.

### 7.5 `/flow:init` — project bootstrap and migration

Frontmatter: `disable-model-invocation: true`, argument hint `[--existing]`.

New project:
1. Detect stack (`package.json` / `pyproject.toml` / `composer.json` / mixed).
2. Ensure git; create the OpenSpec skeleton (`project.md`, `specs/`,
   `changes/`) — via CLI when present, manually otherwise.
3. Generate a thin CLAUDE.md from the bundled template (target ≤ 60 lines):
   Commands, Architecture notes, Invariants, a two-line flow pointer, and
   the worktree note. Process rules do NOT go here — they live in the plugin.
4. Suggest the matching LSP plugin (`typescript-lsp`, `pyright-lsp`,
   `php-lsp`) and check its binary is installed.
5. Run `/run-skill-generator` to record the launch/verify recipe.
6. Offer opt-in project hooks: PostToolUse affected-lint for the stack;
   optional Stop-hook test gate for autonomous runs.
7. Offer the self-describing team snippet (`extraKnownMarketplaces` +
   `enabledPlugins`) for `.claude/settings.json`.
8. Verify superpowers is installed; if the plugin dependency mechanism did
   not auto-install it, print the install command.

`--existing` (migration, additive and reversible):
- Extract process rules from CLAUDE.md into two pointer lines; keep
  Commands / Architecture / Invariants / environment quirks untouched.
- Add missing pieces only with the owner's confirmation (LSP, run-skill,
  openspec skeleton if absent).
- Never restructure existing `openspec/` or `docs/superpowers/` content.

### 7.6 `flow:risk-profiles` — background knowledge

Frontmatter: `user-invocable: false` (Claude loads it during spec/accept or
when asked "what checks does this change need").

| Profile | Applies to | Mandatory verification | Behavior inventory | `/security-review` | `/code-review` effort |
|---|---|---|---|---|---|
| `trivial` | typos, comments, log lines, local renames | affected tests | — | — | — (fast path, no lifecycle) |
| `pure-logic` | algorithms, calculations, pure functions | TDD unit tests incl. edge cases | — | — | medium |
| `ui-surface` | routes, pages, components, forms, navigation | route/component tests; empty/error/loading states; `/verify` run | yes | — | medium |
| `api-contract` | endpoints, schemas, error formats, versioning | contract tests on both sides; backward-compat check | if UI affected | — | high |
| `data-storage` | persistence, schemas, migrations | migration up + idempotency; malformed old data; round-trip | — | if auth-adjacent | high |
| `auth-security` | auth, sessions, permissions, secrets, payments | negative tests (bypass, injection-shaped inputs) | affected flows | yes | high |
| `external-integration` | third-party APIs, webhooks, queues | mocked failure modes: timeout, non-2xx, malformed payload | — | if secrets handled | medium |
| `build-deploy` | build config, dependencies, env, CI | build passes; lockfile reviewed | — | dependency audit for new deps | medium |

Rules: a change may carry several profiles — requirements are the union.
**Brownfield modifier**: any profile additionally requires `/flow:blast-radius`
when modifying existing code that has dependents outside the change scope;
blast-radius then determines which dependents lack coverage and pins them
with characterization tests.

### 7.7 `agents/plan-reviewer.md`

Read-only tools (Read, Grep, Glob, read-only Bash), `model: opus`. Input:
change id + diff. Checks exactly three things and reports gaps only (no
style feedback): every requirement in the change is implemented; nothing
outside the declared scope changed; behavior inventory items are preserved.
This is the one review native tooling does not provide — `/code-review`
finds bugs, plan-reviewer finds plan divergence.

### 7.8 `hooks/hooks.json` — one universal guard

PreToolUse on Bash: block `git push --force`/`--force-with-lease` to
main/master and `git commit --no-verify`, with a message explaining why.
This is the only plugin-level hook because plugin hooks fire in every
project; anything stack-specific is generated per project by `/flow:init`.

## 8. Model routing

| Phase | Model | Rationale |
|---|---|---|
| `/flow:spec`, architecture decisions | Fable 5 (`/model fable`), effort high | deeper investigation and self-verification where errors are most expensive; design is a small share of total tokens |
| `/flow:implement` | Opus 4.8 | half the price of Fable; sufficient for executing an approved plan; default on the Max plan |
| plan-reviewer, `/code-review` | Opus | fresh context matters more than model size |
| `ultra` cloud review | multi-agent, user-triggered | only genuinely risky merges |

Routing is advisory (skills check and suggest `/model`), never enforced —
consistent with the soft-gates decision. The phase switch doubles as a
context reset: spec in one session, implementation in a fresh one, which is
also the officially recommended pattern.

## 9. Distribution and onboarding

Per machine (once):

```
/plugin marketplace add amilabs/flow-skeleton
/plugin install flow@flow-skeleton        # User scope
/plugin → Marketplaces → flow-skeleton → Enable auto-update
```

User scope makes flow available in every project on the machine with zero
per-project setup. The repo is public — no auth required.

Team repositories may opt into self-description by committing to
`.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "flow-skeleton": {
      "source": { "source": "github", "repo": "amilabs/flow-skeleton" }
    }
  },
  "enabledPlugins": { "flow@flow-skeleton": true }
}
```

Then a teammate's instruction is one sentence: "clone, open in Claude Code,
accept the trust dialog and plugin install prompt."

Updates: edit a rule → bump `version` in `plugin.json` → commit. Machines
with auto-update pick it up on next start; others run
`/plugin marketplace update flow-skeleton`.

`plugin.json` declares superpowers as a dependency so it auto-installs with
flow; `/flow:init` independently verifies and prints the install command if
the cross-marketplace dependency did not resolve.

## 10. Failure modes and fallbacks

| Missing | Behavior |
|---|---|
| OpenSpec CLI (no Node) | directory conventions + structural checklist replace `openspec validate` |
| LSP plugin / language server binary | blast-radius falls back to grep + import tracing; `/flow:init` re-suggests install |
| superpowers not installed | skills degrade to their own inline instructions for TDD/verification and print the install command |
| run-skill absent | `/verify` falls back to inference; `/flow:init` offers `/run-skill-generator` |
| git worktree session | CLAUDE.md + openspec carry all context (persistent memory unavailable); noted in implement skill |

## 11. Validating the plugin itself

- `claude plugin validate` in CI-less local form before each version bump.
- Dry-run after first build: one full spec → implement → accept cycle on a
  toy fixture project (small Express + TypeScript app — the primary target
  stack) driven manually.
- Trigger-quality checks for the two model-invocable pieces (blast-radius,
  risk-profiles) with skill-creator evals — optional, when descriptions
  misfire in practice.
- Dogfooding is the primary long-term validation: next real project task
  runs through flow, and friction fixes land as version bumps.
- Deliberately no meta-validation scripts (see Non-goals).

## 12. Adoption plan for existing projects

- **Tiler**: install-only (user scope). CLAUDE.md already thin; OpenSpec
  stays manual. `/flow:init --existing` optional, low value.
- **Batcher**: `/flow:init --existing` shrinks the CLAUDE.md Process section
  (~35 lines) to pointers; Commands/Architecture/Invariants stay; suggest
  `pyright-lsp`; record run recipe.
- Existing projects keep working unchanged if never migrated — flow is
  strictly additive.

## 13. Decisions log

| Decision | Choice | Date |
|---|---|---|
| Architecture | thin plugin + own marketplace (option B) | 2026-07-05 |
| Spec layer | OpenSpec = artifacts, superpowers = process | 2026-07-05 |
| Gates | soft rules + minimal hooks; Stop-gates opt-in per project | 2026-07-05 |
| Stacks | TS/React/Node, Python, PHP, Vue/Svelte | 2026-07-05 |
| Repo | `amilabs/flow-skeleton`, public | 2026-07-05 |
| Repo language | English artifacts, Russian owner communication | 2026-07-05 |
