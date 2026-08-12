# Operational lessons (troubleshooting)

Pitfalls found by using flow in real work, with their fixes. Consumer
projects are anonymized to the A–D labels used in
`docs/superpowers/reviews/` (this repo is public).

## Install & update

- Dependencies in plugin.json must be scoped: a bare name resolves only
  inside its own marketplace. `["superpowers"]` did not load; correct is
  `["superpowers@claude-plugins-official"]`.
- `install` printing "Successfully installed" ≠ the plugin will load —
  verify with `claude plugin list` (Status: enabled).
- `claude plugin update` requires the full name `flow@flow-skeleton`
  (install accepts the short one).
- Marketplace auto-update = the `autoUpdate` key in
  `~/.claude/plugins/known_marketplaces.json`; the UI toggle lives in the
  **marketplace** details, not the plugin's (a frequent miss).
- Which version a session holds: `.in_use/<pid>` markers in
  `~/.claude/plugins/cache/flow-skeleton/flow/<ver>/`.

## Desktop sessions

- "New session" can grab a pre-warmed spare process with the old plugin
  set → right after install/update the first "new" session may not see
  the plugin. Cure: **full app restart (⌘Q)**, not just a new session.
- Session transcripts are strictly local
  (`~/.claude/projects/<cwd-path>/*.jsonl`), keyed by the absolute
  project path, never synced between machines. Cross-machine continuity =
  cloud sessions (git + team snippet) or state carried through flow's git
  artifacts (spec / tasks / CLAUDE.md / CHANGELOG), never the transcript.
