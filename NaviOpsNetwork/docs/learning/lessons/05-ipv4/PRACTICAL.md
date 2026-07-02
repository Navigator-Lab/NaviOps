# Lesson 05 — Pure Practical: IPv4

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `docker exec -it clab-h1 bash`; net_a 10.10.1.0/24. **Rules:** type it, diagnose
> before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: address classes, private ranges & ARP (fluency)

**Scenario.** `NOC-051`. Identify the class/scope of the lab addresses and watch ARP resolve an IPv4 to
a MAC — the L3↔L2 glue.

**Objective.** Classify `10.10.1.0/24` (private, RFC-1918) and capture an ARP request/reply.

**Given / constraints.** Read-only. Use `ip neigh` + `tcpdump`.

**Hints.**
1. `10.x` = RFC-1918 private. Confirm scope, not just class.
2. Flush + re-resolve: `ip neigh flush all; ping -c1 10.10.1.1; ip neigh`.
3. Capture: `tcpdump -ni eth0 arp` while pinging a fresh neighbor.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'ip neigh flush all; ping -c1 10.10.1.1 >/dev/null; ip neigh' | grep -q lladdr && echo "ARP RESOLVED ✅"
```

**Pitfalls.**
- Confusing private vs public ranges.
- Thinking ARP is L3 — it's the L2/L3 bridge.
- Stale ARP cache masking a change.

🎯 **Stretch.** Observe gratuitous ARP and explain its purpose (IP takeover / dup detection).

---

## Task 2 — Ticket-driven: "duplicate IP / intermittent connectivity" (diagnose → fix)

**Scenario.** `NOC-052` (P2). *"A host has flaky connectivity — sometimes works, sometimes not."*
Suspect an IP conflict. Find and resolve it.

**Objective.** Detect the duplicate address and fix it so the host is stable.

**Given / constraints.** Simulate: assign 10.10.1.10 to two interfaces/hosts. Fix by re-addressing.

**Hints.**
1. `arping -D 10.10.1.10` (duplicate address detection) — two MACs replying = conflict.
2. `ip neigh` flapping between MACs is the tell.
3. Re-address one host to a free IP; re-test.

✅ **Verify.**
```bash
docker exec clab-h1 arping -c3 -D 10.10.1.10 2>&1 | grep -qi 'conflict\|Received 0' && echo "checked"
docker exec clab-h1 ping -c3 10.10.1.1 | grep -q '0% packet loss' && echo "STABLE ✅"
```

**Pitfalls.**
- Blaming the switch/cable for what's an IP conflict.
- Fixing one host but leaving the duplicate on another.
- Not using DAD to confirm before/after.

🎯 **Stretch.** Explain how DHCP + proper IPAM prevents this class of problem.

---

## Task 3 — On-call: exhausted address space / rogue host (synthesis)

**Scenario.** `NOC-053` (time-boxed). A segment is "full" or a rogue device appeared. Audit live IPs
vs the plan, find the free/rogue addresses, and document.

**Objective.** Produce a live-vs-planned address audit for `10.10.1.0/24`, flag anomalies, recommend.

**Given / constraints.** Non-destructive discovery. Compare against the intended allocation.

**Hints.**
1. `nmap -sn 10.10.1.0/24` for live IPs; `arp -n` for MACs.
2. Diff against the expected list; unexpected IP/MAC = rogue.
3. Note free addresses and any conflicts.

✅ **Verify.**
```bash
docker exec clab-h1 nmap -sn 10.10.1.0/24 | grep -c 'Host is up'
test -f docs/learning/reports/NOC-053-ip-audit.md && echo "AUDIT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-053-ip-audit.md`: live IPs/MACs · free · rogue/anomaly · action.

**Pitfalls.**
- No baseline to diff against → can't spot a rogue.
- Trusting IP alone (spoofable) — record MAC too.
- Aggressive scanning without authorization.

🎯 **Stretch.** Propose a DHCP scope + reservations that would end manual IP tracking.

---

## Done?
- [ ] All ✅ Verify pass · [ ] DAD used for the conflict · [ ] IP audit written.
- [ ] **Guardrails:** lab ranges only. → [README Reflection](./README.md).
