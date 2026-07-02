# Lesson 27 — Pure Practical: Network Documentation

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** the running topology is your subject to document. **Rules:** produce real
> artifacts, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: an as-built of the lab (fluency)

**Scenario.** `NOC-271`. Produce the documentation a new NOC tech needs: topology, IP plan, and access.

**Objective.** An as-built doc: diagram (ASCII ok), IP/subnet table, device roles, access methods.

**Given / constraints.** Derive from the *live* lab, not assumptions.

**Hints.**
1. Pull facts: `ip`/`vtysh show` from each device.
2. Diagram: h1─net_a─r1─core─r2─net_b─h2 with IPs.
3. Table: device · role · interfaces · IPs · access.

✅ **Verify.**
```bash
test -f docs/learning/reports/NOC-271-as-built.md && grep -qi '10.10.1' docs/learning/reports/NOC-271-as-built.md && echo "AS-BUILT ✅"
```

**Pitfalls.**
- Documenting intent instead of reality (drift).
- No access/credentials-location note (redact secrets themselves).
- Diagram without IPs/subnets.

🎯 **Stretch.** Add a "what changed" changelog convention to keep it living.

---

## Task 2 — Ticket-driven: "docs are wrong / out of date" (diagnose → fix)

**Scenario.** `NOC-272` (P2). *"The runbook says the path is X but traffic goes Y."* Reconcile docs with
reality after an undocumented change.

**Objective.** Find the drift between documented and actual state, correct the docs, and note the
change.

**Given / constraints.** Change one thing in the lab (a route/IP), then reconcile the as-built.

**Hints.**
1. Diff live state vs the doc.
2. Confirm the real change (who/when if logs show it).
3. Update the doc + add a changelog entry.

✅ **Verify.**
```bash
grep -qi 'updated\|changelog' docs/learning/reports/NOC-271-as-built.md && echo "DOC RECONCILED ✅"
```

**Pitfalls.**
- Fixing the doc without confirming the live change was intentional.
- No changelog → next drift is invisible.
- Trusting the doc over reality.

🎯 **Stretch.** Automate a nightly "live vs documented" diff that flags drift.

---

## Task 3 — On-call: documentation gap slows an incident (synthesis)

**Scenario.** `NOC-273` (time-boxed). During an incident, missing docs cost time. Capture what was
missing, produce the runbook that would've helped, and note the gap.

**Objective.** A targeted runbook for the incident type + a note on the documentation gap.

**Given / constraints.** Base it on a real drill you did. Runbook must be actionable (commands + verify).

**Hints.**
1. What info did you wish you had at 2am? That's the runbook.
2. Steps with exact commands + a verify per step.
3. Link it from the as-built.

✅ **Verify.**
```bash
test -f docs/learning/reports/NOC-273-runbook.md && grep -qi 'verify' docs/learning/reports/NOC-273-runbook.md && echo "RUNBOOK ✅"
```

**Deliverable.** `docs/learning/reports/NOC-273-runbook.md`: incident type · steps (cmd+verify) · escalation · the gap it fills.

**Pitfalls.**
- A runbook that's prose, not actionable steps.
- No verify per step.
- Never linking it where on-call will find it.

🎯 **Stretch.** Convert the runbook into a checklist the whole team reviews.

---

## Done?
- [ ] All ✅ Verify pass · [ ] docs match reality · [ ] runbook actionable with verifies.
- [ ] **Guardrails:** redact secrets; document their location, not their value. → [README Reflection](./README.md).
