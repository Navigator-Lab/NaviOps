#!/usr/bin/env sh
# navi-report-watch.sh — auto-reveal every new/updated report in the editor, agent-independent.
#
# Watches docs/reports/ with inotify and, whenever a report file is finished being written to disk,
# opens it in the current Antigravity IDE window (via navi-reveal.sh). This does NOT depend on any
# agent remembering to run a command — it triggers on the real filesystem write, so it works the same
# whether the report was produced by Claude Code, Antigravity/Gemini, or edited by hand.
#
# Usage:  navi-report-watch.sh [repo-root]   (defaults to the git root / CWD)
# Needs:  inotify-tools  ->  sudo apt install -y inotify-tools

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WATCH="$ROOT/docs/reports"
REVEAL="$ROOT/.agent/bin/navi-reveal.sh"

command -v inotifywait >/dev/null 2>&1 || { echo "navi-report-watch: inotify-tools not installed (sudo apt install -y inotify-tools)" >&2; exit 1; }
[ -d "$WATCH" ] || { echo "navi-report-watch: no $WATCH to watch" >&2; exit 1; }
[ -x "$REVEAL" ] || { echo "navi-report-watch: missing $REVEAL" >&2; exit 1; }

echo "navi-report-watch: watching $WATCH -> reveal via $REVEAL" >&2

# close_write = a normal save finished; moved_to = atomic write-then-rename (many editors/tools do this).
inotifywait -m -r -e close_write -e moved_to --format '%w%f' "$WATCH" 2>/dev/null | while IFS= read -r f; do
  case "$f" in
    *.md) ;;                 # only markdown reports
    *) continue ;;
  esac
  case "$(basename "$f")" in
    INDEX.md) continue ;;    # the index updates on every report; reveal the actual card, not the index
  esac
  "$REVEAL" "$f"             # navi-reveal absolutizes + reuse-window; best-effort/non-fatal
done
