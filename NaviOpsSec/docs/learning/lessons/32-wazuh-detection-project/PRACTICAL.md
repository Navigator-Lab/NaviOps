# Lesson 32 — Pure Practical: Wazuh Detection Project

> **Companion to [`README.md`](./README.md).** Already hands-on; this adds 3 detection-engineering
> drills. **Lab:** manager `docker exec -it wazuh.manager bash`; `wazuh-logtest`; content in
> `infra/wazuh/`. **Rules:** every detection is tested both ways, run ✅ **Verify** each task.

Each task: **Scenario · Objective · Given/constraints · Hints · ✅ Verify · Pitfalls · 🎯 Stretch.**

---

## Task 1 — Guided: build a tested detection from a threat (fluency)

**Scenario.** `SOC-321`. Take one threat and deliver a production-quality detection: rule + decoder +
test cases (should/shouldn't match).

**Objective.** A detection with passing positive + negative test cases via `wazuh-logtest`.

**Given / constraints.** Include both a TP sample and an FP sample. Tune to pass both.

**Hints.**
1. Write the rule/decoder; pick 2 samples (malicious, benign).
2. `wazuh-logtest` both; malicious fires, benign doesn't.
3. Document the test cases.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<TP>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "<rule>"' && echo "TP FIRES ✅"
docker exec wazuh.manager sh -c 'echo "<FP>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "<rule>" && echo BAD || echo GOOD' | grep -q GOOD && echo "FP SUPPRESSED ✅"
```

**Pitfalls.**
- Testing only the positive case (FPs surface in prod).
- Rule too broad/narrow.
- No documented test cases.

🎯 **Stretch.** Add the detection + tests to `infra/wazuh/` (sanitized).

---

## Task 2 — Ticket-driven: a detection is too noisy in prod (diagnose → tune)

**Scenario.** `SOC-322` (P2). A shipped detection is generating too many FPs. Tune for fidelity without
losing the TP.

**Objective.** Reduced FPs, TP preserved, proven with test cases.

**Given / constraints.** Add scoped exceptions, not a disable. Prove both cases.

**Hints.**
1. Characterize the FP source; add a scoped exception/condition.
2. Re-test TP + FP.
3. Document the tuning.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'echo "<TP>" | /var/ossec/bin/wazuh-logtest 2>/dev/null | grep -q "<rule>"' && echo "TP STILL FIRES ✅"
```

**Deliverable.** `docs/learning/reports/SOC-322-tuning.md`: FP source · exception · TP/FP re-test · result.

**Pitfalls.**
- Disabling instead of scoping.
- Tuning away the TP.
- No re-test.

🎯 **Stretch.** Add a metric for the rule's precision over time.

---

## Task 3 — On-call: build a detection pack for an attack campaign (synthesis)

**Scenario.** `SOC-323` (P1, time-boxed). Deliver detections covering a multi-stage campaign
(recon→brute→persistence→exfil) with test coverage per stage.

**Objective.** A detection pack (≥3 rules) covering the campaign, each with test cases; a coverage note.

**Given / constraints.** Map each rule to an ATT&CK technique. Test each.

**Hints.**
1. One detection per stage; map to technique.
2. Test each with `wazuh-logtest`.
3. Coverage note: stage → rule → technique → tested.

✅ **Verify.**
```bash
docker exec wazuh.manager sh -c 'grep -c "<rule id=" /var/ossec/etc/rules/local_rules.xml 2>/dev/null'   # ≥3 custom rules
test -f docs/learning/reports/SOC-323-detection-pack.md && echo "PACK ✅"
```

**Deliverable.** `docs/learning/reports/SOC-323-detection-pack.md`: stage · rule · MITRE · test case · coverage.

**Pitfalls.**
- Detections with no ATT&CK mapping.
- Untested rules.
- Gaps between stages unflagged.

🎯 **Stretch.** Publish the pack as sanitized content in `infra/wazuh/`.

---

## Done?
- [ ] All ✅ Verify pass · [ ] every detection tested both ways · [ ] campaign pack mapped to ATT&CK.
- [ ] **Guardrails:** sanitized rules; no real data. → [README Reflection](./README.md).
