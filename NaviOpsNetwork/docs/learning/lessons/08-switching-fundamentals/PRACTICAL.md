# Lesson 08 — Pure Practical: Switching Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** netshoot hosts on a bridged L2 segment (`clab-h1` and its `net_a` bridge);
> use a Linux bridge to model a switch. **Rules:** type it, diagnose before you fix, run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: MAC learning on a bridge (fluency)

**Scenario.** `NOC-081`. A switch is a MAC-learning bridge. See the forwarding table (CAM) populate as
hosts talk.

**Objective.** Observe MAC addresses being learned and mapped to ports on a Linux bridge.

**Given / constraints.** Use `bridge fdb`/`brctl showmacs` on the docker bridge or a bridge you create.

**Hints.**
1. `docker network inspect net_a` shows the bridge; `ip -br link` for MACs.
2. On the host bridge (needs privilege): `bridge fdb show` — MAC↔port entries.
3. Generate traffic (ping) and watch the table populate/age.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c1 10.10.1.1 >/dev/null; echo "traffic sent"
docker exec clab-h1 ip -br link | grep -q 'ether' && echo "MAC PRESENT ✅"
```

**Pitfalls.**
- Confusing the MAC (L2, per-NIC) with the IP (L3).
- Thinking a switch routes — it forwards by MAC within a broadcast domain.
- Ignoring CAM aging (entries expire).

🎯 **Stretch.** Explain what happens on an unknown-unicast (flooding) vs a known MAC (forward).

---

## Task 2 — Ticket-driven: "two hosts on the same segment can't talk" (diagnose → fix)

**Scenario.** `NOC-082` (P2). *"Same subnet, same switch, but no connectivity between two hosts."* An
L2 problem — find it.

**Objective.** Restore L2 connectivity, identifying an interface-down, wrong bridge membership, or MAC
filtering issue.

**Given / constraints.** Recreate: one host's iface down, or a host on the wrong bridge/subnet. Fix at
L2.

**Hints.**
1. Both up? `ip -br link`. Same segment/bridge? `docker network inspect net_a`.
2. ARP resolving between them? `ip neigh` — no MAC = L2 break.
3. Fix membership/link; confirm ARP then ping.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'ping -c1 10.10.1.1 >/dev/null; ip neigh' | grep -q lladdr && echo "L2 OK ✅"
```

**Pitfalls.**
- Debugging L3/routing for a same-subnet (pure L2) problem.
- Host silently on a different bridge/subnet.
- Stale ARP hiding the real state.

🎯 **Stretch.** Explain the difference between a collision domain and a broadcast domain here.

---

## Task 3 — On-call: broadcast storm / loop symptoms (synthesis)

**Scenario.** `NOC-083` (time-boxed). A segment is saturated and everything's slow — classic L2 loop /
broadcast storm signature. Detect the flood, reason about the cause, and document (STP is the fix —
Lesson 10).

**Objective.** Detect abnormal broadcast/traffic levels, identify the loop signature, and write a note
recommending STP.

**Given / constraints.** Observe with `tcpdump` broadcast counts; reason (don't actually build a
loop that wedges the lab). Document.

**Hints.**
1. `tcpdump -ni eth0 'broadcast or multicast'` — abnormal volume = storm.
2. Interface counters climbing fast (`ip -s link`) with no legit load.
3. Root cause of a real storm = an L2 loop with no STP.

✅ **Verify.**
```bash
docker exec clab-h1 timeout 3 tcpdump -ni eth0 'broadcast or multicast' 2>/dev/null | wc -l   # baseline count
test -f docs/learning/reports/NOC-083-l2-storm.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-083-l2-storm.md`: symptom · evidence (broadcast rate) · suspected loop · fix (STP).

**Pitfalls.**
- Chasing "slow hosts" instead of the L2 flood underneath.
- Building an actual loop without STP and taking down the lab.
- Not connecting the symptom to the STP solution.

🎯 **Stretch.** Preview Lesson 10: how STP blocks a redundant port to break the loop.

---

## Done?
- [ ] All ✅ Verify pass · [ ] stayed at L2 for Task 2 · [ ] storm note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
