---
name: implement
description: Execute an approved OpenSpec change task-by-task with TDD and scope discipline. Run in a fresh session on Opus after /flow:spec approval. Invoke only when the owner explicitly asks to implement an approved change (in any wording); never start it on your own initiative.
argument-hint: "[change-id]"
model: opus
---

# Implement a change

Change: $ARGUMENTS. If empty, take the single active (non-archived) change
under `openspec/changes/`; if several are active, ask which one.

## Preconditions

- The change folder exists and the owner approved it. If not, stop and
  point to /flow:spec.
- Work on a feature branch (a git worktree when sessions run in parallel).
  Never implement on main/master without the owner's explicit consent.
- Implementation runs economically: this skill pins its turns to Opus via
  frontmatter. Note the scope: the override lasts for the current turn
  only — after each owner message the session model returns, so if the
  session runs on Fable, still suggest `/model opus` (or a fresh session)
  for long multi-turn implementation.
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
