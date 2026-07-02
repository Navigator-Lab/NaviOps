# Lesson 11 — Pure Practical: Cyber Kill Chain

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** Wazuh + victim. **Rules:** evidence before verdict, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: place lab activity on the kill chain (fluency)

**Scenario.** `SOC-111`. Map generated activity to kill-chain phases (recon → weaponization → delivery →
exploitation → installation → C2 → actions).

**Objective.** ≥3 lab events placed in the correct phase with reasoning.

**Given / constraints.** Generate recon + brute force + a persistence artifact. Map each.

**Hints.**
1. Scan = reconnaissance; brute force = delivery/exploitation; rogue cron/user = installation (persistence).
2. Earlier phases = better interception (defense).
3. Record event → phase → why.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-111-killchain.md && grep -qiE 'recon|exploit|c2|persist' docs/learning/reports/SOC-111-killchain.md && echo "MAPPED ✅"
```

**Pitfalls.**
- Only spotting late phases (you want to catch recon early).
- Forcing events into phases that don't fit.
- Confusing kill chain with ATT&CK (complementary, not identical).

🎯 **Stretch.** Note the earliest phase you had detection for (your "left of boom").

---

## Task 2 — Ticket-driven: where in the chain are we? (diagnose → decide response)

**Scenario.** `SOC-112` (P2). An alert fires — determine the attacker's kill-chain phase to choose the
right response (block early vs contain late).

**Objective.** Correct phase identification + a phase-appropriate response recommendation.

**Given / constraints.** Evidence-based. Response scales with phase.

**Hints.**
1. Which phase does the evidence indicate?
2. Early (recon/delivery) → block/deny; late (installation/C2/actions) → contain + hunt for scope.
3. Recommend accordingly.

✅ **Verify.**
```bash
grep -qiE 'phase|response' docs/learning/reports/SOC-112-phase.md && echo "PHASE + RESPONSE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-112-phase.md`: evidence · phase · response rationale.

**Pitfalls.**
- Under-reacting to a late-phase indicator (already inside).
- Over-reacting to noise recon.
- Response not matched to phase.

🎯 **Stretch.** Map the phase to the likely next phase and pre-position a detection.

---

## Task 3 — On-call: full-chain intrusion write-up (synthesis)

**Scenario.** `SOC-113` (P1, time-boxed). Reconstruct an intrusion across the whole chain, identify the
earliest missed interception point, and report.

**Objective.** A phase-by-phase reconstruction + the earliest point you could/should have stopped it.

**Given / constraints.** Multiple planted, related events. Identify the best missed intercept.

**Hints.**
1. Order events by phase.
2. Where was the earliest detectable opportunity you missed?
3. Recommend a control at that phase.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-113-full-chain.md && grep -qi 'earliest\|intercept' docs/learning/reports/SOC-113-full-chain.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-113-full-chain.md`: phase timeline · earliest intercept · control recommendation.

**Pitfalls.**
- Only documenting the phase you detected.
- No "earliest intercept" analysis (the learning).
- Recommending controls at the wrong phase.

🎯 **Stretch.** Build the control/detection for that earliest phase now.

---

## Done?
- [ ] All ✅ Verify pass · [ ] response matched to phase · [ ] earliest-intercept identified.
- [ ] **Guardrails:** no real IoCs committed. → [README Reflection](./README.md).
