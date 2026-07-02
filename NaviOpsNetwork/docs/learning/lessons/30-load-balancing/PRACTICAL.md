# Lesson 30 — Pure Practical: Load Balancing

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** an nginx/haproxy container in front of two backend containers on the lab net.
> **Rules:** type it, diagnose before you fix, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: balance two backends with health checks (fluency)

**Scenario.** `NOC-301`. Put an LB in front of two web backends so load spreads and a dead backend is
removed automatically.

**Objective.** LB distributing across two backends; a dead backend is ejected by the health check.

**Given / constraints.** Two identifiable backends; health check configured.

**Hints.**
1. `upstream` (nginx) / `backend` (haproxy) with both servers + health check.
2. Curl the LB repeatedly → responses alternate.
3. Kill a backend → traffic still served.

✅ **Verify.**
```bash
for i in $(seq 6); do docker exec clab-h1 curl -s <lb>:8080/whoami; done | sort | uniq -c   # both seen
```

**Pitfalls.**
- No health check → traffic to a dead backend (errors).
- Sticky assumptions on a stateful app.
- Wrong algorithm for the workload.

🎯 **Stretch.** Add TLS termination at the LB.

---

## Task 2 — Ticket-driven: "half of requests fail" (diagnose → fix)

**Scenario.** `NOC-302` (P2). Intermittent errors through the LB — one backend is sick but still in
rotation. Find and eject it.

**Objective.** Get error rate to 0 by fixing the health check / ejecting the bad backend — diagnose
first.

**Given / constraints.** One backend returns 500s. Fix without taking the LB down.

**Hints.**
1. Hit each backend directly (bypass LB) to find the sick one.
2. LB stats/health — is the check catching it?
3. Tighten the check threshold; verify error rate → 0.

✅ **Verify.**
```bash
for i in $(seq 20); do docker exec clab-h1 curl -s -o /dev/null -w '%{http_code}\n' <lb>:8080/; done | sort | uniq -c   # all 200
```

**Pitfalls.**
- Too-lax health check keeps a flapping backend in.
- Taking the whole LB down for one backend.
- One curl "looks fine" (measure the rate).

🎯 **Stretch.** Add connection draining before removing a backend.

---

## Task 3 — On-call: LB is the single point of failure (synthesis)

**Scenario.** `NOC-303` (P1, time-boxed). The LB itself failed and took everything down. Restore
service and document a design fix (redundant LBs / VRRP) so it can't recur.

**Objective.** Restore traffic, and write a note proposing LB redundancy (active/passive + VIP).

**Given / constraints.** Simulate LB failure; restore. Design recommendation required.

**Hints.**
1. Restore the LB / fail over to a standby.
2. Verify traffic served.
3. Note: two LBs + a floating VIP (keepalived/VRRP) removes the SPOF.

✅ **Verify.**
```bash
docker exec clab-h1 curl -sf <lb>:8080/ >/dev/null && echo "SERVICE RESTORED ✅"
grep -qi 'vrrp\|keepalived\|redundan' docs/learning/reports/NOC-303-lb-spof.md && echo "DESIGN FIX ✅"
```

**Deliverable.** `docs/learning/reports/NOC-303-lb-spof.md`: Impact · cause · fix · redundancy design.

**Pitfalls.**
- A single LB (the SPOF the incident exposed).
- Restoring without addressing the design.
- No VIP failover plan.

🎯 **Stretch.** Sketch the keepalived/VRRP config for an active/passive pair.

---

## Done?
- [ ] All ✅ Verify pass · [ ] error rate → 0 · [ ] SPOF design fix proposed.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
