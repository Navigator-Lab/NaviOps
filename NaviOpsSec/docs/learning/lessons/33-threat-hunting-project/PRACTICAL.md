# Lesson 33 — Pure Practical: Threat Hunting Project

> **Companion to [`README.md`](./README.md).** Already hands-on; this adds 3 hypothesis-driven hunt
> drills. **Lab:** full Wazuh stack + victim data. **Rules:** hypothesis first, evidence always, run ✅
> **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: run a hypothesis-driven hunt (fluency)

**Scenario.** `SOC-331`. Hunting isn't waiting for alerts. Form a hypothesis ("an attacker would
persist via cron"), then hunt for evidence.

**Objective.** A documented hunt: hypothesis → queries → findings (present/absent) → conclusion.

**Given / constraints.** State the hypothesis first. Evidence-based conclusion.

**Hints.**
1. Hypothesis → the observable it would leave.
2. Query logs/host for that observable.
3. Conclude present/absent with evidence.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-331-hunt.md && grep -qiE 'hypothesis|finding' docs/learning/reports/SOC-331-hunt.md && echo "HUNT ✅"
```

**Pitfalls.**
- Hunting with no hypothesis (aimless).
- "Nothing found" without showing the queries.
- Confirmation bias (only looking for what confirms).

🎯 **Stretch.** If found, convert the hunt into a persistent detection.

---

## Task 2 — Ticket-driven: hunt a specific TTP (diagnose → report)

**Scenario.** `SOC-332` (P2). Intel names a TTP. Hunt the lab for it and report presence/absence with a
coverage recommendation.

**Objective.** TTP translated to queries, hunted, reported — with a detection recommendation.

**Given / constraints.** Plant (or not) the TTP. Evidence for either verdict.

**Hints.**
1. TTP → concrete observables/queries.
2. Hunt; record hits.
3. Recommend a detection to catch it going forward.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-332-ttp-hunt.md && grep -qiE 'found|not found|detection' docs/learning/reports/SOC-332-ttp-hunt.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-332-ttp-hunt.md`: TTP · queries · findings · detection recommendation.

**Pitfalls.**
- Not translating the TTP into concrete queries.
- No detection follow-up.
- Absence claimed without evidence.

🎯 **Stretch.** Build the recommended detection now.

---

## Task 3 — On-call: proactive hunt uncovers an active intrusion (synthesis)

**Scenario.** `SOC-333` (P1, time-boxed). A hunt finds a real (planted) intrusion that no alert caught.
Scope it, pivot to full IR, and report — including why detection missed it.

**Objective.** Scope the intrusion found by hunting, hand off to IR, and document the detection gap.

**Given / constraints.** Plant an undetected intrusion. Hunt finds it; scope + IR handoff.

**Hints.**
1. From the hunt hit, pivot to scope (what else did they touch?).
2. Transition to IR (contain/eradicate references L28/29).
3. Note why detection missed → new detection.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-333-hunt-to-ir.md && grep -qiE 'scope|detection gap' docs/learning/reports/SOC-333-hunt-to-ir.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-333-hunt-to-ir.md`: hunt hit · scope · IR handoff · detection gap · new detection.

**Pitfalls.**
- Finding the hit but not scoping.
- No detection improvement (the whole point of hunting).
- Not transitioning to formal IR.

🎯 **Stretch.** Close the loop: build the detection so the next instance alerts automatically.

---

## Done?
- [ ] All ✅ Verify pass · [ ] hypothesis-first · [ ] hunt→detection loop closed.
- [ ] **Guardrails:** sanitized data only. → [README Reflection](./README.md).
