#!/usr/bin/env python3
"""flow git-guard: blocks force-push to main/master and commit --no-verify.

Reads the PreToolUse hook JSON from stdin. Tokenizes the Bash command with
shlex (quote-aware) and splits it into pipeline/list segments, so words
inside string literals or neighboring commands cannot trigger the guard.
Fail-open: any parse or tooling problem allows the command through.
Stdlib only.
"""
import json
import os
import shlex
import subprocess
import sys

WRAPPERS = {"sudo", "command", "env", "nice", "time", "nohup", "xargs"}
SEPARATORS = {"&&", "||", ";", "|", "&"}
FORCE_FLAGS = {"-f", "--force", "--force-with-lease"}
PROTECTED = {"main", "master"}

PUSH_MESSAGE = ("force-push to main/master is blocked. Push a branch and "
                "open a PR, or have the owner run the command manually.")
NOVERIFY_MESSAGE = ("'git commit --no-verify' is blocked. Fix the failing "
                    "hook instead of bypassing it.")


def block(message):
    print(f"flow git-guard: {message}", file=sys.stderr)
    sys.exit(2)


def current_branch():
    try:
        out = subprocess.run(
            ["git", "-C", os.environ.get("CLAUDE_PROJECT_DIR", "."),
             "symbolic-ref", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        return out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        return ""


def git_subcommand(tokens):
    """Return (subcommand, remaining tokens) for a git segment, else (None, [])."""
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        is_env_prefix = ("=" in tok and not tok.startswith("-")
                         and tok.split("=", 1)[0].replace("_", "a").isalnum())
        if is_env_prefix or tok in WRAPPERS:
            i += 1
            continue
        break
    if i >= len(tokens) or os.path.basename(tokens[i]) != "git":
        return None, []
    i += 1
    while i < len(tokens):
        tok = tokens[i]
        if tok in ("-C", "-c"):  # git global options that take a value
            i += 2
            continue
        if tok.startswith("-"):
            i += 1
            continue
        return tok, tokens[i + 1:]
    return None, []


def check_push(rest):
    force = bool(FORCE_FLAGS & set(rest)) or any(
        t.startswith("--force-with-lease=") or t.startswith("--force=")
        for t in rest
    )
    positionals = [t for t in rest if not t.startswith("-")]
    refs = positionals[1:]  # first positional is the remote
    for ref in refs:
        name = ref.lstrip("+").split(":")[-1]
        if name.startswith("refs/heads/"):
            # Prefix-strip only: split("/")[-1] would false-block
            # branches like feature/main.
            name = name[len("refs/heads/"):]
        if (force or ref.startswith("+")) and name in PROTECTED:
            block(PUSH_MESSAGE)
    if force and not refs and current_branch() in PROTECTED:
        block(PUSH_MESSAGE)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if not cmd:
        sys.exit(0)
    try:
        tokens = shlex.split(cmd)
    except ValueError:
        sys.exit(0)

    segment = []
    segments = [segment]
    for tok in tokens:
        if tok in SEPARATORS:
            segment = []
            segments.append(segment)
        else:
            segment.append(tok)

    for seg in segments:
        sub, rest = git_subcommand(seg)
        if sub == "push":
            check_push(rest)
        elif sub == "commit" and "--no-verify" in rest:
            block(NOVERIFY_MESSAGE)


if __name__ == "__main__":
    main()