- The GUI app can "lose" a third-party-marketplace plugin while the CLI
  state stays healthy (seen on app 1.24012.x): official-marketplace
  plugins keep loading into sessions, the third-party one doesn't; the
  Plugins panel still shows it enabled with all its skills (the panel
  reads the registry) and its toggle stops reacting. Cure:
  `claude plugin uninstall` → `install` (re-registers the plugin through
  the app's current code path), then a full app restart — new sessions
  see the skills again. Diagnostic nuance: `.in_use/<pid>` markers in the
  plugin cache appear on the first actual skill use, not at session
  start, and can go stale — check pid liveness before trusting them.
- Escalation of the same failure (app 1.26832.x / CC 2.1.222, diagnosed
  2026-08-11): the drop is now persistent — reinstall + restart no
  longer cures. Everything owner-side is valid: settings enable the
  plugin, `claude plugin validate` passes plugin and marketplace
  manifests, `claude plugin list` shows enabled with no errors, and the
  SAME desktop-bundled binary run headless (`claude -p`) in the same
  project loads every flow skill. But desktop-assembled sessions mount
  only official-marketplace local plugins: the app logs "Passing N
  plugin(s) to SDK (… local: 15)" while the session's PATH carries bin/
  mounts for exactly the 14 official ones — the sole
  third-party-marketplace plugin is dropped between the count and the
  mount, with no error anywhere. Known upstream bug class:
  anthropics/claude-code #27049, #39897, #41514, #39400. Workarounds in
  order: (1) run flow-lifecycle sessions from terminal `claude` —
  unaffected, verified; (2) desktop sessions use the CLAUDE.md manual
  fallback (the session-start required-plugins check exists exactly for
  this); (3) per #39400, uploading the plugin as a zip through the
  desktop's own plugin UI bypasses the broken marketplace pipeline;
  (4) re-test after each app update. Quick per-session diagnostic:
  `echo $PATH | tr ':' '\n' | grep flow-skeleton` — mounted plugins add
  their bin/ to the session PATH.
- Closure (2026-08-12): the upstream drop was fixed by the app's
  auto-update to CC 2.1.227 — desktop sessions mount
  third-party-marketplace plugins again (proof: a dependency-free
  third-party plugin with hooks mounted immediately). The one plugin
  still missing after the fix turned out to be disabled the ordinary
  way: `"flow@flow-skeleton": false` in `~/.claude/settings.json` —
  almost certainly written by the Plugins-panel toggle, which was inert
  during the July breakage (clicking it then did nothing) and silently
  started WORKING after the app fix, so a diagnostic click flipped the
  plugin off. Diagnosis: `grep '"flow@flow-skeleton"' ~/.claude/settings.json`
  and the app log pair `[LocalPluginsReader] Found N` vs
  `[CCD] Passing … local: N-1`. Cure: `claude plugin enable
  flow@flow-skeleton` (or the UI toggle), then ⌘Q — new sessions can
  grab pre-warmed spares with the old plugin set. The 0.1.27
  cross-marketplace-dependency removal predates this closure and stands
  on its own grounds (three failure classes), but it was not the cause
  of the final drop.

## git-guard hook

- Grepping a raw bash string is unreliable — fix evolution: segments
  (v0.1.2), quotes (v0.1.3), refs/heads forms (v0.1.4). Final: guard on
  **python3 shlex** (stdlib, fail-open): quote-aware tokens, per-segment
  analysis, git-subcommand detection, +refspec/sudo/path-git/refs-heads
  coverage. 23 regression tests.
- The guard's boundary: a seatbelt against accidental model actions, NOT
  a security boundary (trivially bypassed by writing the command into a
  script file). Bar for new patterns: "can happen by accident", not "can
  be bypassed".

## Fable safeguard-fallback on crypto/security domains

- Fable's safeguards classifier (cybersecurity/biology) really does hand
  sessions to Opus mid-work — confirmed on a crypto codebase (project D)
  and constantly on project B. Server-side; cannot be disabled on Fable;
  not written to local logs — check the UI/transcript.
- Impact is asymmetric: uncritical for flow spec (the scripted stance
  carries design through), damaging for research passes — exactly the
  valuable security content gets flagged, silently continues on Opus,
  and the analysis comes out uneven and untrustworthy.
- The real solution is the trusted-access program (same engine without
  the safeguard measures, for approved orgs) via the Anthropic account
  team; the org's blockchain work is a legitimate case.
- Palliative without trusted access: make degradation visible — mark
  sections worked on Opus after a fallback ("Analyzed-on: Opus
  (fallback)") and re-verify them on Fable manually. Disabling
  auto-switch is not useful (pause/refusal, needs babysitting).
- Two modes depending on config: with auto-switch on, a flag = silent
  fallback to Opus and work continues; with "ask before switching", the
  same flag = hard block, no auto-Opus. Fallback is sticky: the session
  stays on Opus until a manual /model switch; the next flag drops it
  again.
- The trigger is topic **density**, not just "dangerous" code: a dense
  meta-discussion of the classifier itself gets flagged (confirmed: it
  blocked a request ABOUT the blocking mechanism); a crypto-colored
  session context keeps flagging to the session's end.
- Session-split rule: ops/coordination/diagnostics on **Opus** (doesn't
  need Fable's power, and crypto context blocks it); Fable only for
  actual research. A session that drifted into ops but stayed on Fable
  catches block after block.
- Fable sessions abort on reading a large crypto-colored artifact
  wholesale (3/3 attempts, abort right after the tool result, no error
  record) vs 6/6 successful blocks with targeted verification:
  claim-by-claim small greps/chunks, commit per block (nothing stranded
  on abort). Rule: don't load the artifact whole; verify pointwise;
  commit incrementally. Verified from transcripts: the aborts are
  aborts, NOT silent fallbacks.
- Model provenance is recovered from the transcript (`message.model` +
  timestamps → compress into windows → match to commit times), not from
  the session's self-assessment (it cannot see its per-turn model and
  underestimates — "assume everything was Opus").
- Resilience-grade commit splitting is ONLY for Fable research mode.
  Don't carry it into development: Opus doesn't abort, and splitting
  logical commits into crumbs is churn without benefit. Not needed in
  flow skills either: implement already commits per task (a logical
  unit), spec persists files to disk before any commit, and research is
  not a flow phase. The real principle: "emit results in small
  persistent units", not "commit more often".

## Skill invocation

- `disable-model-invocation` breaks prose-style invocation (removed in
  v0.1.5): the flag removes the skill from the model's toolkit, so
  "accept via /flow:accept" mid-message does nothing (slash expands only
  at message start). The explicit-owner-request rule moved into
  `description`; lifecycle skills stay model-invocable.
- Skill name collisions: another plugin's `code-review` can shadow the
  bundled `/code-review`. Ask for the built-in explicitly, or disable
  unused plugins to cut context noise.
