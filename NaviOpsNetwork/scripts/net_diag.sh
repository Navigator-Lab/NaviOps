#!/usr/bin/env bash
# net_diag.sh — bottom-up Linux network snapshot (L1 -> L4).
# NaviOpsNetwork · Lesson 01 (Networking Fundamentals), grown in Lesson 17.
#
# Prints interface/MAC (L1/L2), addresses + routes (L3), ARP table (L2),
# and listening sockets (L4). Exits non-zero if there is no default route.
#
# Usage: ./net_diag.sh
# Output is safe to paste into a ticket AFTER redaction (see LEARNING_STATE.md).
set -euo pipefail

hr() { printf '== %s ==\n' "$1"; }

hr "L1/L2: interfaces & MAC"; ip -br link
hr "L3: addresses";          ip -br addr
hr "L3: routes";             ip route show
hr "L2: ARP / neighbours";   ip neigh show
hr "L4: listening sockets";  ss -tuln

hr "default-route check"
if ip route show default | grep -q '^default'; then
    gw=$(ip route show default | awk '{print $3; exit}')
    echo "OK: default gateway is $gw"
    if ping -c1 -W2 "$gw" >/dev/null 2>&1; then
        echo "OK: gateway $gw reachable"
    else
        echo "WARN: gateway $gw not responding to ping (may be ICMP-filtered)"
    fi
else
    echo "FAIL: no default route — host can reach its own subnet only"
    exit 1
fi
