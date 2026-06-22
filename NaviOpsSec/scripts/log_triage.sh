#!/usr/bin/env bash
# log_triage.sh — first-pass Linux security log triage. NaviOpsSec Lesson 01/05.
# Read-only: summarizes auth/login/sudo/process/network signal an analyst checks first.
# Lab/self-owned hosts only. Redact before committing any output (see LEARNING_STATE.md).
set -euo pipefail

AUTH_LOG="${AUTH_LOG:-/var/log/auth.log}"   # Debian/Ubuntu; RHEL = /var/log/secure
[ -r "$AUTH_LOG" ] || AUTH_LOG="/var/log/secure"

hr() { printf '\n== %s ==\n' "$1"; }

hr "Failed logins by source IP (top 10)"
if [ -r "$AUTH_LOG" ]; then
  grep -a "Failed password" "$AUTH_LOG" 2>/dev/null \
    | grep -aoE 'from [0-9]+(\.[0-9]+){3}' | awk '{print $2}' \
    | sort | uniq -c | sort -rn | head -10 || echo "  (none)"
else
  echo "  auth log not readable: $AUTH_LOG"
fi

hr "Accepted logins by source IP (top 10)"
grep -a "Accepted " "$AUTH_LOG" 2>/dev/null \
  | grep -aoE 'from [0-9]+(\.[0-9]+){3}' | awk '{print $2}' \
  | sort | uniq -c | sort -rn | head -10 || echo "  (none)"

hr "Recent sudo usage (last 10)"
grep -a "sudo:" "$AUTH_LOG" 2>/dev/null | tail -10 || echo "  (none)"

hr "Failed login history (lastb, last 10)"
command -v lastb >/dev/null 2>&1 && (lastb 2>/dev/null | head -10 || true) || echo "  lastb unavailable"

hr "Listening sockets (potential foothold / unexpected services)"
ss -tulnp 2>/dev/null || ss -tuln

hr "Processes with a network connection (quick reverse-shell sweep)"
# parent/child + state; analyst confirms anything spawned from a service shell
ps -eo pid,ppid,user,comm,args --sort=ppid 2>/dev/null | awk 'NR==1 || /sh|bash|nc|socat|python|perl/' | head -20

# TODO (operator): add new-user diff vs a committed baseline of /etc/passwd;
# TODO: flag exec from /tmp or /dev/shm; emit non-zero exit if a hard IOC is matched.
