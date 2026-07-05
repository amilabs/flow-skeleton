# flow Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `flow` Claude Code plugin and its marketplace in this repository, implementing the design at `docs/superpowers/specs/2026-07-05-flow-plugin-design.md`.

**Architecture:** A plugin marketplace repo (`amilabs/flow-skeleton`) containing one thin plugin (`flow/`): 6 skills, 1 read-only agent, 1 PreToolUse hook with a bundled guard script. All deliverables are markdown/JSON/bash files; verification is `claude plugin validate`, a bash unit-test script for the hook, and a repo-wide grep gate.

**Tech Stack:** Claude Code plugin system (plugin.json / marketplace.json / SKILL.md / agents / hooks), bash + jq (fail-open), no runtime dependencies.

## Global Constraints

- All repo artifacts are in English (owner communication is Russian, files are not).
- No mentions of the owner's other projects anywhere; the final gate greps for their names (the list is kept outside this repository) and must find nothing.
- Component budget is fixed: 6 skills, 1 agent, 1 hook. Do not add components.
- Plain files first: nothing may hard-depend on Node, the OpenSpec CLI, jq, or an LSP server; every consumer of an external tool fails open or has a documented file-only fallback.
- Plugin namespace is `flow` (skills invoke as `/flow:<dir-name>`); marketplace name is `flow-skeleton`.
- Repository: `git@github.com:amilabs/flow-skeleton.git`, branch `main`. Never push with `--force`.
- Every commit message ends with: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Skill bodies stay concise (each well under 150 lines; hard cap 500).

---

### Task 1: Manifests — marketplace.json and plugin.json

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `flow/.claude-plugin/plugin.json`

**Interfaces:**
- Produces: plugin name `flow` and marketplace name `flow-skeleton` — every later install/reference uses `flow@flow-skeleton`; `${CLAUDE_PLUGIN_ROOT}` becomes the install path of `flow/` at runtime.

- [ ] **Step 1: Create the marketplace manifest**

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "flow-skeleton",
  "owner": { "name": "amilabs" },
  "plugins": [
    {
      "name": "flow",
      "source": "./flow",
      "description": "Universal development workflow: spec-first design, TDD implementation, risk-scaled acceptance, brownfield regression safety. Thin layer over superpowers and OpenSpec."
    }
  ]
}
```

- [ ] **Step 2: Create the plugin manifest**

Create `flow/.claude-plugin/plugin.json`:

```json
{
  "name": "flow",
  "description": "Spec → implement → accept lifecycle with risk profiles, blast-radius analysis for brownfield code, and Fable→Opus model routing.",
  "version": "0.1.0",
  "author": { "name": "amilabs" },
  "homepage": "https://github.com/amilabs/flow-skeleton",
  "repository": "https://github.com/amilabs/flow-skeleton",
  "license": "Apache-2.0",
  "dependencies": ["superpowers@claude-plugins-official"]
}
```

- [ ] **Step 3: Validate both manifests**

Run: `claude plugin validate ./flow && claude plugin validate .`
Expected: both report the manifest as valid (exit 0). Warnings about missing optional dirs are acceptable at this stage; errors are not.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json flow/.claude-plugin/plugin.json
git commit -m "feat: marketplace and plugin manifests

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: git-guard hook (test-first)

**Files:**
- Create: `tests/git-guard.test.sh`
- Create: `flow/scripts/git-guard.sh`
- Create: `flow/hooks/hooks.json`

**Interfaces:**
- Consumes: PreToolUse hook stdin JSON: `{"tool_name":"Bash","tool_input":{"command":"..."}}`.
- Produces: exit 0 = allow, exit 2 + stderr message = block. `hooks.json` wires the script via `${CLAUDE_PLUGIN_ROOT}`.

- [ ] **Step 1: Write the failing test script**

Create `tests/git-guard.test.sh`:

```bash
#!/bin/bash
# Unit tests for flow/scripts/git-guard.sh
# Run: bash tests/git-guard.test.sh
set -u
GUARD="$(cd "$(dirname "$0")/.." && pwd)/flow/scripts/git-guard.sh"
pass=0; fail=0

# Deterministic environments for the current-branch fallback:
NONGIT_DIR=$(mktemp -d)                       # not a repo → no branch
MAIN_REPO=$(mktemp -d); git -C "$MAIN_REPO" init -q -b main
FEAT_REPO=$(mktemp -d); git -C "$FEAT_REPO" init -q -b feature/x
trap 'rm -rf "$NONGIT_DIR" "$MAIN_REPO" "$FEAT_REPO"' EXIT

