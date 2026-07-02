# Lesson 07 — Pure Practical: Routing Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** the FRR topology — `clab-r1`/`clab-r2` (routers, `vtysh`), `clab-h1` (10.10.1.10)
> / `clab-h2` (10.10.2.10). This is the lab's headline exercise (see [`infra/LAB.md`](../../../../infra/LAB.md)).
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: make h1 reach h2 with OSPF (fluency)

**Scenario.** `NOC-071`. Out of the box, h1 can't reach h2 (different subnets, no routing). Bring up
OSPF on both routers and point the hosts at them.

**Objective.** OSPF adjacency FULL between r1↔r2; h1 ↔ h2 ping works end to end.

**Given / constraints.** Configure via `vtysh`; `write memory`. Follow the layered verify (adjacency →
routes → ping → path).

**Hints.**
1. On r1: `router ospf` → `network 10.10.1.0/24 area 0` + `network 10.0.0.0/24 area 0`. Same on r2 with its nets.
2. Hosts default to the docker gateway — repoint: `docker exec clab-h1 ip route replace default via 10.10.1.1` (and h2 via 10.10.2.1).
3. Verify bottom-up (neighbor → route → ping → traceroute).

✅ **Verify.**
```bash
docker exec clab-r1 vtysh -c "show ip ospf neighbor" | grep -qi full && echo "ADJACENCY FULL ✅"
docker exec clab-r1 vtysh -c "show ip route ospf" | grep -q 10.10.2.0 && echo "ROUTE LEARNED ✅"
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "H1→H2 ✅"
```

**Pitfalls.**
- Forgetting to repoint host default routes (routers converge but hosts still use the wrong gateway).
- Wrong `network` statements / area mismatch → no adjacency.
- Not `write memory` → lost on restart.

🎯 **Stretch.** `traceroute` h1→h2 and confirm the path is h1→r1→r2→h2.

---

## Task 2 — Ticket-driven: "remote subnet unreachable" (diagnose → fix)

**Scenario.** `NOC-072` (P2). *"h1 can reach its own subnet but not h2's."* The classic "local works,
remote doesn't" — a routing problem. Find where it breaks.

**Objective.** Restore h1↔h2, identifying whether it's a host default route, an OSPF adjacency drop, or
a missing route.

**Given / constraints.** Recreate: drop r1's core interface (`ip link set eth1 down`) or remove a host
route. Fix the specific break.

**Hints.**
1. Local ok + remote fail = L3 routing. `ip route` on the host; `show ip ospf neighbor` on r1.
2. Adjacency down? Check the core link. Missing host route? Re-add default.
3. Walk the path: where does `traceroute` stop?

✅ **Verify.**
```bash
docker exec clab-r1 vtysh -c "show ip ospf neighbor" | grep -qi full && echo "ADJ RESTORED ✅"
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "REMOTE OK ✅"
```

**Pitfalls.**
- Assuming "can't ping remote" = whole network down (it's just routing).
- Fixing the router but not the host's default route.
- Not checking OSPF neighbor state first.

🎯 **Stretch.** Add a floating static route as backup and reason about administrative distance vs OSPF.

---

## Task 3 — On-call: link failure + reconvergence (synthesis)

**Scenario.** `NOC-073` (P1, time-boxed). The core link flaps; traffic between sites drops and returns.
Observe OSPF reconvergence, confirm recovery, and document the outage window.

**Objective.** Induce the failure, measure the loss/reconvergence, verify auto-recovery, and write an
incident note with the timeline.

**Given / constraints.** `ip link set eth1 down` on r1, watch, then `up`. Don't hard-reset the routers.

**Hints.**
1. Continuous ping h1→h2 in one pane; drop the core link; watch loss then recovery when OSPF reconverges.
2. `show ip ospf neighbor` transitions (FULL → down → FULL).
3. Note time-to-drop and time-to-recover.

✅ **Verify.**
```bash
docker exec clab-r1 sh -c 'ip link set eth1 down; sleep 3; ip link set eth1 up'
sleep 15; docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "RECONVERGED ✅"
test -f docs/learning/reports/NOC-073-reconvergence.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NOC-073-reconvergence.md`: Impact · Timeline · Root cause · Recovery · Prevention.

**Pitfalls.**
- Panicking during the (normal) reconvergence window instead of letting OSPF heal.
- Not measuring the outage window (the number the business cares about).
- Leaving the interface down.

🎯 **Stretch.** Tune OSPF hello/dead timers and measure the reconvergence improvement.

---

## Done?
- [ ] All ✅ Verify pass · [ ] verified bottom-up · [ ] reconvergence timed + documented.
- [ ] **Guardrails:** lab only; no real device creds. → [README Reflection](./README.md).
