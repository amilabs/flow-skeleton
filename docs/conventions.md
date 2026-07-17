# Repo conventions

- **No cross-project references.** This is a public repo: artifacts must
  not name the owner's other projects. Abstract project-derived
  knowledge into rules; where a concrete case is unavoidable, use the
  A–D labels established in `docs/superpowers/reviews/`. Grep for
  project names before every commit.
- **No Co-Authored-By trailers** in commit messages (owner rule,
  2026-07-16; applies across all of the owner's repos).
- **English artifacts.** Repo files and commit messages are English;
  communication with the owner is Russian.
- **WIP stays local within a version** (owner rule, 2026-07-16). GitHub
  carries finished versions; unfinished iterations — research branches,
  worktrees, drafts — may live only on the local machine until the
  iteration completes. Sessions must remind the owner at release
  checkpoints what is still local-only; the push decision is per-release
  and the owner's.
