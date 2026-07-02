# Lesson 31 — Pure Practical: Security Monitoring Project

> **Companion to [`README.md`](./README.md).** The project is already hands-on; this adds 3 end-to-end
> monitoring-build drills. **Lab:** full Wazuh stack + victim. **Rules:** build, prove, document. Run ✅
> **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: stand up monitoring coverage for a host (fluency)

**Scenario.** `SOC-311`. Deliver baseline monitoring for the victim: log ingestion, FIM, and a few
detections mapped to your threat model.

**Objective.** Victim fully monitored: logs in, FIM on critical paths, ≥3 detections firing on test.

**Given / constraints.** Map coverage to L08's threat model. Prove each detection with `wazuh-logtest`.

**Hints.**
1. Ensure ingestion + FIM (L14/L24).
2. Add ≥3 detections for your top threats.
3. Prove each with a test event.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c '/var/ossec/bin/agent_control -l 2>/dev/null | grep -qi active' && echo "MONITORED ✅"
test -f docs/learning/reports/SOC-311-coverage.md && echo "COVERAGE DOC ✅"
```

**Pitfalls.**
- Coverage not tied to actual threats (random rules).
- Detections never tested.
- No FIM on critical paths.

🎯 **Stretch.** Produce a coverage matrix (threat → detection → tested?).

---

## Task 2 — Ticket-driven: close a monitoring gap (diagnose → fix)

**Scenario.** `SOC-312` (P2). An attack succeeded with no alert — a coverage gap. Find it, build the
detection, prove it.

**Objective.** A new detection that catches the previously-missed attack, validated.

**Given / constraints.** Run an attack that isn't detected; build + prove the detection.

**Hints.**
1. Confirm the gap (attack, no alert).
2. Identify the log signal; write the rule.
3. Prove with `wazuh-logtest` + a live re-run.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<attack line>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "Rule id"' && echo "GAP CLOSED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-312-gap.md`: gap · signal · detection · validation.

**Pitfalls.**
- Building a rule you never test.
- A rule so narrow it only catches the exact test.
- Not confirming the gap first.

🎯 **Stretch.** Add the detection to `infra/wazuh/` (sanitized) with test cases.

---

## Task 3 — On-call: prove the monitoring works under attack (synthesis)

**Scenario.** `SOC-313` (P1, time-boxed). Run a multi-stage attack and demonstrate the monitoring
detects each stage; report coverage + gaps.

**Objective.** A detection report: each attack stage → detected? → evidence; gaps flagged.

**Given / constraints.** Multi-stage attack. Map each stage to a detection; be honest about gaps.

**Hints.**
1. Run recon → brute → persistence.
2. For each, was there an alert? Evidence.
3. Report coverage + gaps + fixes.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-313-detection-report.md && grep -qiE 'stage|gap|detected' docs/learning/reports/SOC-313-detection-report.md && echo "REPORT ✅"
```

**Deliverable.** `docs/learning/reports/SOC-313-detection-report.md`: stages · detected? · evidence · gaps · fixes.

**Pitfalls.**
- Only testing what you know is covered.
- Hiding gaps (they're the value).
- No evidence per stage.

🎯 **Stretch.** Turn the report into an ATT&CK coverage layer.

---

## Done?
- [ ] All ✅ Verify pass · [ ] coverage tied to threats · [ ] gaps found + closed + validated.
- [ ] **Guardrails:** sanitized rules; no real data. → [README Reflection](./README.md).
