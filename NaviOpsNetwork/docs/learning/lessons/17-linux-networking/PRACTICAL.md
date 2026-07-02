# Lesson 17 — Pure Practical: Linux Networking

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it clab-h1 bash` (netshoot: `ip`, `ss`, `ethtool`, `tc`). **Rules:**
> type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: the modern `ip`/`ss` toolkit (fluency)

**Scenario.** `NOC-171`. Master the commands that replaced `ifconfig`/`netstat` — the daily Linux net toolkit.

**Objective.** Read addresses, routes, neighbors, sockets, and link stats with `ip`/`ss`.

**Given / constraints.** No `ifconfig`/`netstat`. Use `ip`/`ss`.

**Hints.**
1. `ip -br addr`, `ip route`, `ip neigh`, `ip -s link` (stats).
2. `ss -tulpn` (listening sockets + pids), `ss -ti` (TCP internals).
3. Map each old command to its modern equivalent.

✅ **Verify.**
```bash
docker exec clab-h1 ss -tulpn | grep -q . && echo "SOCKETS ✅"
docker exec clab-h1 ip -s link show eth0 | grep -qi rx && echo "LINK STATS ✅"
```

**Pitfalls.**
- Reaching for `ifconfig`/`netstat` (deprecated, may be absent).
- Not using `-p` to tie a socket to a process.
- Ignoring interface error counters.

🎯 **Stretch.** Persist a config with the distro's method (netplan/NetworkManager) vs runtime `ip`.

---

## Task 2 — Ticket-driven: "interface errors / poor throughput" (diagnose → fix)

**Scenario.** `NOC-172` (P2). *"A link is slow and flaky."* Check for L1/L2 errors, MTU, and duplex —
diagnose before blaming the network.

**Objective.** Identify the physical/link cause (errors, MTU mismatch) and correct it.

**Given / constraints.** Recreate an MTU mismatch (`ip link set eth0 mtu 1400`) or read error counters.
Fix the mismatch.

**Hints.**
1. `ip -s link` — rx/tx errors, drops, overruns. `ethtool eth0` — speed/duplex.
2. MTU mismatch → large packets fail (small ping ok, big ping fails): `ping -M do -s 1472`.
3. Correct MTU/duplex to match the path.

✅ **Verify.**
```bash
docker exec clab-h1 ip link show eth0 | grep -q 'mtu 1500' && echo "MTU CORRECT ✅"
docker exec clab-h1 ping -M do -s 1472 -c2 10.10.1.1 >/dev/null && echo "NO FRAG ISSUE ✅"
```

**Pitfalls.**
- MTU mismatch shows as "works small, fails big" — easy to misdiagnose.
- Ignoring rising error counters.
- Duplex mismatch causing collisions/slowness.

🎯 **Stretch.** Find the path MTU with incremental `ping -M do` sizes.

---

## Task 3 — On-call: a host is flooding / saturating its link (synthesis)

**Scenario.** `NOC-173` (time-boxed). One host's NIC is saturated; find which process/flow and contain
it, then document.

**Objective.** Identify the top talker (process + peer), throttle or stop it, and write a note.

**Given / constraints.** Use `ss`, `iftop`/`nethogs` if present, or `tc` to shape. Contain the specific
flow.

**Hints.**
1. `ss -tp` (which process), `iftop`/`nethogs` for per-flow bandwidth.
2. Contain: stop the process or `tc` rate-limit the interface.
3. Confirm the link load drops.

✅ **Verify.**
```bash
docker exec clab-h1 ss -tp | head; echo "top talkers identified"
test -f docs/learning/reports/NOC-173-saturation.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-173-saturation.md`: top talker · flow · action · prevention.

**Pitfalls.**
- Throttling the whole interface when one flow is the problem.
- No per-process visibility (`ss -p`) → guessing.
- Leaving a `tc` shaping rule in place.

🎯 **Stretch.** Write a small script that flags when a host's tx exceeds a threshold.

---

## Done?
- [ ] All ✅ Verify pass · [ ] used `ip`/`ss` throughout · [ ] saturation note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
