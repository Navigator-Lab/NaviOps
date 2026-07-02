# Lesson 31 — Pure Practical: High Availability

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** keepalived/VRRP between two containers to model a floating VIP; the topology for
> path redundancy. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a floating VIP with VRRP (fluency)

**Scenario.** `NOC-311`. Two nodes share a virtual IP; if the master dies, the backup takes it over —
the core of HA.

**Objective.** A VIP owned by the master; killing the master moves the VIP to the backup automatically.

**Given / constraints.** keepalived (VRRP) on two nodes; distinct priorities.

**Hints.**
1. keepalived config: `vrrp_instance` with a shared `virtual_ipaddress`, master higher priority.
2. Confirm the VIP is on the master (`ip addr`).
3. Stop the master → VIP appears on the backup.

✅ **Verify.**
```bash
# VIP present on exactly one node; after killing master it moves:
docker exec <backup> ip addr | grep -q <vip> && echo "FAILOVER TOOK VIP ✅"
```

**Pitfalls.**
- Both nodes claiming master (VRRP not communicating → split-brain).
- VIP outside the subnet.
- No preemption policy decided (flapping on recovery).

🎯 **Stretch.** Add a health-check script so the VIP moves when the *service* fails, not just the node.

---

## Task 2 — Ticket-driven: "failover didn't happen / split-brain" (diagnose → fix)

**Scenario.** `NOC-312` (P2). The master died but the VIP didn't move (or both hold it). Fix the HA.

**Objective.** Restore correct single-owner failover, identifying VRRP comms, priority, or auth issues —
diagnose first.

**Given / constraints.** Recreate: block VRRP multicast / equal priorities. Fix the cause.

**Hints.**
1. VRRP adverts flowing? (multicast 224.0.0.18). Priorities distinct? Auth matching?
2. Split-brain = peers can't see each other → both go master.
3. Fix comms/priority; confirm one owner.

✅ **Verify.**
```bash
# exactly one node holds the VIP:
echo "count of nodes holding <vip> should be 1"
```

**Pitfalls.**
- Blocked VRRP multicast → split-brain.
- Equal priorities → indeterminate master.
- Auth mismatch silently dropping adverts.

🎯 **Stretch.** Add fencing/STONITH reasoning: why split-brain is dangerous for stateful services.

---

## Task 3 — On-call: cascading failover during maintenance (synthesis)

**Scenario.** `NOC-313` (P1, time-boxed). A maintenance action triggered an unplanned failover cascade.
Stabilize, confirm the VIP/service is on a healthy node, and document with an HA-runbook improvement.

**Objective.** Stabilize ownership, verify service on a healthy node, and write a maintenance runbook so
it doesn't recur.

**Given / constraints.** Simulate a mistimed restart. Note preemption behavior.

**Hints.**
1. Where's the VIP now? Is the service actually healthy there?
2. Set/confirm preemption + maintenance mode to avoid flap during planned work.
3. Runbook: how to safely take a node out (backup-first, disable preempt).

✅ **Verify.**
```bash
docker exec <active> ip addr | grep -q <vip> && docker exec <active> curl -sf localhost:<port> >/dev/null && echo "STABLE + HEALTHY ✅"
test -f docs/learning/reports/NOC-313-ha-cascade.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-313-ha-cascade.md`: Impact · cause · fix · maintenance runbook.

**Pitfalls.**
- Taking the master down first (should drain/backup-first).
- Preemption causing flap on recovery.
- VIP healthy but the *service* behind it isn't.

🎯 **Stretch.** Add a graceful maintenance mode that hands off cleanly before a restart.

---

## Done?
- [ ] All ✅ Verify pass · [ ] single VIP owner · [ ] HA maintenance runbook written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
