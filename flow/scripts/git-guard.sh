#!/bin/bash
# flow git-guard — PreToolUse(Bash) hook (wrapper).
# Real parsing lives in git-guard.py: shlex-based, quote-aware, per-segment,
# so words inside string literals or neighboring commands never leak into
# the check. Fail-open: without python3 the guard allows everything.

command -v python3 >/dev/null 2>&1 || exit 0
exec python3 "$(dirname "$0")/git-guard.py"
