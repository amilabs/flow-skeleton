#!/bin/sh
# Wrapper so the hook works regardless of python3 shim differences.
exec python3 "$(dirname "$0")/dispatch-guard.py" "$@"
