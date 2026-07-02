# Lesson 28 — Pure Practical: Incident Response Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** `siem-victim` + Wazuh. **Rules:** follow the IR lifecycle, preserve evidence, run
> ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: run the IR lifecycle on a known incident (fluency)

**Scenario.** `SOC-281`. Rehearse the phases (prepare → detect/analyze → contain → eradicate → recover →
lessons) on a *known* planted incident.

**Objective.** Work all phases on a known incident and produce a phase-labeled note.

**Given / constraints.** Plant a known incident. Follow phases in order; time each.

**Hints.**
1. Detect/analyze (confirm + scope) → contain (evidence first) → eradicate → recover → lessons.
2. Timeline live; capture MTTD/MTTR.
3. Label each phase.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-281-lifecycle.md && grep -qiE 'contain|eradicat|recover' docs/learning/reports/SOC-281-lifecycle.md && echo "LIFECYCLE ✅"
```

**Pitfalls.**
- Skipping analysis (respond blind).
- Containing without evidence.
- No lessons-learned phase.

🎯 **Stretch.** Turn the run into an IR playbook others can follow.

---

## Task 2 — Ticket-driven: an unknown incident, full lifecycle (diagnose end to end)

**Scenario.** `SOC-282` (P1). An unknown incident. Work it detection → root cause → contain → eradicate →
recover → report.

**Objective.** Root cause found, threat removed, service recovered, IR report produced.

**Given / constraints.** Unknown fault. Timebox. Evidence throughout.

**Hints.**
1. Confirm + scope before acting.
2. Contain (evidence first) → eradicate all footholds → recover → verify clean.
3. IR report with IoCs + MITRE.

✅ **Verify.**
```bash
docker exec siem-victim sh -c 'crontab -l 2>/dev/null | grep -q "<rogue>"' && echo "NOT CLEAN ❌" || echo "RESOLVED ✅"
test -f docs/learning/reports/SOC-282-ir.md && grep -qiE 'root cause|ioc' docs/learning/reports/SOC-282-ir.md && echo "IR REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-282-ir.md`: detection · root cause · containment · eradication · recovery · IoCs · MITRE.

**Pitfalls.**
- Acting before scoping.
- Missing footholds (recurrence).
- Declaring recovery before verifying clean.

🎯 **Stretch.** Determine initial access and add a detection for it.

---

## Task 3 — On-call: major incident with roles + comms (synthesis)

**Scenario.** `SOC-283` (P1, time-boxed). A major incident. Run it with IC/comms roles, coordinate the
lifecycle, and produce a blameless postmortem with metrics + action items.

**Objective.** Coordinated response + resolution + blameless postmortem (MTTD/MTTR, action items).

**Given / constraints.** Major planted incident. Comms cadence. Metrics.

**Hints.**
1. Declare, roles (IC/comms/ops — even solo), live timeline.
2. Full lifecycle; verify recovery.
3. Postmortem with metrics + owned actions.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-283-major-ir.md && grep -qiE 'mttr|action item' docs/learning/reports/SOC-283-major-ir.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/SOC-283-major-ir.md`: timeline · comms · lifecycle · MTTD/MTTR · action items.

**Pitfalls.**
- No comms cadence (stakeholders blind).
- Fixing before scoping.
- Blameful review.

🎯 **Stretch.** Add an external status-update template + a tabletop version of the scenario.

---

## Done?
- [ ] All ✅ Verify pass · [ ] full lifecycle each time · [ ] recovery verified clean · [ ] blameless postmortem.
- [ ] **Guardrails:** fake incidents; no real data. → [README Reflection](./README.md).
