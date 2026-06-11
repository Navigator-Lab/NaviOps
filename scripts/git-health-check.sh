#!/usr/bin/env bash
# git-health-check.sh — NaviOps Lesson 02
# Reports basic Git repo health: branch, last commit, uncommitted changes, remotes.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERROR: not inside a git repository" >&2; exit 1
}

echo "=== Git Health Check: $REPO_ROOT ==="
echo ""
echo "Branch:      $(git rev-parse --abbrev-ref HEAD)"
echo "Last commit: $(git log -1 --format='%h %s (%ar)' 2>/dev/null || echo 'no commits yet')"
echo "Status:"
git status --short || true
echo ""
echo "Remotes:"
git remote -v 2>/dev/null || echo "  (none configured)"
echo ""
echo "Stash count: $(git stash list 2>/dev/null | wc -l)"
echo "Unpushed commits vs origin/main:"
git log origin/main..HEAD --oneline 2>/dev/null || echo "  (no remote to compare)"
