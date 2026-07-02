# Lesson 25 — Pure Practical: Threat Hunting Fundamentals

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** full Wazuh stack + `siem-victim` data. **Rules:** hypothesis first, evidence
> always, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: form and test a hunt hypothesis (fluency)

**Scenario.** `SOC-251`. Hunting is proactive: assume a breach, form a hypothesis about attacker
behavior, and look for evidence — no alert required.

**Objective.** A documented hunt: hypothesis → observable → query → finding (present/absent).

**Given / constraints.** State the hypothesis before querying. Evidence-based conclusion.

**Hints.**
1. Hypothesis ("persistence via cron / odd outbound / new admin") → the observable it leaves.
2. Query logs + host for that observable.
3. Conclude with evidence.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-251-hunt.md && grep -qiE 'hypothesis|finding' docs/learning/reports/SOC-251-hunt.md && echo "HUNT ✅"
```

**Pitfalls.**
- No hypothesis (aimless log-staring).
- "Nothing found" without showing the query.
- Confirmation bias.

🎯 **Stretch.** Convert a positive hunt into a persistent detection.

---

## Task 2 — Ticket-driven: hunt from a lead (diagnose → report)

**Scenario.** `SOC-252` (P2). A weak signal (odd login time, rare process) is your lead. Hunt around it to
confirm or dismiss malicious activity.

**Objective.** Pivot from the lead across data sources to a documented verdict.

**Given / constraints.** Corroborate across ≥2 sources. Evidence for the verdict.

**Hints.**
1. Pivot on the entity (user/host/process) across logs.
2. Expand the time window around the lead.
3. Verdict + evidence + recommended detection.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-252-lead-hunt.md && grep -qiE 'verdict|evidence' docs/learning/reports/SOC-252-lead-hunt.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-252-lead-hunt.md`: lead · pivots · findings · verdict · detection idea.

**Pitfalls.**
- Chasing the lead in one source only.
- Dismissing without expanding the window.
- No detection follow-up.

🎯 **Stretch.** Build the detection so the lead auto-alerts next time.

---

## Task 3 — On-call: structured hunt across the estate (synthesis)

**Scenario.** `SOC-253` (P1, time-boxed). Run a structured hunt (multiple hypotheses from your threat
model), document coverage, and hand off any findings to IR.

**Objective.** A multi-hypothesis hunt report with coverage + any findings escalated.

**Given / constraints.** Derive hypotheses from L08's threat model. Document what you looked for.

**Hints.**
1. Several hypotheses; query each; record present/absent.
2. Findings → IR handoff.
3. Coverage note (what was and wasn't hunted).

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-253-structured-hunt.md && grep -qiE 'coverage|hypothes' docs/learning/reports/SOC-253-structured-hunt.md && echo "HUNT REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-253-structured-hunt.md`: hypotheses · queries · findings · coverage · escalations.

**Pitfalls.**
- One hypothesis (narrow coverage).
- No record of what was hunted (irreproducible).
- Findings not escalated to IR.

🎯 **Stretch.** Turn recurring hunts into scheduled detections (hunt→detect maturity).

---

## Done?
- [ ] All ✅ Verify pass · [ ] hypothesis-first · [ ] coverage documented · [ ] findings escalated.
- [ ] **Guardrails:** sanitized data only. → [README Reflection](./README.md).
