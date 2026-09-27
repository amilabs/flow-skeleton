#!/usr/bin/env python3
"""flow git-guard: blocks force-push to protected branches and commit --no-verify.

Protected branches come from FLOW_PROTECTED_BRANCHES (comma-separated,
e.g. "main,develop"); unset or empty means main,master.

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
DEFAULT_PROTECTED = ("main", "master")


def protected_branches():
    raw = os.environ.get("FLOW_PROTECTED_BRANCHES", "")
    names = {n.strip() for n in raw.split(",") if n.strip()}
    return names or set(DEFAULT_PROTECTED)


PROTECTED = protected_branches()

PUSH_MESSAGE = ("force-push to a protected branch ("
                + ", ".join(sorted(PROTECTED)) + ") is blocked. Push a "
                "branch and open a PR, or have the owner run the command "
                "manually.")
NOVERIFY_MESSAGE = ("'git commit --no-verify' is blocked. Fix the failing "
                    "hook instead of bypassing it.")


def block(message):
    print(f"flow git-guard: {message}", file=sys.stderr)
    sys.exit(2)


def current_branch(cdir=None):
    """Branch checked out where the command runs: the project dir, or the
    `git -C` path resolved against it."""
    where = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    if cdir:
        where = os.path.join(where, cdir)  # an absolute cdir wins
    try:
        out = subprocess.run(
            ["git", "-C", where, "symbolic-ref", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        return out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        return ""


def git_subcommand(tokens):
    """Return (subcommand, remaining tokens, -C path) for a git segment,
    else (None, [], None). Repeated -C paths chain the way git chains them."""
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
        return None, [], None
    i += 1
    cdir = None
    while i < len(tokens):
        tok = tokens[i]
        if tok == "-C" or tok.startswith("-C="):
            if tok == "-C":
                path = tokens[i + 1] if i + 1 < len(tokens) else ""
                i += 2
            else:
                path = tok[len("-C="):]
                i += 1
            if path:
                path = os.path.expanduser(path)
                cdir = os.path.join(cdir, path) if cdir else path
            continue
        if tok == "-c":  # git global option that takes a value
            i += 2
            continue
        if tok.startswith("-"):
            i += 1
            continue
        return tok, tokens[i + 1:], cdir
    return None, [], None


def check_push(rest, cdir=None):
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
    if force and not refs and current_branch(cdir) in PROTECTED:
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
        sub, rest, cdir = git_subcommand(seg)
        if sub == "push":
            check_push(rest, cdir)
        elif sub == "commit" and "--no-verify" in rest:
            block(NOVERIFY_MESSAGE)


if __name__ == "__main__":
    main()