check() { # description, expected_exit, project_dir, bash_command_string
  desc="$1"; expected="$2"; dir="$3"; cmd="$4"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd" \
    | CLAUDE_PROJECT_DIR="$dir" bash "$GUARD" >/dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); echo "FAIL: $desc (expected exit $expected, got $actual)"
  fi
}

check "force push to main blocked"            2 "$NONGIT_DIR" "git push --force origin main"
check "force-with-lease to master blocked"    2 "$NONGIT_DIR" "git push --force-with-lease origin master"
check "short -f push to main blocked"         2 "$NONGIT_DIR" "git push -f origin main"
check "force push to feature ref allowed even from main checkout" 0 "$MAIN_REPO" "git push --force origin feature/x"
check "bare force push while on main blocked" 2 "$MAIN_REPO"   "git push -f origin"
check "bare force push on feature branch allowed" 0 "$FEAT_REPO" "git push -f origin"
check "plain push to main allowed"            0 "$NONGIT_DIR" "git push origin main"
check "no-verify commit blocked"              2 "$NONGIT_DIR" "git commit --no-verify -m msg"
check "plain commit allowed"                  0 "$NONGIT_DIR" "git commit -m msg"
check "unrelated command allowed"             0 "$NONGIT_DIR" "ls -la"
check "empty command tolerated"               0 "$NONGIT_DIR" ""

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/git-guard.test.sh`
Expected: FAIL lines (guard script does not exist yet), final exit non-zero.

- [ ] **Step 3: Write the guard script**

Create `flow/scripts/git-guard.sh`. Blocking rule for force-pushes: block
when main/master is named in the command; when no refspec is named at all,
fall back to the current branch of `CLAUDE_PROJECT_DIR`. When a non-main
refspec is named explicitly, allow — the current checkout is irrelevant to
what `git push <remote> <ref>` touches.

```bash
#!/bin/bash
# flow git-guard — PreToolUse(Bash) hook.
# Blocks: force-push targeting main/master; git commit --no-verify.
# Fail-open: any tooling problem allows the command through (exit 0).

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat) || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

if printf '%s' "$cmd" | grep -qE 'git[^|;&]*push[^|;&]*(--force(-with-lease)?([= ]|$)|[[:space:]]-f([[:space:]]|$))'; then
  blocked=""
  if printf '%s' "$cmd" | grep -qE '[[:space:]](main|master)([[:space:]]|:|$)'; then
    blocked="yes"
  else
    # Second non-flag token after "push" is the refspec (first is the remote).
    refspec=$(printf '%s' "$cmd" | awk '{
      push=0; n=0
      for (i=1; i<=NF; i++) {
        if ($i=="push") { push=1; continue }
        if (!push) continue
        if ($i ~ /^-/) continue
        n++
        if (n==2) { print $i; exit }
      }
    }')
    if [ -z "$refspec" ]; then
      branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" symbolic-ref --short HEAD 2>/dev/null)
      case "$branch" in main|master) blocked="yes";; esac
    fi
  fi
  if [ -n "$blocked" ]; then
    echo "flow git-guard: force-push to main/master is blocked. Push a branch and open a PR, or have the owner run the command manually." >&2
    exit 2
  fi
fi

if printf '%s' "$cmd" | grep -qE 'git[^|;&]*commit[^|;&]*--no-verify'; then
  echo "flow git-guard: 'git commit --no-verify' is blocked. Fix the failing hook instead of bypassing it." >&2
  exit 2
fi

exit 0
```

Then: `chmod +x flow/scripts/git-guard.sh`

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/git-guard.test.sh`
Expected: `pass=11 fail=0`, exit 0.

- [ ] **Step 5: Wire the hook**

Create `flow/hooks/hooks.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/git-guard.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 6: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid, hook listed.

```bash
git add tests/git-guard.test.sh flow/scripts/git-guard.sh flow/hooks/hooks.json
git commit -m "feat: git-guard PreToolUse hook with unit tests

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: risk-profiles skill (background knowledge)

**Files:**
- Create: `flow/skills/risk-profiles/SKILL.md`

