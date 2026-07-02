# Lesson 35 — Pure Practical: NOC Capstone

> **Companion to [`README.md`](./README.md).** Already hands-on; this adds 3 shift-simulation drills
> (the daily NOC job). **Lab:** full topology + monitoring (`./infra/bootstrap.sh all`; Grafana :3001).
> **Rules:** you're on shift — detect, triage, act, document. Run ✅ **Verify** each.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: run a monitored shift (fluency)

**Scenario.** `NOC-351`. Start of shift: confirm the board is green, acknowledge a planted alert, and
log the handover.

**Objective.** Baseline the monitoring, ack an alert, and write a shift-handover note.

**Given / constraints.** Use the monitoring stack. Handover note captures state.

**Hints.**
1. `:9091/targets`/Grafana → all green baseline.
2. Trigger a probe alert; acknowledge + note it.
3. Handover: what's healthy, what's watched, what's open.

✅ **Verify.**
```bash
curl -s localhost:9091/api/v1/query?query=probe_success | grep -q '"value"' && echo "BOARD READING ✅"
test -f docs/learning/reports/NOC-351-handover.md && echo "HANDOVER ✅"
```

**Pitfalls.**
- No baseline → can't tell normal from abnormal.
- Acking without noting.
- No handover → next shift is blind.

🎯 **Stretch.** Define what "green" means per signal (thresholds).

---

## Task 2 — Ticket-driven: work the queue by priority (diagnose → act)

**Scenario.** `NOC-352` (P2). A queue of mixed alerts. Triage by impact, work the top item to
resolution, document.

**Objective.** Prioritized queue + the top incident resolved + a ticket note.

**Given / constraints.** Several planted alerts of differing impact. Justify ordering.

**Hints.**
1. Score by impact × confidence; order the queue.
2. Resolve the top (detect→fix→verify).
3. Note rationale + resolution.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "TOP INCIDENT RESOLVED ✅"
test -f docs/learning/reports/NOC-352-queue.md && echo "TICKET ✅"
```

**Deliverable.** `docs/learning/reports/NOC-352-queue.md`: prioritized queue · rationale · top resolution.

**Pitfalls.**
- Working newest/loudest instead of most impactful.
- No documented rationale.
- Leaving the top unverified.

🎯 **Stretch.** Add an SLA clock per priority tier.

---

## Task 3 — On-call: major incident, you're IC (synthesis)

**Scenario.** `NOC-353` (P1, time-boxed). A major outage. Run it as Incident Commander: detect, comms,
mitigate, verify, postmortem with MTTD/MTTR.

**Objective.** Full IC loop on a major failure + a blameless postmortem with metrics + action items.

**Given / constraints.** Planted major failure. Timebox. Capture comms cadence.

**Hints.**
1. Declare, assign roles (even solo: comms vs ops), timeline live.
2. Mitigate; verify recovery across the board.
3. Postmortem: MTTD/MTTR, root cause, action items with owners.

✅ **Verify.**
```bash
docker exec clab-h1 ping -c3 10.10.2.10 | grep -q '0% packet loss' && echo "RECOVERED ✅"
grep -qiE 'mttr|action item' docs/learning/reports/NOC-353-major.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/NOC-353-major.md`: timeline · comms · MTTD/MTTR · root cause · action items.

**Pitfalls.**
- No comms cadence (stakeholders in the dark).
- Fixing before scoping impact.
- Blameful postmortem.

🎯 **Stretch.** Add a status-page-style external update template.

---

## Done?
- [ ] All ✅ Verify pass · [ ] worked shift→queue→major · [ ] postmortem with metrics.
- [ ] **Guardrails:** lab only. → [README Reflection](./README.md).
