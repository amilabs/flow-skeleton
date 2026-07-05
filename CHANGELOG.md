# Changelog

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
