#!/usr/bin/env bash
# git-health-check.sh - print a labelled git repo health snapshot
set -euo pipefail

# --- Guard: must be inside a git repo -------------------
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "Error: not inside a git repositroy." >&2
	exit 1
}

# --- Report ---------------------------------------------
echo "Current branch  : $(git rev-parse --abbrev-ref HEAD)"
echo "Last commit     : $(git log -1 --format='%h %s (%ar)')"
echo "Working Tree    : $(git status --short | head -20 || echo '(Clean)')"
echo "Remotes         : $(git remote -v)"
echo "Stash count     : $(git stash list | wc -l)"
echo "Unpushed commits: $(git log origin/main..HEAD --oneline || echo '(none or no origin/main)')"