**Interfaces:**
- Produces: profile names `trivial | pure-logic | ui-surface | api-contract | data-storage | auth-security | external-integration | build-deploy` — referenced verbatim by the spec and accept skills.

- [ ] **Step 1: Write the skill**

Create `flow/skills/risk-profiles/SKILL.md`:

```markdown
---
name: risk-profiles
description: Maps a change type to the verification it needs - tests, behavior inventory, security review, code-review effort. Consult when designing a change (/flow:spec), accepting one (/flow:accept), or whenever deciding how much testing or review a change requires.
user-invocable: false
---

# Risk profiles

Select one or more profiles for every change during /flow:spec and record
them in the change's proposal.md. Requirements of multiple profiles combine
(union). When in doubt between two profiles, take the stricter one.

| Profile | Applies to | Mandatory verification | Behavior inventory | /security-review | /code-review effort |
|---|---|---|---|---|---|
| trivial | typos, comments, log lines, local renames | affected tests | no | no | none (fast path: skip the flow lifecycle entirely) |
| pure-logic | algorithms, calculations, pure functions | TDD unit tests incl. edge cases | no | no | medium |
| ui-surface | routes, pages, components, forms, navigation | route/component tests; empty/error/loading states; /verify run | yes | no | medium |
| api-contract | endpoints, schemas, error formats, versioning | contract tests on both sides; backward-compat check | if UI affected | no | high |
| data-storage | persistence, schemas, migrations | migration up + idempotency; malformed old data; round-trip | no | if auth-adjacent | high |
| auth-security | auth, sessions, permissions, secrets, payments | negative tests: bypass attempts, injection-shaped inputs | affected flows | yes | high |
| external-integration | third-party APIs, webhooks, queues | mocked failure modes: timeout, non-2xx, malformed payload | no | if secrets handled | medium |
| build-deploy | build config, dependencies, env, CI | build passes; lockfile reviewed | no | dependency audit for new deps | medium |

**Brownfield modifier**: any profile additionally requires /flow:blast-radius
when the change modifies existing code that has dependents outside the
change scope. Blast-radius determines which dependents lack test coverage
and pins them with characterization tests before the modification.

**Fast path**: a change is trivial when its diff can be described in one
sentence and it touches no dependents. Trivial changes skip /flow:spec,
/flow:implement, and /flow:accept — edit directly, run affected tests, done.
```

- [ ] **Step 2: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid, skill listed.

