#!/usr/bin/env sh
# navi-reveal.sh — reveal a Navi report in the CURRENT editor window (Antigravity IDE / any VS Code fork).
#
# Agent-agnostic (Claude Code · Antigravity/Gemini · Cursor · …) and best-effort/non-fatal:
# if no editor CLI is found it exits 0 silently — the report file is always the real deliverable,
# the reveal is only a convenience. It reveals an existing file; it never creates or mutates content,
# so it does NOT breach the REPORT-ONLY guarantee of ENUM/MENTOR/EXP/REVIEW.
#
# Usage:  .agent/bin/navi-reveal.sh <path-to-report> [more paths...]
# Override the editor binary with NAVI_IDE_BIN=/abs/path if auto-detection ever misses.

[ "$#" -eq 0 ] && exit 0

# Resolve the editor CLI: explicit override → PATH (fork names) → known install locations.
IDE_BIN="${NAVI_IDE_BIN:-}"
if [ -z "$IDE_BIN" ]; then
  for c in antigravity-ide antigravity code cursor windsurf; do
    if command -v "$c" >/dev/null 2>&1; then IDE_BIN="$(command -v "$c")"; break; fi
  done
fi
if [ -z "$IDE_BIN" ]; then
  for p in /opt/antigravity-ide/bin/antigravity-ide /usr/bin/antigravity-ide /usr/local/bin/antigravity-ide; do
    if [ -x "$p" ]; then IDE_BIN="$p"; break; fi
  done
fi
[ -z "$IDE_BIN" ] && exit 0   # no editor CLI on this host — nothing to reveal, not an error

# -r = --reuse-window: land the file in the window the human is already looking at (never spawn one).
# The path MUST be absolute — the editor CLI resolves relative paths against the Electron process's
# CWD, not ours, so a relative path silently opens nothing. This was the original reveal bug.
for f in "$@"; do
  [ -f "$f" ] || continue
  abs="$(readlink -f "$f" 2>/dev/null || echo "$f")"
  "$IDE_BIN" -r "$abs" >/dev/null 2>&1 || true
done
exit 0
