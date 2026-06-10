#!/usr/bin/env bash
# Pre-commit hook: block commits containing secrets (per .gitleaks.toml).
# Install once: ln -sf ../../scripts/pre-commit-gitleaks.sh .git/hooks/pre-commit
set -euo pipefail

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "WARNING: gitleaks not installed — skipping secret scan." >&2
  echo "Install: https://github.com/gitleaks/gitleaks#installing" >&2
  exit 0
fi

gitleaks protect --staged --redact --config "$(git rev-parse --show-toplevel)/.gitleaks.toml"
