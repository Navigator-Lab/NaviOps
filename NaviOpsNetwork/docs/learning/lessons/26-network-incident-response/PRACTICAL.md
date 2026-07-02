# Lesson 26 — Pure Practical: Network Incident Response

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** the full topology + monitoring. **Rules:** you are the NOC on shift — detect,
> triage, mitigate, verify, document. Run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: rehearse the NOC incident loop (fluency)

**Scenario.** `NOC-261`. Practice the loop on a *known* failure (down a router interface): detect →
triage → mitigate → verify → document.

**Objective.** Work the 5-step loop on a planted failure and produce a clean incident note.

**Given / constraints.** `docker exec clab-r1 ip link set eth1 down`. Detect from monitoring, not from
knowing.

**Hints.**
1. Detect via `probe_success`/alert. Triage: scope + severity. Mitigate: bring the link up.
2. Verify: h1↔h2 restored. Document with times.
3. Record MTTD/MTTR.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "RECOVERED ✅"
test -f docs/learning/reports/NOC-261-incident.md && echo "NOTE ✅"
```

**Pitfalls.**
- Skipping detection ("I know what I broke").
- No timing captured.
- Fixing without a verify.

🎯 **Stretch.** Turn the loop into a one-page NOC runbook.

---

## Task 2 — Ticket-driven: unknown outage (diagnose end to end)

**Scenario.** `NOC-262` (P1). Users report loss between sites; cause unknown (use a random LAB.md
drill). Work it blind.

**Objective.** Find the true cause across layers, mitigate, verify, document — no prior knowledge.

**Given / constraints.** Unknown fault. Timebox 15 min. Correlate signals.

**Hints.**
1. Ladder + monitoring: neighbor state, routes, link, host route.
2. Hypothesize → test cheaply → confirm.
3. Timeline as you go.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "RESOLVED ✅"
grep -qi 'root cause' docs/learning/reports/NOC-262-outage.md && echo "ROOT CAUSE ✅"
```

**Deliverable.** `docs/learning/reports/NOC-262-outage.md`: Impact · Timeline · Root cause · Fix · Prevention.

**Pitfalls.**
- Guess-fixing before confirming.
- No live timeline.
- Tunnel vision on one layer.

🎯 **Stretch.** Add a detection improvement that would've caught it faster.

---

## Task 3 — On-call: concurrent incidents, prioritize (synthesis)

**Scenario.** `NOC-263` (P1, time-boxed). Two issues at once (a link down + a saturated host).
Prioritize by impact, resolve both, run a blameless review.

**Objective.** Triage by impact, resolve both without one worsening the other, write a game-day report
with MTTD/MTTR.

**Given / constraints.** Two planted faults. Explicit prioritization rationale.

**Hints.**
1. Which hurts more users now? Contain that first.
2. Ensure fix A doesn't aggravate B.
3. Blameless review + action items.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "LINK OK ✅"
grep -qiE 'action item|mttr' docs/learning/reports/NOC-263-gameday.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/NOC-263-gameday.md`: both timelines · prioritization · MTTD/MTTR · action items.

**Pitfalls.**
- Working the interesting one, not the impactful one.
- Fix A worsens B.
- Blameful review.

🎯 **Stretch.** Make it a recurring game day; track MTTR trend.

---

## Done?
- [ ] All ✅ Verify pass · [ ] detection→postmortem each time · [ ] blameless reviews.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
