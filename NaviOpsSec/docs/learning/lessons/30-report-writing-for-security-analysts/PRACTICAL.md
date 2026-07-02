# Lesson 30 — Pure Practical: Report Writing for Security Analysts

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** use the reports you produced in Lessons 17–29 as raw material. **Rules:** write
> for the audience, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: a clean alert-triage note (fluency)

**Scenario.** `SOC-301`. Write the everyday artifact: a concise triage note another analyst can act on
without asking you anything.

**Objective.** A triage note with: what · evidence · verdict · action · confidence.

**Given / constraints.** Base it on a real alert you triaged. Concise + complete.

**Hints.**
1. Lead with the verdict + confidence, then evidence.
2. Facts vs assessment clearly separated.
3. Actionable next step.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-301-triage-note.md && grep -qiE 'verdict|evidence|action' docs/learning/reports/SOC-301-triage-note.md && echo "NOTE ✅"
```

**Pitfalls.**
- Burying the verdict at the end.
- Mixing fact and speculation.
- No clear next action.

🎯 **Stretch.** Make a reusable template for the team.

---

## Task 2 — Ticket-driven: an incident report for two audiences (diagnose → write)

**Scenario.** `SOC-302` (P2). Write an incident report with a technical section (for engineers) AND an
executive summary (for leadership) — same facts, two registers.

**Objective.** A report with a jargon-free exec summary + a technical detail section, both from the same
incident.

**Given / constraints.** Base on a real IR from L28/29. No jargon in the exec summary.

**Hints.**
1. Exec summary: impact, business risk, status, ask — no jargon.
2. Technical: timeline, root cause, IoCs, MITRE, remediation.
3. Consistent facts across both.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-302-incident-report.md && grep -qiE 'executive|summary' docs/learning/reports/SOC-302-incident-report.md && echo "TWO-AUDIENCE REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-302-incident-report.md`: exec summary · timeline · root cause · IoCs · remediation.

**Pitfalls.**
- Jargon in the exec summary (loses leadership).
- Technical section with no timeline/root cause.
- Facts differing between the two sections.

🎯 **Stretch.** Add a metrics line (MTTD/MTTR) leadership tracks.

---

## Task 3 — On-call: blameless postmortem with action items (synthesis)

**Scenario.** `SOC-303` (time-boxed). Write the postmortem that actually improves the SOC: blameless,
with measurable action items and owners.

**Objective.** A blameless postmortem: timeline, root cause, what went well/poorly, action items
(owner + verification).

**Given / constraints.** Blameless (system/process, not people). Action items measurable.

**Hints.**
1. Timeline + root cause (5-whys, not "who").
2. What went well / what was slow.
3. Action items: specific, owned, verifiable.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-303-postmortem.md && grep -qiE 'action item|owner' docs/learning/reports/SOC-303-postmortem.md && echo "POSTMORTEM ✅"
```

**Deliverable.** `docs/learning/reports/SOC-303-postmortem.md`: timeline · root cause · well/poorly · action items (owner+verify).

**Pitfalls.**
- Blaming a person → people hide problems next time.
- Action items with no owner/verification → nothing changes.
- No "what went well" (morale + reinforcement).

🎯 **Stretch.** Track the action items to closure in a follow-up.

---

## Done?
- [ ] All ✅ Verify pass · [ ] verdict-first triage note · [ ] two-audience report · [ ] blameless postmortem.
- [ ] **Guardrails:** redact real data; sanitized examples only. → [README Reflection](./README.md).
