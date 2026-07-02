# Lesson 10 — Pure Practical: Spanning Tree (STP)

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Linux bridges with STP (`ip link add br0 type bridge stp_state 1`) on a netshoot
> host (privileged). **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: enable STP and read the topology (fluency)

**Scenario.** `NOC-101`. STP prevents L2 loops by blocking redundant paths. Enable it on a bridge and
read root/port roles.

**Objective.** A bridge with STP on; identify the root bridge and port states.

**Given / constraints.** `bridge` tooling; STP enabled.

**Hints.**
1. `ip link add br0 type bridge stp_state 1; ip link set br0 up`.
2. `bridge -d link show` / `cat /sys/class/net/br0/bridge/stp_state`.
3. Root bridge = lowest bridge ID (priority+MAC).

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'ip link add br0 type bridge stp_state 1 2>/dev/null; cat /sys/class/net/br0/bridge/stp_state' | grep -q 1 && echo "STP ON ✅"
```

**Pitfalls.**
- Assuming STP is on by default (often off on Linux bridges).
- Confusing bridge priority with port cost.
- Not knowing which device is root (determines the tree).

🎯 **Stretch.** Explain port states (blocking/listening/learning/forwarding) and convergence time.

---

## Task 2 — Ticket-driven: "a link is blocked / suboptimal path" (diagnose → fix)

**Scenario.** `NOC-102` (P2). *"Traffic takes a slow path; a faster link seems unused."* STP blocked a
port or elected a poor root. Diagnose and influence the tree.

**Objective.** Make STP choose the intended root/path by adjusting priority/cost — diagnose first.

**Given / constraints.** Adjust bridge priority / port cost. Don't disable STP.

**Hints.**
1. Who's root? Lowest priority wins. Set the intended device lower (`bridge/priority`).
2. Port cost influences which redundant link forwards.
3. Re-read the tree after the change.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'echo 4096 > /sys/class/net/br0/bridge/priority 2>/dev/null; cat /sys/class/net/br0/bridge/priority'   # lowered priority
echo "adjust + observe root election"
```

**Pitfalls.**
- Disabling STP to "speed things up" → reintroduces loop risk.
- Changing cost without understanding which port forwards.
- Leaving a random device as root (unpredictable paths).

🎯 **Stretch.** Compare classic STP vs RSTP convergence and why RSTP is preferred.

---

## Task 3 — On-call: a loop took down the segment (synthesis)

**Scenario.** `NOC-103` (P1, time-boxed). Someone patched a redundant cable with STP disabled → a loop
→ broadcast storm → segment down. Restore stability and document the fix (re-enable STP / break loop).

**Objective.** Identify the loop signature, stop the storm, re-enable STP, verify stability, and write
an incident note.

**Given / constraints.** Reason from broadcast-rate evidence (don't wedge the lab). Fix = STP on / one
path removed.

**Hints.**
1. Storm signature: broadcast rate spikes (`tcpdump 'broadcast'`), counters climb.
2. Immediate: remove the redundant link (break the loop); durable: enable STP.
3. Confirm broadcast rate returns to baseline.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'cat /sys/class/net/br0/bridge/stp_state' | grep -q 1 && echo "STP ENABLED ✅"
test -f docs/learning/reports/NOC-103-loop.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NOC-103-loop.md`: Impact · Detection (broadcast rate) · Root cause (loop, STP off) · Fix · Prevention (BPDU guard).

**Pitfalls.**
- Rebooting switches instead of breaking the loop / enabling STP.
- Not recognizing the broadcast-storm signature.
- No prevention (BPDU guard / portfast discipline) → recurs.

🎯 **Stretch.** Explain how BPDU guard on access ports prevents this exact incident.

---

## Done?
- [ ] All ✅ Verify pass · [ ] influenced the tree deliberately · [ ] loop postmortem written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
