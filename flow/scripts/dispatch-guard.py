#!/usr/bin/env python3
"""flow dispatch-guard: one-shot seatbelt for the multi-agent discipline.

pre  (PreToolUse, matcher ^(Task|Agent)$): allow the first subagent
     dispatch of a session; on the second+ dispatch with no
     dispatching-parallel-agents invocation recorded, block ONCE (exit 2,
     stderr feeds the model), then never nag again this session.
post (PostToolUse, matcher ^Skill$): record invoked skill names.

Same philosophy as git-guard: a seatbelt against accidental process
skips, not an enforcement boundary. Fail-open on any parse or IO problem.
State: <tmpdir>/flow-dispatch-guard-<session_id>.json. Stdlib only.
"""
import json
import os
import sys
import tempfile

BLOCK_MESSAGE = (
    "flow dispatch-guard: second agent dispatch in this session without the "
    "superpowers dispatching-parallel-agents discipline. Invoke that skill "
    "first (one agent per independent problem domain, self-contained prompts, "
    "a git worktree per writing agent, independent verification of results — "
    "an agent's own success report is never evidence), then re-issue this "
    "dispatch. If these dispatches are not parallel work, just re-issue the "
    "call — this guard warns once per session."
)


def state_path(session_id):
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_")[:64]
    return os.path.join(
        tempfile.gettempdir(), "flow-dispatch-guard-%s.json" % (safe or "unknown")
    )


def load_state(path):
    try:
        with open(path, encoding="utf-8") as fh:
            state = json.load(fh)
        if isinstance(state, dict):
            state.setdefault("skills", [])
            state.setdefault("dispatches", 0)
            state.setdefault("warned", False)
            return state
    except Exception:
        pass
    return {"skills": [], "dispatches": 0, "warned": False}


def save_state(path, state):
    try:
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(state, fh)
        os.replace(tmp, path)
    except Exception:
        pass


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "pre"
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    if not isinstance(data, dict):
        return 0
    path = state_path(str(data.get("session_id", "")))
    state = load_state(path)

    if mode == "post":
        tool_input = data.get("tool_input")
        name = ""
        if isinstance(tool_input, dict):
            name = str(tool_input.get("skill", "") or tool_input.get("name", ""))
        if name and name not in state["skills"]:
            state["skills"].append(name)
            save_state(path, state)
        return 0

    state["dispatches"] += 1
    disciplined = any("dispatching-parallel-agents" in s for s in state["skills"])
    if state["dispatches"] >= 2 and not disciplined and not state["warned"]:
        state["warned"] = True
        save_state(path, state)
        print(BLOCK_MESSAGE, file=sys.stderr)
        return 2
    save_state(path, state)
    return 0


if __name__ == "__main__":
    sys.exit(main())
