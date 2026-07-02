# Lesson 26 — Pure Practical: Detection Engineering Basics

> **Companion to [`README.md`](./README.md).** Pure practice: 3 scenario tasks, guided → ticket-driven
> → on-call. **Lab:** manager `docker exec -it wazuh.manager bash`; `wazuh-logtest`; content in
> `infra/wazuh/`. **Rules:** every detection tested both ways, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: the detection lifecycle (fluency)

**Scenario.** `SOC-261`. Take a detection from idea → rule → test → tune, treating detections like code
(the detection-engineering mindset).

**Objective.** A detection with TP + FP test cases, documented as a lifecycle artifact.

**Given / constraints.** Idea from a threat; test both cases; document.

**Hints.**
1. Idea → data source → logic → rule.
2. `wazuh-logtest` TP + FP.
3. Document like a spec (what it catches, known FPs, tuning).

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<TP>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "<rule>"' && echo "DETECTION WORKS ✅"
test -f docs/learning/reports/SOC-261-detection.md && echo "SPEC ✅"
```

**Pitfalls.**
- Treating detections as fire-and-forget (they need maintenance).
- No FP test.
- No documentation/spec.

🎯 **Stretch.** Version the detection (change log) like code.

---

## Task 2 — Ticket-driven: measure + improve a detection's quality (diagnose → tune)

**Scenario.** `SOC-262` (P2). A detection exists but its quality is unknown. Measure precision (TP vs FP)
and improve it.

**Objective.** A precision assessment + a tuning that improves it, both proven.

**Given / constraints.** Test with several TP + FP samples. Improve without losing TPs.

**Hints.**
1. Run a batch of samples through `wazuh-logtest`; count TP/FP.
2. Tune the logic to raise precision.
3. Re-measure.

✅ **Verify.**
```bash
test -f docs/learning/reports/SOC-262-precision.md && grep -qiE 'precision|tp|fp' docs/learning/reports/SOC-262-precision.md && echo "MEASURED ✅"
```

**Deliverable.** `docs/learning/reports/SOC-262-precision.md`: samples · TP/FP counts · tuning · new precision.

**Pitfalls.**
- No measurement (can't improve what you don't measure).
- Tuning that drops TPs.
- One-sample "testing".

🎯 **Stretch.** Track precision over time as a detection health metric.

---

## Task 3 — On-call: build detections for a coverage gap (synthesis)

**Scenario.** `SOC-263` (P1, time-boxed). A gap analysis shows uncovered techniques. Engineer detections
to close the top gaps and document coverage.

**Objective.** ≥2 new tested detections mapped to ATT&CK closing real gaps; coverage note.

**Given / constraints.** Map to techniques; test each; be honest about remaining gaps.

**Hints.**
1. Pick the highest-risk uncovered techniques.
2. Engineer + test detections.
3. Coverage note (before/after).

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -c "<rule id=" /var/ossec/etc/rules/local_rules.xml 2>/dev/null'   # grew
test -f docs/learning/reports/SOC-263-gap-closure.md && echo "COVERAGE ✅"
```

**Deliverable.** `docs/learning/reports/SOC-263-gap-closure.md`: gaps · new detections · MITRE · tests · remaining gaps.

**Pitfalls.**
- Building easy detections instead of high-risk ones.
- Untested rules.
- Claiming full coverage (be honest about gaps).

🎯 **Stretch.** Produce an ATT&CK Navigator before/after coverage layer.

---

## Done?
- [ ] All ✅ Verify pass · [ ] detections tested + measured · [ ] gaps closed with ATT&CK mapping.
- [ ] **Guardrails:** sanitized rules; no real data. → [README Reflection](./README.md).
