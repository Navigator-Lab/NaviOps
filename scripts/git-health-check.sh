#! /usr/bin/env bash
# git-health-check.sh - NaviOps Lesson 02
# Reports Basic Git repo health: branch, last commit, uncomitted changes, remotes.
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Error: not inside a git repositroy" >&2; exit 1  }

