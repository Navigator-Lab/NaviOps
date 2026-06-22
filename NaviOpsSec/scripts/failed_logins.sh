#!/usr/bin/env bash
# failed_logins.sh — count + threshold SSH failed logins by source IP. NaviOpsSec Lesson 18.
# Surfaces brute-force candidates from auth.log. Read-only. Lab/self-owned hosts only.
# Exit 2 if any source IP exceeds the brute-force threshold (for use in a cron/alert hook).
set -euo pipefail

AUTH_LOG="${AUTH_LOG:-/var/log/auth.log}"
[ -r "$AUTH_LOG" ] || AUTH_LOG="/var/log/secure"
THRESHOLD="${THRESHOLD:-10}"   # failed attempts from one IP to flag as brute force

[ -r "$AUTH_LOG" ] || { echo "auth log not readable: $AUTH_LOG" >&2; exit 1; }

echo "== Failed SSH logins by source IP (threshold=${THRESHOLD}) =="
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

grep -a "Failed password" "$AUTH_LOG" \
  | grep -aoE 'from [0-9]+(\.[0-9]+){3}' | awk '{print $2}' \
  | sort | uniq -c | sort -rn > "$tmp"

cat "$tmp"

flagged=0
while read -r count ip; do
  [ -z "${ip:-}" ] && continue
  if [ "$count" -ge "$THRESHOLD" ]; then
    echo "  [ALERT] $ip — $count failed attempts (>= $THRESHOLD) — possible brute force (T1110)"
    flagged=1
  fi
done < "$tmp"

# Did any flagged IP also succeed? (failed-then-accepted = likely compromise — escalate)
if [ "$flagged" -eq 1 ]; then
  echo "== Cross-check: did a flagged IP also log in successfully? =="
  grep -a "Accepted " "$AUTH_LOG" \
    | grep -aoE 'from [0-9]+(\.[0-9]+){3}' | awk '{print $2}' | sort -u
fi

[ "$flagged" -eq 1 ] && exit 2 || exit 0
