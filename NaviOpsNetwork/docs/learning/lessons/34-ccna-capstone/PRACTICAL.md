# Lesson 34 — Pure Practical: CCNA Capstone

> **Companion to [`README.md`](./README.md).** The capstone is already hands-on; this adds 3 timed,
> exam-style build+troubleshoot drills that combine Lessons 01–33. **Lab:** full FRR topology
> (`clab-r1/r2`, `clab-h1/h2`). **Rules:** hands-on, timed, verify each. Run ✅ **Verify**.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: build the routed network from scratch (fluency)

**Scenario.** `NOC-341`. From a clean lab, deliver end-to-end reachability: addressing, OSPF, host
routes — the CCNA build core.

**Objective.** h1↔h2 works via OSPF; adjacency FULL; correct host default routes. Timed.

**Given / constraints.** Start from `./infra/bootstrap.sh destroy && up`. Config persisted (`write memory`).

**Hints.**
1. Verify addressing first; configure OSPF on both routers; repoint host defaults.
2. Bottom-up verify (neighbor → route → ping → traceroute).
3. Time yourself.

✅ **Verify.**
```bash
docker exec clab-r1 vtysh -c "show ip ospf neighbor" | grep -qi full && \
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "BUILD COMPLETE ✅"
```

**Pitfalls.**
- Forgetting host default routes.
- Not `write memory` (lost on restart).
- No systematic verify.

🎯 **Stretch.** Rebuild and beat your time.

---

## Task 2 — Ticket-driven: multi-fault troubleshoot (diagnose → fix)

**Scenario.** `NOC-342` (P1). Several faults injected across L1–L3. Restore full connectivity by
finding each — the CCNA troubleshooting section.

**Objective.** Systematically clear all injected faults; end-to-end restored. Timed.

**Given / constraints.** Peer injects 2–3 faults (link down, bad host route, OSPF network stmt removed).
Fix all.

**Hints.**
1. Ladder + `show ip ospf neighbor`/`show ip route` on routers, `ip route` on hosts.
2. Fix one, re-verify, continue.
3. Don't stop at the first fix — confirm end to end.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && \
docker exec clab-h1 traceroute -n 10.10.2.10 | grep -q 10.0.0 && echo "ALL FAULTS CLEARED ✅"
```

**Pitfalls.**
- Fixing one fault and declaring victory (multiple injected).
- Guess-fixing without the ladder.
- Not confirming the path with traceroute.

🎯 **Stretch.** Log each fault + fix as you go (troubleshooting journal).

---

## Task 3 — On-call: full mock scenario + write-up (synthesis)

**Scenario.** `NOC-343` (time-boxed). Deliver a scenario spec (addressing plan + services + a
failure/recovery) end to end, then document the design and verification — capstone deliverable.

**Objective.** Implement the spec, prove it with checks, and produce a design+verification write-up.

**Given / constraints.** Fresh lab. Follow a written spec. Document design decisions + verification.

**Hints.**
1. Plan → build → verify each requirement with a command.
2. Induce the specified failure; show recovery.
3. Write the design doc + verification evidence.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "SCENARIO MET ✅"
test -f docs/learning/reports/NOC-343-capstone.md && echo "WRITE-UP ✅"
```

**Deliverable.** `docs/learning/reports/NOC-343-capstone.md`: design · addressing · verification per requirement · failure/recovery.

**Pitfalls.**
- Building without verifying each requirement.
- No failure/recovery demonstration.
- Doc without verification evidence.

🎯 **Stretch.** Have someone else follow only your doc to rebuild it.

---

## Done?
- [ ] All ✅ Verify pass · [ ] timed builds · [ ] capstone write-up with evidence.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
