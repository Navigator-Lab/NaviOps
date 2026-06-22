#!/usr/bin/env bash
# dns_check.sh — compare local vs public resolver for a name, flag SERVFAIL / mismatch.
# NaviOpsNetwork · Lesson 13 (DNS). The synthetic check a NOC runs to isolate "it's always DNS".
#
# Usage: ./dns_check.sh <name> [public_resolver]
#   e.g. ./dns_check.sh example.com 9.9.9.9
# Exits: 0 = OK, 2 = SERVFAIL/NXDOMAIN, 3 = local/public answer mismatch.
set -euo pipefail

name="${1:?usage: dns_check.sh <name> [public_resolver]}"
pub="${2:-9.9.9.9}"

local_ns=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf 2>/dev/null || true)
local_ns="${local_ns:-127.0.0.53}"

local_ans=$(dig +short "$name" @"$local_ns" 2>/dev/null || true)
pub_ans=$(dig +short "$name" @"$pub" 2>/dev/null || true)
status=$(dig "$name" +noall +comments 2>/dev/null | sed -n 's/.*status: \([A-Z]*\).*/\1/p' | head -n1)
status="${status:-UNKNOWN}"

echo "name=$name  status=$status  local_resolver=$local_ns  public=$pub"
echo "  local : ${local_ans:-<none>}"
echo "  public: ${pub_ans:-<none>}"

case "$status" in
    SERVFAIL|NXDOMAIN)
        echo "ALERT: resolution failed ($status) — see Lesson 13 §4 decision flow"
        exit 2 ;;
esac

if [[ -n "$local_ans" && -n "$pub_ans" && "$local_ans" != "$pub_ans" ]]; then
    echo "WARN: local vs public answers differ — possible cache lag or split-horizon DNS"
    exit 3
fi

echo "OK: resolution healthy"
