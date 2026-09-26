---
name: implement
description: Execute an approved OpenSpec change task-by-task with TDD and scope discipline. Run in a fresh session on Opus after /flow:spec approval. Invoke only when the owner explicitly asks to implement an approved change (in any wording); never start it on your own initiative.
argument-hint: "[change-id]"
---

# Implement a change

Change: $ARGUMENTS. If empty, take the single active (non-archived) change
under `openspec/changes/`; if several are active, ask which one.

## Preconditions

- The change folder exists and the owner approved it. If not, stop and
  point to /flow:spec.
- Work on a feature branch (a git worktree when sessions run in parallel).
  Never implement on main/master without the owner's explicit consent.
- Execution model and effort are the owner's choice — confirm them before
  starting (AskUserQuestion, one question): default Opus at session effort;
  offer Fable for architecturally gnarly or high-risk changes, and a higher
  effort level when the change warrants it. You cannot switch the session's
  model yourself: if the owner picks a model different from the current
  session, ask them to run `/model` (picker key `s` = this session only) or
  open a fresh session on it, then continue.
- If running in a git worktree: persistent memory is unavailable there —
  CLAUDE.md and openspec/ carry all needed context; merge back when the
  phase completes.

## Execution loop — per task in tasks.md

tasks.md IS the plan: do not invoke the superpowers brainstorming,
writing-plans, or executing-plans skills — the change folder already
carries the design and the task list. Use superpowers execution
disciplines (TDD, systematic-debugging, verification) per task.

1. Test-driven development (use the superpowers TDD skill when available):
   failing test → verify red → minimal implementation → verify green.
2. On any test failure you did not predict, unexpected behavior, or
   "weird" result: invoke the superpowers systematic-debugging skill
   BEFORE attempting a fix. Guess-and-retry loops are a process
   violation, not a style choice.
3. Touch only files within the change scope. No drive-by refactoring; if a
   necessary refactor emerges, add it to the change or flag it to the owner.
   The scope of a change is the changed COMPONENT plus the consumers its
   change actually reaches: a shared repository, host, branch or process
   does not make its tenants one component, and a component the change
   does not touch is not built, versioned, deployed or verified for it.
4. Before ticking a task checkbox, invoke the superpowers
   verification-before-completion skill: run the verifying commands and
   read their output fresh — a done-claim without evidence from THIS
   session state is a gate failure. Then tick the checkbox in tasks.md IN
   THE SAME COMMIT that completes the task. When behavior changes, update
   the capability spec in that same commit.
5. After each task run the affected tests/lint (commands from CLAUDE.md) —
   including the EXISTING tests of every mechanism the task changed, not
   only the new ones. The project's recorded test cadence decides what
   ends implement: where one says the single full run belongs to
   /flow:accept, implement ends with the targeted checks of the changed
   mechanisms through their own call paths, and running the full suite
   here as well is a second execution of the same proof. Where no cadence
   is recorded, run the full suite before /flow:accept.
6. At a `[USER GATE]` task: stop, present the decision, wait for the owner.

## Agent policy

Explore subagents for research only. No review fan-out during
implementation — review happens once, at /flow:accept.

Any fan-out to 2+ agents, and any multi-session batch (night cycles
included), starts by invoking the superpowers
dispatching-parallel-agents skill — visibly, before the first dispatch —
and follows it: one agent per independent problem domain, self-contained
prompts (scope, context, constraints, expected output), independent
verification of results — an agent's own success report is never
evidence. Isolation is per writer: every agent that writes files gets
its own git worktree via the native worktree mechanism (the superpowers
using-git-worktrees skill when available) — never one shared tree split
by file lists; read-only research agents may share. In any parallel
session, verify which branch/worktree this session actually sits on
before running gates or reporting them green.

## On a blocker

Stop and report: what blocks, what was tried, the options. Do not improvise
beyond the approved scope.

When all tasks are done and the full suite is green, tell the owner the
change is ready for /flow:accept.
