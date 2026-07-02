# Lesson 11 — Pure Practical: EtherChannel / Link Aggregation

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Linux bonding on a netshoot host (`ip link add bond0 type bond`) models
> EtherChannel/LACP. **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: bond two links for bandwidth + redundancy (fluency)

**Scenario.** `NOC-111`. Aggregate two interfaces into one logical link for more throughput and
failover.

**Objective.** A `bond0` with two enslaved interfaces, up, in an aggregating mode.

**Given / constraints.** Use LACP (802.3ad) or balance mode. Both members enslaved.

**Hints.**
1. `ip link add bond0 type bond mode 802.3ad`; enslave: `ip link set eth1 master bond0` (×2); `ip link set bond0 up`.
2. `cat /proc/net/bonding/bond0` shows members + mode.
3. Address the bond, not the members.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'cat /proc/net/bonding/bond0 2>/dev/null | grep -c "Slave Interface"'   # ≥2
```

**Pitfalls.**
- Addressing member interfaces instead of the bond.
- Mode mismatch between the two ends (LACP vs static).
- Expecting a single flow to exceed one member's speed (hashing spreads *flows*, not a single stream).

🎯 **Stretch.** Compare LACP (dynamic) vs static aggregation and the risk of a silent misconfig.

---

## Task 2 — Ticket-driven: "the bond isn't aggregating / one link dead" (diagnose → fix)

**Scenario.** `NOC-112` (P2). *"We bonded two links but throughput/redundancy isn't there."* One member
is down or the mode is wrong. Find it.

**Objective.** Restore full aggregation with both members active — diagnose first.

**Given / constraints.** Recreate: down one member, or a mode mismatch. Fix the specific cause.

**Hints.**
1. `cat /proc/net/bonding/bond0` — member status (up/down), MII status, LACP state.
2. A down member = degraded but working (that's failover doing its job); wrong mode = no aggregation.
3. Bring the member up / align the mode.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'grep -c "MII Status: up" /proc/net/bonding/bond0'   # both members up
```

**Pitfalls.**
- Thinking a degraded-but-up bond is "broken" (it survived a failure — good).
- LACP on one side, static on the other → no bundle.
- Missing that hashing means one flow won't use both links.

🎯 **Stretch.** Test failover: down one member mid-ping and confirm zero/near-zero loss.

---

## Task 3 — On-call: member failure during peak (synthesis)

**Scenario.** `NOC-113` (time-boxed). A physical link in the bundle fails at peak. Confirm the bond
failed over cleanly, assess degraded capacity, and document.

**Objective.** Verify failover kept traffic up, quantify the capacity loss, and write a note.

**Given / constraints.** Down a member during continuous traffic; measure loss; restore.

**Hints.**
1. Continuous ping/iperf while you down a member; loss should be minimal.
2. Degraded capacity = remaining members' bandwidth; note it.
3. Restore the member; confirm re-aggregation.

✅ **Verify.**
```bash
docker exec clab-h1 sh -c 'ip link set eth1 nomaster 2>/dev/null; sleep 2; grep -c "MII Status: up" /proc/net/bonding/bond0'
test -f docs/learning/reports/NOC-113-bond-failover.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-113-bond-failover.md`: event · loss during failover · degraded capacity · recovery.

**Pitfalls.**
- No monitoring on member state → a silently-degraded bond runs on one link until the second fails.
- Not sizing for N-1 (bundle can't carry peak on remaining members).
- Forgetting to re-enslave the recovered member.

🎯 **Stretch.** Add an alert on `MII Status` so a single-member failure pages you before the second drops.

---

## Done?
- [ ] All ✅ Verify pass · [ ] failover tested · [ ] degraded-capacity note written.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