```bash
git add flow/skills/risk-profiles/SKILL.md
git commit -m "feat: risk-profiles background skill

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: blast-radius skill

**Files:**
- Create: `flow/skills/blast-radius/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks (LSP tools when present; grep fallback).
- Produces: the impact-note convention (goes into a change's `design.md`) consumed by the spec skill's step 4.

- [ ] **Step 1: Write the skill**

Create `flow/skills/blast-radius/SKILL.md`:

```markdown
---
name: blast-radius
description: Impact analysis before modifying existing code. Use before changing shared modules, widely imported utilities, or any existing code whose dependents may not be covered by tests - especially in legacy or brownfield projects. Maps dependents, then pins uncovered ones with characterization tests.
argument-hint: "[file, symbol, or module to change]"
---

# Blast radius

Target: $ARGUMENTS (if empty, use the code the current task is about to modify).

## 1. Map dependents

- With a code-intelligence (LSP) plugin active: use find-references and the
  call hierarchy on the symbols being changed.
- Without LSP: grep for imports/usages of the module and its exported
  names; trace one level of re-exports.

List every dependent: file, symbol used, and how it would break if the
behavior shifts.

## 2. Classify coverage

For each dependent, determine whether an existing test exercises it through
the code being changed. Run the relevant slice of the suite to confirm —
do not guess from file names.

## 3. Pin uncovered dependents

For each dependent without coverage, write a characterization test BEFORE
modifying anything: capture current observable behavior (input → current
output), even if that behavior looks wrong. If it looks wrong, flag it in
the impact note — do not silently fix it; changing it is a scope decision
for the owner.

## 4. Write the impact note

Produce a short note: dependents found, coverage classification, tests
added, residual risks. Put it in the active change's design.md (create the
file if the change lacks one), or report it inline for fast-path work.

Do not start the actual modification until the characterization tests pass
against the unmodified code.
```

- [ ] **Step 2: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid.

```bash
git add flow/skills/blast-radius/SKILL.md
git commit -m "feat: blast-radius impact-analysis skill

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: spec skill

**Files:**
- Create: `flow/skills/spec/SKILL.md`

**Interfaces:**
- Consumes: `/flow:blast-radius` (Task 4), profile names from `risk-profiles` (Task 3).
- Produces: the OpenSpec change-folder convention `openspec/changes/<id>/{proposal.md, design.md, tasks.md, spec deltas}` consumed by implement (Task 6), accept (Task 7), and plan-reviewer (Task 9).

- [ ] **Step 1: Write the skill**

Create `flow/skills/spec/SKILL.md`:

```markdown
---
name: spec
description: Design a change before any implementation - interview, impact analysis, OpenSpec change folder with risk profile and behavior inventory. Ends at the owner approval gate.
disable-model-invocation: true
argument-hint: "[task description]"
---

# Design a change

Task: $ARGUMENTS

You are in the design phase. Do not write implementation code. The
deliverable is an OpenSpec change folder ready for owner approval.

## Setup

- This phase belongs on the strongest model: if the session is not on
  Fable, suggest `/model fable` (advisory — continue either way). Plan mode
  is recommended.
- Read `openspec/project.md` if it exists (project context and constraints).

## Steps

1. **Interview.** Clarify with AskUserQuestion whatever the request leaves
   open: scope, out-of-scope, constraints, success criteria. Skip what the
   request already answers; prefer a few sharp questions over many obvious
   ones.
2. **Locate affected areas.** For large codebases use an Explore subagent
   so this session's context stays clean.
3. **Baseline specs (brownfield).** For each affected capability, read its
   spec under `openspec/specs/`. If none exists, first write a baseline
   spec of CURRENT behavior — document only the area being touched, never
   the whole legacy project upfront.
4. **Impact analysis.** If the change modifies existing code with
   dependents outside the change scope, run /flow:blast-radius and put the
   impact note in the change's design.md.
5. **Risk profile.** Select profile(s) from the flow risk-profiles table
   and record them in proposal.md. If the change qualifies as trivial,
   stop: tell the owner the fast path applies and no change folder is
   needed.
6. **Behavior inventory (ui-surface).** List observable behavior that must
   survive: routes/pages, navigation entries, table columns, form fields,
   states (empty/error/loading/success). Keep it in the change folder.
7. **Write the change folder** `openspec/changes/<kebab-case-id>/`:
   - `proposal.md` — why, what, risk profile(s), explicit out-of-scope list
   - spec deltas for affected capabilities
   - `design.md` — only when there are non-obvious tradeoffs (blast-radius
     impact note lives here)
   - `tasks.md` — ordered checkbox tasks, each sized for one test cycle;
     mark decisions only the owner can make with `[USER GATE]`
8. **Validate.** With the openspec CLI: `openspec validate <id>`. Without
   it, check structurally: files above present, every task actionable,
   profile recorded, inventory present when required.
9. **Stop for approval.** Summarize the change and ask the owner to approve
   it. Do not start implementation. After approval the owner runs
   /flow:implement — ideally in a fresh session on Opus.
```

- [ ] **Step 2: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid.

```bash
git add flow/skills/spec/SKILL.md
git commit -m "feat: spec design-phase skill

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: implement skill

**Files:**
- Create: `flow/skills/implement/SKILL.md`

**Interfaces:**
- Consumes: change folder convention from Task 5 (`openspec/changes/<id>/tasks.md` checkboxes, `[USER GATE]` markers).
- Produces: completed tasks state consumed by accept (Task 7).

- [ ] **Step 1: Write the skill**

Create `flow/skills/implement/SKILL.md`:

```markdown
---
name: implement
description: Execute an approved OpenSpec change task-by-task with TDD and scope discipline. Run in a fresh session on Opus after /flow:spec approval.
disable-model-invocation: true
argument-hint: "[change-id]"
---

# Implement a change

Change: $ARGUMENTS. If empty, take the single active (non-archived) change
under `openspec/changes/`; if several are active, ask which one.

## Preconditions

- The change folder exists and the owner approved it. If not, stop and
  point to /flow:spec.
- Implementation runs economically: if the session is on Fable, suggest
  `/model opus` (advisory).
- If running in a git worktree: persistent memory is unavailable there —
  CLAUDE.md and openspec/ carry all needed context; merge back when the
  phase completes.

## Execution loop — per task in tasks.md

1. Test-driven development (use the superpowers TDD skill when available):
   failing test → verify red → minimal implementation → verify green.
2. Touch only files within the change scope. No drive-by refactoring; if a
   necessary refactor emerges, add it to the change or flag it to the owner.
3. Tick the task checkbox in tasks.md IN THE SAME COMMIT that completes the
   task. When behavior changes, update the capability spec in that same
   commit.
4. After each task run the affected tests/lint (commands from CLAUDE.md).
   Run the FULL suite at phase checkpoints and before /flow:accept — not
   after every step.
5. At a `[USER GATE]` task: stop, present the decision, wait for the owner.

## Agent policy

Explore subagents for research only. No review fan-out during
implementation — review happens once, at /flow:accept.

## On a blocker

Stop and report: what blocks, what was tried, the options. Do not improvise
beyond the approved scope.

When all tasks are done and the full suite is green, tell the owner the
change is ready for /flow:accept.
```

- [ ] **Step 2: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid.

```bash
git add flow/skills/implement/SKILL.md
git commit -m "feat: implement execution-phase skill

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: accept skill

**Files:**
- Create: `flow/skills/accept/SKILL.md`

**Interfaces:**
- Consumes: change folder (Task 5), profile effort levels (Task 3), agent `flow:plan-reviewer` (Task 9), bundled `/code-review`, `/security-review`, `/verify`.
- Produces: acceptance summary for the owner; archive convention `openspec/changes/archive/`.

- [ ] **Step 1: Write the skill**

Create `flow/skills/accept/SKILL.md`:

```markdown
---
name: accept
description: Acceptance gate before merge - full checks, live-app verification, plan-compliance review, risk-scaled code review, acceptance summary for the owner.
disable-model-invocation: true
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
```

- [ ] **Step 2: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid.

```bash
git add flow/skills/accept/SKILL.md
git commit -m "feat: accept acceptance-gate skill

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: init skill with templates

**Files:**
- Create: `flow/skills/init/SKILL.md`
- Create: `flow/skills/init/templates/CLAUDE.md.template`
- Create: `flow/skills/init/templates/team-settings.json`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: per-project CLAUDE.md skeleton and team settings snippet; `{{...}}` placeholders are filled by the skill at run time.

- [ ] **Step 1: Write the skill**

Create `flow/skills/init/SKILL.md`:

```markdown
---
name: init
description: Bootstrap a project for the flow workflow (new project) or migrate an existing one (--existing). Sets up CLAUDE.md, OpenSpec structure, LSP suggestion, run recipe, optional project hooks.
disable-model-invocation: true
argument-hint: "[--existing]"
---

# Project bootstrap

Mode: `--existing` in "$ARGUMENTS" means migration of a live project;
otherwise fresh setup. Everything here is opt-in and non-destructive:
propose, show the diff, apply only on confirmation.

## Both modes

1. **Detect the stack**: package.json (Node/TS — note the framework),
   pyproject.toml or requirements.txt (Python), composer.json (PHP). Mixed
   stacks get all applicable adapters.
2. **LSP plugin**: suggest the matching code-intelligence plugin and check
   its binary is installed — typescript-lsp (typescript-language-server),
   pyright-lsp (pyright-langserver), php-lsp (intelephense). Skip silently
   when the stack has no official LSP plugin.
3. **Run recipe**: if no `.claude/skills/run-*` skill exists, offer
   /run-skill-generator so /verify and /flow:accept can drive the real app.
4. **superpowers check**: verify the superpowers plugin is installed; if
   the plugin dependency did not auto-install it, print:
   `/plugin install superpowers@claude-plugins-official`
5. **Project hooks (opt-in)**: offer a PostToolUse hook running the stack's
   affected lint/typecheck after edits and, for autonomous runs, an
   optional Stop-hook test gate. Write to the project's
   `.claude/settings.json` only on explicit confirmation.
6. **Team snippet (opt-in)**: for shared repos, offer the self-describing
   settings from [templates/team-settings.json](templates/team-settings.json).

## New project additionally

7. **git**: `git init -b main` when not a repo; add a sensible .gitignore
   for the detected stack.
8. **OpenSpec skeleton**: `openspec init` when the CLI exists; otherwise
   create by hand: `openspec/project.md` (project context, constraints,
   conventions), `openspec/specs/`, `openspec/changes/`. Plain files are
   the contract; the CLI is an accelerator.
9. **CLAUDE.md**: generate from
   [templates/CLAUDE.md.template](templates/CLAUDE.md.template), filling
   Commands from the detected stack. Keep it at or under 60 lines:
   commands, architecture facts, invariants, environment quirks. Process
   rules do NOT go here — they live in the flow plugin.

## --existing additionally

7. **CLAUDE.md migration**: identify generic process rules (TDD cycles,
   review/gate rules, commit etiquette) and collapse them to the Workflow
   section of the template. Keep project facts untouched: Commands,
   Architecture, Invariants, environment quirks, current-state notes. Show
   the full diff before applying.
8. **OpenSpec**: if `openspec/` is absent, offer the skeleton from step 8
   above. Never restructure existing openspec/ or docs/ content.
```

- [ ] **Step 2: Write the CLAUDE.md template**

Create `flow/skills/init/templates/CLAUDE.md.template`:

```markdown
# {{PROJECT_NAME}} — instructions for Claude sessions

## Commands

```bash
{{INSTALL_COMMAND}}
{{TEST_COMMAND}}
{{LINT_COMMAND}}
{{RUN_COMMAND}}
```

## Architecture

{{THREE_TO_FIVE_FACTS_CLAUDE_CANNOT_INFER_FROM_CODE}}

## Invariants (violating these is a bug)

{{PROJECT_INVARIANTS}}

## Workflow

- Non-trivial work goes through the flow plugin: /flow:spec → owner
  approval → /flow:implement (fresh session) → /flow:accept → owner
  accepts. Trivial changes (one-sentence diff, no dependents) skip the
  lifecycle.
- Worktree sessions: persistent memory is unavailable — this file and
  openspec/ carry everything; merge back to main when a phase completes.
- Never commit or push unless explicitly asked.
```

- [ ] **Step 3: Write the team settings snippet**

Create `flow/skills/init/templates/team-settings.json`:

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

- [ ] **Step 4: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid.

```bash
git add flow/skills/init
git commit -m "feat: init bootstrap skill with templates

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 9: plan-reviewer agent

**Files:**
- Create: `flow/agents/plan-reviewer.md`

**Interfaces:**
- Consumes: change folder convention from Task 5.
- Produces: agent type `flow:plan-reviewer`, launched by the accept skill (Task 7, gate 3).

- [ ] **Step 1: Write the agent**

Create `flow/agents/plan-reviewer.md`:

```markdown
---
name: plan-reviewer
description: Read-only reviewer that checks an implementation diff against its approved OpenSpec change. Launch from /flow:accept with the change id. Reports plan divergence only - bugs are /code-review's job.
model: opus
disallowedTools: Write, Edit, NotebookEdit
---

You are a plan-compliance reviewer. You never modify files; you only read
and report.

Input: a change id under `openspec/changes/<id>/` and the diff to review.
If no diff is provided, run `git diff main...HEAD` yourself; fall back to
`git diff HEAD` for uncommitted work.

Check exactly three things:

1. **Completeness** — every requirement in the change's proposal.md, spec
   deltas, and tasks.md is implemented. An unticked task must correspond to
   genuinely missing work; a ticked task must correspond to present work.
2. **Scope** — nothing outside the change's declared scope was modified.
   Compare the diff's file list against what the change implies; flag
   unrelated edits, drive-by refactors, and undeclared new dependencies.
3. **Behavior inventory** — when the change carries one, each inventory
   item (routes, navigation entries, columns, fields, states) is still
   present in the implementation.

Report format: a short list of gaps, each with file:line references and the
violated change requirement. Severity per gap: blocker (requirement missing
or scope violated) or note. No style feedback, no bug hunting, no praise.
If everything checks out, say so in one line.
```

- [ ] **Step 2: Validate and commit**

Run: `claude plugin validate ./flow`
Expected: valid, agent listed.

```bash
git add flow/agents/plan-reviewer.md
git commit -m "feat: plan-reviewer read-only agent

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 10: Documentation — READMEs and CHANGELOG

**Files:**
- Modify: `README.md` (repo root — currently a one-line stub)
- Create: `flow/README.md`
- Create: `CHANGELOG.md`

**Interfaces:**
- Consumes: install identifiers from Task 1 (`flow@flow-skeleton`), team snippet from Task 8.

- [ ] **Step 1: Write the root README (onboarding)**

Replace the content of `README.md` with:

````markdown
# flow-skeleton

A Claude Code plugin marketplace with one plugin: **flow** — a universal
development workflow. Design on the strongest model, implement economically,
verify by risk, survive brownfield rewrites.

## Install (once per machine)

Inside any Claude Code session:

```
/plugin marketplace add amilabs/flow-skeleton
/plugin install flow@flow-skeleton
```

Choose **User scope** — flow becomes available in every project on the
machine. Then enable updates: `/plugin` → Marketplaces → flow-skeleton →
**Enable auto-update**. The superpowers plugin is declared as a dependency
and installs alongside.

## Commands

| Command | Purpose |
|---|---|
| `/flow:init` | bootstrap a project (`--existing` migrates a live one) |
| `/flow:spec` | design a change → OpenSpec change folder → owner approval |
| `/flow:implement` | execute the approved change with TDD (fresh session) |
| `/flow:accept` | acceptance gate: checks, live verify, reviews, summary |
| `/flow:blast-radius` | impact analysis before touching existing code |

Trivial changes (one-sentence diff, no dependents) skip the lifecycle
entirely — that is a rule, not an exception.

## Team repositories

Commit this to the project's `.claude/settings.json` and teammates get an
install prompt on first trusted open — their instruction is one sentence:
"clone, open in Claude Code, accept the prompts."

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

## Design

The full design document:
[docs/superpowers/specs/2026-07-05-flow-plugin-design.md](docs/superpowers/specs/2026-07-05-flow-plugin-design.md).

## License

Apache-2.0
````

- [ ] **Step 2: Write the plugin README**

Create `flow/README.md`:

```markdown
# flow

Universal development workflow plugin. Thin by design: a budget of 6
skills, 1 agent, 1 hook — growth requires removing something first.

## Lifecycle

/flow:spec (design, strongest model) → owner approves →
/flow:implement (TDD, economical model, fresh session) →
/flow:accept (checks + live verify + plan compliance + risk-scaled review)
→ owner accepts → merge/PR, change archived.

## Components

- skills/spec — design phase, ends at the approval gate
- skills/implement — execution loop with scope discipline
- skills/accept — acceptance gates and owner summary
- skills/blast-radius — dependent mapping + characterization tests
- skills/init — project bootstrap and migration
- skills/risk-profiles — background knowledge: change type → verification
- agents/plan-reviewer — read-only diff-vs-change compliance review
- hooks + scripts/git-guard.sh — blocks force-push to main/master and
  --no-verify commits (fail-open)

## Layering

flow orchestrates and does not duplicate: process discipline comes from
superpowers, spec artifacts follow OpenSpec conventions (CLI optional —
plain files are the contract), review/verify/LSP come from Claude Code
built-ins and official plugins.
```

- [ ] **Step 3: Write the CHANGELOG**

Create `CHANGELOG.md`:

```markdown
# Changelog

## 0.1.0 — 2026-07-05

Initial release: spec / implement / accept lifecycle skills, blast-radius
impact analysis, risk-profiles background knowledge, init bootstrap with
templates, plan-reviewer agent, git-guard hook.
```

- [ ] **Step 4: Commit**

```bash
git add README.md flow/README.md CHANGELOG.md
git commit -m "docs: onboarding README, plugin README, changelog

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 11: Final gate — validate, test, grep, push, tag

**Files:**
- No new files; verification and release only.

- [ ] **Step 1: Full validation**

Run: `claude plugin validate ./flow && claude plugin validate .`
Expected: both valid, all 6 skills + 1 agent + hooks listed for the plugin.

- [ ] **Step 2: Hook tests**

Run: `bash tests/git-guard.test.sh`
Expected: `pass=9 fail=0`, exit 0.

- [ ] **Step 3: Cross-project reference gate**

Run a case-insensitive recursive grep (excluding `.git`) for the owner's
private project names — the list lives outside this repository.
Expected: no matches (exit 1).

- [ ] **Step 4: Component budget check**

Run: `ls flow/skills | wc -l && ls flow/agents | wc -l`
Expected: `6` skills, `1` agent.

- [ ] **Step 5: Push and tag**

```bash
git push
git tag v0.1.0 && git push origin v0.1.0
```

Expected: main and tag `v0.1.0` on `amilabs/flow-skeleton`.
